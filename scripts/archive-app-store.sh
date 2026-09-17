#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
release_output="${1:-$PWD/artifacts/app-store-release}"
mkdir -p "$release_output"
python3 scripts/generate-project.py
xcodebuild -project CrocoCross.xcodeproj -scheme CrocoCross -configuration Release \
  -destination 'generic/platform=iOS' -archivePath "$release_output/CrocoCross.xcarchive" \
  -allowProvisioningUpdates archive
printf '\nArchive ready: %s\n' "$release_output/CrocoCross.xcarchive"
printf 'Export locally after Apple Distribution signing is configured:\n'
printf 'xcodebuild -exportArchive -archivePath "%s/CrocoCross.xcarchive" -exportPath "%s/export" -exportOptionsPlist distribution/config/ExportOptions-AppStore.plist -allowProvisioningUpdates\n' "$release_output" "$release_output"
