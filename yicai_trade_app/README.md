# YiCai Trade

YiCai Trade is a Flutter client for the global sourcing and electronic reverse-auction platform.

## Production configuration

- Bundle identifier: `com.chainnexlink.yicaitrade`
- App Store Connect app ID: `6791591302`
- Production API: `https://api.chainnexlink.com`
- iOS deployment target: 13.0+

## Verification

```bash
flutter pub get
flutter analyze lib
flutter test
```

The `ios-testflight` workflow in `codemagic.yaml` builds and publishes signed iOS archives after the App Store Connect integration is configured in Codemagic.
