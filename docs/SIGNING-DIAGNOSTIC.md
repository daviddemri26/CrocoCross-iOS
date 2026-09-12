# Local signing investigation — September 12, 2026

The local signing failure was resolved after the owner locked and explicitly unlocked the login keychain, entering the password locally. The final development-signed Release build passed at 16:00:27 PDT using the existing certificate and provisioning profile. Independent signature verification, physical installation and process launch then succeeded. The process was still running 45 seconds later; human gameplay and audio checks remain outstanding.

## Resolution evidence

- `/tmp/crococross-device-after-unlock.log` records the successful `CodeSign` step and `BUILD SUCCEEDED` for the final arm64 iPhone Release app.
- Independent `codesign --verify --deep --strict` verification outside the command sandbox passed: valid on disk and satisfying its designated requirement. The earlier sandboxed trust error did not reproduce in that verification.
- At 16:01:02, `devicectl` installed `com.daviddemri.crococross` on the connected physical iPhone. `/tmp/crococross-install-after-unlock.json` records `outcome: success`; the matching text log is `/tmp/crococross-install-after-unlock.log`.
- At 16:01:35, `devicectl` successfully launched the installed app as PID `63065`. A process listing at 16:02:20 confirmed it was still running, 45 seconds after launch. This does not establish human gameplay, audio or sustained performance.
- Durable copies of the build, installation, launch and running-process evidence are in `artifacts/qa/2026-09-12/logs`, including `crococross-launch-physical.*` and `crococross-running-physical.*`.
- No certificate was created or revoked, no key was exported, and no trust setting or key ACL was changed to achieve this result.

## Earlier failure evidence

- Certificate: Apple Development: david.demri@gmail.com (9ST6WRK434).
- Public certificate SHA-1: `74964DE15F9C84FC37FDBC96BC9DC9922AE94134`.
- Keychain Access shows that certificate as valid through October 21, 2026, with a private key in the login keychain.
- Before the reload, the login keychain was reported unlocked. A successful identity lookup and private-key reference lookup did not prove the key could be used.
- During the GUI build at 15:47:45, securityd attempts to decode the already-unlocked keychain and logs `CSSMERR_CSP_INVALID_DATA`. The client then reports an integrity-check failure, `CSSMERR_CSP_OPERATION_AUTH_DENIED`, `errSecAuthFailed (-25293)` and finally `errSecInternalComponent (-2070)`.
- A targeted, read-only `SecKeychainItemCopyAccess` call also returns -25293. No private-key bytes were exported or requested.
- No SecurityAgent/authd dialogue was recorded around that failed operation. Reconnecting the Apple account and repeating Build, including from Xcode's graphical session, had not resolved it.

## Interpretation and remaining validation

Apple's open-source implementation converts a failed database decode into an authorization error. Recovery after the explicit lock/unlock is consistent with stale cached keychain state; it does not establish permanent corruption or a specific incorrect app permission. The secondary -25337 error only means that an error description could not be loaded.

Reloading the keychain resolved this observed signing failure on this Mac. The password was entered by the owner locally, not supplied in a command argument, file or chat. The remaining device checks are human interaction and actual gameplay, audio, interruption and performance validation; a successful process launch does not establish those results.

No keychain reset, certificate replacement, trust override or broad partition-list change was needed. Apple notes that the lock keyboard shortcut no longer applies to the login/iCloud keychains on current macOS; the successful reload here used the command-line lock/unlock flow.

Sources: [database unlock/decode implementation](https://github.com/apple-oss-distributions/Security/blob/main/securityd/src/kcdatabase.cpp), [database cryptography](https://github.com/apple-oss-distributions/Security/blob/main/securityd/src/dbcrypto.cpp), [client integrity handling](https://github.com/apple-oss-distributions/Security/blob/main/OSX/libsecurity_keychain/lib/KeyItem.cpp), [Keychain Access shortcuts](https://support.apple.com/en-ca/guide/keychain-access/kyca699a9058/mac).
