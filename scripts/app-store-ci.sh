#!/bin/bash
# GitHub-hosted runner only. Never reads or exports signing material from the owner's Mac.
set -euo pipefail

fail() { printf 'ERROR: %s\n' "$1" >&2; exit 1; }
[[ "${GITHUB_ACTIONS:-}" == true && "${RUNNER_OS:-}" == macOS ]] || fail 'Run this script only in the manual macOS GitHub Actions job.'
[[ -n "${RUNNER_TEMP:-}" ]] || fail 'RUNNER_TEMP is required.'
signing_dir="$RUNNER_TEMP/crococross-app-store-signing"
keychain="$signing_dir/signing.keychain-db"
profile_dir="$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"
cleanup() {
  if [[ -f "$signing_dir/profile-uuid" ]]; then
    local profile_uuid
    profile_uuid=$(cat "$signing_dir/profile-uuid")
    if [[ "$profile_uuid" =~ ^[A-Fa-f0-9-]{36}$ ]]; then
      rm -f "$profile_dir/$profile_uuid.mobileprovision"
    fi
  fi
  security delete-keychain "$keychain" >/dev/null 2>&1 || true
  rm -rf "$signing_dir"
}
if [[ "${1:-}" == cleanup ]]; then cleanup; exit 0; fi
[[ $# == 0 ]] || fail 'Only the optional cleanup argument is supported.'
[[ "${GITHUB_EVENT_NAME:-}" == workflow_dispatch && "${GITHUB_REF:-}" == refs/heads/main ]] || fail 'Distribution requires workflow_dispatch on main.'
[[ "${APP_STORE_RELEASE_ENABLED:-}" == true ]] || fail 'Release hold: enable APP_STORE_RELEASE_ENABLED in the protected app-store environment only after owner authorization.'
[[ "${APP_STORE_BUILD_NUMBER:-}" =~ ^[1-9][0-9]{0,3}(\.[0-9]{1,2}){0,2}$ ]] || fail 'Provide an unused numeric build number, such as 18; Apple permits up to three components (4/2/2 digits).'
[[ "${APP_STORE_UPLOAD:-false}" == false || "${APP_STORE_UPLOAD:-}" == true ]] || fail 'APP_STORE_UPLOAD must be true or false.'
for name in APPLE_DISTRIBUTION_P12_BASE64 APPLE_DISTRIBUTION_P12_PASSWORD APP_STORE_PROFILE_BASE64; do
  [[ -n "${!name:-}" ]] || fail "Missing environment secret: $name"
done
if [[ "${APP_STORE_UPLOAD:-false}" == true ]]; then
  for name in ASC_PRIVATE_KEY_BASE64 ASC_KEY_ID ASC_ISSUER_ID; do
    [[ -n "${!name:-}" ]] || fail "Upload requires environment secret: $name"
  done
fi
cd "$(dirname "$0")/.."
umask 077
mkdir -p "$signing_dir" "$profile_dir" "$RUNNER_TEMP/crococross-release"
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
release_dir="$RUNNER_TEMP/crococross-release"
printf '%s' "$APPLE_DISTRIBUTION_P12_BASE64" | base64 --decode > "$signing_dir/certificate.p12"
printf '%s' "$APP_STORE_PROFILE_BASE64" | base64 --decode > "$signing_dir/profile.mobileprovision"
security cms -D -i "$signing_dir/profile.mobileprovision" > "$signing_dir/profile.plist"
keychain_password=$(openssl rand -base64 32)
security create-keychain -p "$keychain_password" "$keychain"
security set-keychain-settings -lut 3600 "$keychain"
security unlock-keychain -p "$keychain_password" "$keychain"
security import "$signing_dir/certificate.p12" -P "$APPLE_DISTRIBUTION_P12_PASSWORD" -t cert -f pkcs12 -k "$keychain" -T /usr/bin/codesign -T /usr/bin/security >/dev/null
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$keychain_password" "$keychain" >/dev/null
security list-keychains -d user -s "$keychain"
security find-identity -v -p codesigning "$keychain" > "$signing_dir/identities.txt"
python3 - "$signing_dir" <<'PYPROFILE'
import datetime, hashlib, pathlib, plistlib, re, sys
p = pathlib.Path(sys.argv[1])
profile = plistlib.loads((p / 'profile.plist').read_bytes())
entitlements = profile.get('Entitlements', {})
assert profile.get('TeamIdentifier') == ['57XAAX65VC'], 'Unexpected signing team'
assert entitlements.get('application-identifier') == '57XAAX65VC.com.daviddemri.crococross', 'Wrong profile bundle ID'
assert entitlements.get('com.apple.developer.game-center') is True, 'Profile must include Game Center'
assert entitlements.get('get-task-allow') is False, 'Development profiles cannot ship to App Store Connect'
assert not profile.get('ProvisionedDevices') and not profile.get('ProvisionsAllDevices'), 'Use an App Store distribution profile'
assert profile['ExpirationDate'].replace(tzinfo=datetime.timezone.utc) > datetime.datetime.now(datetime.timezone.utc), 'Expired profile'
uuid = profile['UUID']
assert re.fullmatch(r'[A-Fa-f0-9-]{36}', uuid), 'Invalid profile UUID'
certificates = {hashlib.sha1(c).hexdigest().upper() for c in profile['DeveloperCertificates']}
identities = re.findall(r'([A-F0-9]{40}) "Apple Distribution:[^"]+"', (p / 'identities.txt').read_text())
matching = [identity for identity in identities if identity in certificates]
assert len(matching) == 1, 'Import exactly one matching Apple Distribution certificate and private key'
(p / 'profile-uuid').write_text(uuid)
(p / 'identity').write_text(matching[0])
options = dict(method='app-store-connect', destination='export', teamID='57XAAX65VC',
               signingStyle='manual', signingCertificate=matching[0],
               provisioningProfiles={'com.daviddemri.crococross': uuid},
               stripSwiftSymbols=True, uploadSymbols=True, manageAppVersionAndBuildNumber=False,
               testFlightInternalTestingOnly=False)
(p / 'ExportOptions.plist').write_bytes(plistlib.dumps(options))
options['destination'] = 'upload'
(p / 'UploadOptions.plist').write_bytes(plistlib.dumps(options))
PYPROFILE
profile_uuid=$(cat "$signing_dir/profile-uuid")
signing_identity=$(cat "$signing_dir/identity")
cp "$signing_dir/profile.mobileprovision" "$profile_dir/$profile_uuid.mobileprovision"
xcodebuild -project CrocoCross.xcodeproj -scheme CrocoCross -configuration Release \
  -destination 'generic/platform=iOS' -archivePath "$release_dir/CrocoCross.xcarchive" \
  -derivedDataPath "$RUNNER_TEMP/crococross-release-derived" \
  CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM=57XAAX65VC \
  CODE_SIGN_IDENTITY="$signing_identity" PROVISIONING_PROFILE_SPECIFIER="$profile_uuid" \
  CURRENT_PROJECT_VERSION="$APP_STORE_BUILD_NUMBER" archive 2>&1 | tee "$release_dir/archive.log"
xcodebuild -exportArchive -archivePath "$release_dir/CrocoCross.xcarchive" \
  -exportPath "$release_dir/export" -exportOptionsPlist "$signing_dir/ExportOptions.plist" \
  2>&1 | tee "$release_dir/export.log"
python3 - "$release_dir" "$APP_STORE_BUILD_NUMBER" <<'PYEVIDENCE'
import hashlib, json, os, pathlib, plistlib, sys
p = pathlib.Path(sys.argv[1]); expected = sys.argv[2]
app = p / 'CrocoCross.xcarchive/Products/Applications/CrocoCross.app'
info = plistlib.loads((app / 'Info.plist').read_bytes())
assert info['CFBundleVersion'] == expected, 'Archive build number mismatch'
assert info['CFBundleIdentifier'] == 'com.daviddemri.crococross', 'Archive bundle mismatch'
ipas = list((p / 'export').glob('*.ipa'))
assert len(ipas) == 1, 'Expected one exported IPA'
report = dict(commit=os.environ['GITHUB_SHA'], runID=os.environ['GITHUB_RUN_ID'],
              version=info['CFBundleShortVersionString'], build=expected,
              ipaSHA256=hashlib.sha256(ipas[0].read_bytes()).hexdigest(), uploaded=False)
(p / 'package.json').write_text(json.dumps(report, indent=2) + '\n')
print(f"Exported CrocoCross {report['version']} ({expected}); App Review and release remain separate.")
PYEVIDENCE
if [[ "${APP_STORE_UPLOAD:-false}" == true ]]; then
  python3 scripts/check-app-store-package.py --submission
  printf '%s' "$ASC_PRIVATE_KEY_BASE64" | base64 --decode > "$signing_dir/AuthKey.p8"
  xcodebuild -exportArchive -archivePath "$release_dir/CrocoCross.xcarchive" \
    -exportPath "$release_dir/upload" -exportOptionsPlist "$signing_dir/UploadOptions.plist" \
    -authenticationKeyPath "$signing_dir/AuthKey.p8" \
    -authenticationKeyID "$ASC_KEY_ID" -authenticationKeyIssuerID "$ASC_ISSUER_ID" \
    2>&1 | tee "$release_dir/upload.log"
  python3 - "$release_dir/package.json" <<'PYUPLOAD'
import json, pathlib, sys
p = pathlib.Path(sys.argv[1]); report = json.loads(p.read_text()); report['uploaded'] = True
p.write_text(json.dumps(report, indent=2) + '\n')
PYUPLOAD
  printf 'Upload command succeeded. Apple processing, tester distribution, review and release are separate.\n'
fi
