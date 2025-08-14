# Campus Commotion Android

This is the Android port of the Campus Commotion iOS app, converted from Swift/SwiftUI to Kotlin/Jetpack Compose.

## Features

- **Schedule View**: Displays daily class schedule from iCal feeds
- **Menu View**: Shows dining hall menus with dark mode support
- **Settings**: Configure calendar URLs, club URLs, and authentication tokens
- **Secure Storage**: Uses Android EncryptedSharedPreferences for secure credential storage

## Architecture

- **MVVM Pattern**: ViewModels with StateFlow for reactive UI
- **Jetpack Compose**: Modern declarative UI framework
- **Hilt**: Dependency injection
- **Retrofit**: Network requests
- **Kotlinx Serialization**: JSON parsing
- **EncryptedSharedPreferences**: Secure storage (replaces iOS Keychain)

## Key Components

### Data Layer
- `SecureStorage`: Secure credential storage
- `ScheduleRepository`: Data fetching and caching
- `ApiService`: Network API definitions

### UI Layer
- `MainActivity`: Entry point with Compose setup
- `MainScreen`: Bottom navigation container
- `ScheduleScreen`: Daily schedule display
- `MenuScreen`: WebView-based menu display
- `ProfileScreen`: Settings configuration
- `PreferencesScreen`: App preferences

### Utilities
- `ICalendarParser`: Simplified iCal parsing
- `BlockStyling`: Schedule block color theming

## Setup

1. Open in Android Studio
2. Sync Gradle dependencies
3. Configure your calendar URLs and tokens in the Profile screen
4. Build and run on device/emulator

## Dependencies

- Jetpack Compose BOM 2023.10.01
- Retrofit 2.9.0
- Kotlinx Serialization 1.6.0
- Hilt 2.48
- Android Security Crypto 1.1.0

## iOS to Android Conversion Notes

### Major Changes
- SwiftUI → Jetpack Compose
- UITabBarController → BottomNavigation
- KeychainSwift → EncryptedSharedPreferences
- Alamofire → Retrofit + OkHttp
- SwiftyJSON → Kotlinx Serialization
- UserDefaults → SharedPreferences
- WKWebView → Android WebView

### Architecture Improvements
- Added proper dependency injection with Hilt
- Implemented MVVM pattern with StateFlow
- Separated concerns with Repository pattern
- Added proper error handling and loading states

### Missing Features (Future Enhancements)
- Watch companion app (Wear OS)
- Widget support
- Canvas course integration (partially implemented)
- Advanced iCal parsing features
- Todo functionality

## Building

```bash
cd android
./gradlew assembleDebug
```

## Testing

```bash
./gradlew test
```