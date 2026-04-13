# iOS Completion Checklist (Windows-First Workflow)

This project now contains iOS native sign detection support and can be built from cloud macOS runners.

## What is already implemented in code

- iOS native camera preview streamed into Flutter texture.
- iOS hand landmark detection using Vision (21 joints).
- iOS TensorFlow Lite sign classification using `isl_model_advanced.tflite`.
- MethodChannel and EventChannel contract parity with Android:
  - `startDetection`
  - `stopDetection`
  - `switchCamera`
  - `checkCameraPermission`
  - `requestCameraPermission`
  - `isFrontCamera`
  - `resetPrediction`
- iOS deployment target set to 14.0.
- GitHub Actions workflow for cloud iOS simulator build:
  - `.github/workflows/ios-simulator-build.yml`

## Remaining steps that require your credentials/accounts

1. Configure iOS Firebase app in Firebase Console:
   - Add iOS app with bundle id `com.kairo.ai` (or your final bundle id).
   - Download `GoogleService-Info.plist`.
2. Place `GoogleService-Info.plist` in `ios/Runner/` and add it to the Runner target in Xcode.
3. Regenerate `lib/firebase_options.dart` with real iOS values:
   - Replace placeholder `YOUR_IOS_APP_ID` and `YOUR_MACOS_APP_ID`.
4. Configure Apple signing:
   - Apple Developer account
   - Team, certificates, provisioning profiles
5. Configure Google Sign-In iOS URL scheme:
   - Add the reversed client ID from `GoogleService-Info.plist` to `Info.plist` URL types.

## Build from this Windows machine using cloud macOS

1. Push your branch to GitHub.
2. Open Actions tab and run `iOS Simulator Build`.
3. Confirm workflow passes (native iOS compile validation).
4. For TestFlight/App Store, add a signed iOS release workflow with secrets.

## Optional next upgrade

- Add a second workflow for signed TestFlight upload using App Store Connect API key and signing secrets.
