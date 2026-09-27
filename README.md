# Lift Relay

[![iOS](https://github.com/lanray07/Lift-Relay/actions/workflows/ios.yml/badge.svg)](https://github.com/lanray07/Lift-Relay/actions/workflows/ios.yml)

Lift Relay is an offline-first SwiftUI workout companion that adapts structured training when gym equipment is unavailable. The MVP preserves the planned exercise alongside the performed substitute, so history remains meaningful.

## Included

- Four-step personalised onboarding
- Premium dashboard and active workout logger
- Deterministic, configurable substitution scoring with hard safety constraints
- Equipment Rescue, Relay Mode, and Time Rescue
- Rest timer, kg/lb conversion, workout history, and gym profiles
- Speech-framework capture with visible confirmation before state changes
- StoreKit 2 product loading, purchase verification, restore, and dynamic prices
- Privacy-conscious local analytics buffer and privacy manifest
- Fully local recommendation engine with no account or remote processing
- English user interface with localized App Store product pages

## Open on macOS

The project is generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```sh
brew install xcodegen
xcodegen generate
open LiftRelay.xcodeproj
```

Select a development team, create the two subscription products listed in `SubscriptionStore.productIDs`, then build with Xcode 16 or later for iOS 17+. Recommendations run locally using deterministic safety constraints.

## Tests

The platform-neutral engine is a Swift package, so it can be tested without Xcode:

```sh
swift test
```

On Windows, use a short scratch path if SwiftPM encounters path/symlink issues:

```powershell
swift test --scratch-path C:\Temp\liftrelay-swift-build
```

## Release gates

Before App Store submission: complete human translation review for the priority locales, supply production Terms/Privacy URLs, configure StoreKit products, add an app icon and screenshots, select signing, run UI/accessibility tests on iPhone and iPad, and verify the privacy nutrition label against the final backend.
