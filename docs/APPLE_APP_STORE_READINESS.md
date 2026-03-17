# Apple App Store Readiness (Foundry Slag)

This scaffold is now **closer** to App Store readiness, but not yet shippable without signing/notarization and final legal/release operations.

## Included in this pass
- Tauri bundle targets for `.app` and `.dmg`.
- macOS category and minimum OS in Tauri config.
- App Sandbox entitlements file scaffold.
- Base `Info.plist` metadata for category/name/identifier.

## Still required before submission
1. Apple Developer account + provisioning profile setup.
2. Hardened runtime signing + notarization pipeline in CI.
3. Real app icons (`.icns`) and complete metadata/screenshots.
4. Privacy policy and App Privacy disclosures in App Store Connect.
5. End-to-end QA on Apple Silicon with release build.
6. Final review for any network/security behavior and third-party notices.

## Suggested release commands
- `cargo tauri build`
- codesign + notarization using Apple credentials and keychain profile.
