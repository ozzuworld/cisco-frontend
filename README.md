# Cisco Frontend Application

A Flutter application with API configuration and authentication (API Key) support.

## Features

### Core Features

#### FE-001: App Shell + Configuration + Auth (API Key)

This implementation includes:

- **App Shell**: Complete Flutter application structure with Material Design 3
- **Settings Screen**: Configure API base URL and API key
- **Secure Storage**: Platform-aware secure storage implementation
  - Android: Uses `flutter_secure_storage` with encrypted shared preferences
  - Web/Desktop: Uses in-memory storage
- **HTTP Client**: Global Dio client with interceptors for:
  - Automatic Authorization header injection
  - Error normalization with request ID tracking
  - Standard headers (Content-Type, Accept)
- **Test Connection**: Built-in connection testing with `/health` endpoint

#### FE-BG: Background & Weather System (v1.1)

**Lottie-Based Seasonal Weather Effects:**
- **Winter** → Snow particles (weather_snow.json)
- **Spring** → Flower petals (weather_petals.json)
- **Fall** → Falling leaves (weather_leaves.json)
- **Summer** → No weather effect (clean background)

**Background Presets:**
- Time-of-day aware backgrounds (Dawn/Day/Dusk/Night)
- Seasonal presets (Spring/Summer/Fall/Winter)
- Smooth crossfade transitions
- Hemisphere-aware season calculation
- User-configurable weather intensity (Off/Low/Medium/High)
- Debug panel for testing (debug builds only)

**Glass UI System:**
- Liquid glass card components with reflections
- Backdrop blur effects
- Stroke-based borders for clarity
- Interactive lighting (mouse-driven highlights)

📖 **Documentation:**
- See [`docs/BACKGROUND_SYSTEM_IMPLEMENTATION.md`](docs/BACKGROUND_SYSTEM_IMPLEMENTATION.md) for architecture
- See [`SPRINT_1_RELEASE_NOTES.md`](SPRINT_1_RELEASE_NOTES.md) for latest changes
- See [`AUDIT_REPORT.md`](AUDIT_REPORT.md) for refactoring analysis

## Project Structure

```
lib/
├── main.dart                           # App entry point
└── src/
    ├── config/
    │   ├── app_config.dart            # Configuration model
    │   └── config_service.dart        # Configuration management
    ├── models/
    │   └── api_error.dart             # Normalized error model
    ├── services/
    │   ├── http_client.dart           # HTTP client with interceptors
    │   └── storage_service.dart       # Platform-aware storage
    └── screens/
        ├── home_screen.dart           # Main home screen
        └── settings_screen.dart       # Settings/configuration screen
```

## Getting Started

### Prerequisites

- Flutter SDK 3.0.0 or higher
- Dart SDK 3.0.0 or higher

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd cisco-frontend
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the application:

**Web:**
```bash
flutter run -d chrome
```

**Android:**
```bash
flutter run -d android
```

**Desktop (Linux/macOS/Windows):**
```bash
flutter run -d linux    # or macos, windows
```

## Configuration

### Settings Screen

Access the settings screen via the settings icon in the app bar. The settings screen provides:

1. **Base URL Configuration**
   - Default: `http://192.168.1.201:8000`
   - Validates URL format (must start with http:// or https://)

2. **API Key Input**
   - Masked input field with show/hide toggle
   - Optional field

3. **Remember API Key Toggle**
   - When enabled on Android: Stores API key in encrypted secure storage
   - When enabled on Web/Desktop: Stores in memory only (session-based)
   - When disabled: No persistent storage, cleared on app restart

4. **Test Connection Button**
   - Calls `GET /health` endpoint
   - Displays:
     - Success message on 200 OK
     - "API key required" on 401
     - Error details with request ID when available

### Storage Behavior

| Platform | Remember Enabled | Remember Disabled |
|----------|-----------------|-------------------|
| Android  | Secure Storage (encrypted) | Memory Only |
| iOS      | Secure Storage (keychain) | Memory Only |
| Web      | Memory Only | Memory Only |
| Desktop  | Memory Only | Memory Only |

## HTTP Client

### Global Interceptor

The HTTP client (`HttpClientService`) automatically:

1. **Attaches Headers**:
   - `Authorization: Bearer <api_key>` (if API key is configured)
   - `Content-Type: application/json`
   - `Accept: application/json`

2. **Updates Base URL**: Dynamically uses the configured base URL

3. **Normalizes Errors**: All errors are transformed to `ApiError` model with:
   - `error`: Error type/code
   - `message`: Human-readable message
   - `requestId`: From response body `request_id` or header `X-Request-ID`
   - `requestId`: From response body `request_id` or header `X-Request-ID`
   - `statusCode`: HTTP status code

### Error Handling Example

```dart
// From response body (preferred)
{
  "error": "Unauthorized",
  "message": "Invalid API key",
  "request_id": "req_123abc"
}

// Fallback to header
X-Request-ID: req_123abc

// Display format
Error: Unauthorized
Message: Invalid API key
Request ID: req_123abc
Status Code: 401
```

## Usage Example

### Making API Calls

```dart
import 'package:provider/provider.dart';
import 'src/services/http_client.dart';

// In your widget
final httpClient = context.read<HttpClientService>();

try {
  final response = await httpClient.client.get('/your-endpoint');
  // Handle success
} on DioException catch (e) {
  final apiError = e.error as ApiError;
  // Display error
  print(apiError.toString());
}
```

### Accessing Configuration

```dart
import 'package:provider/provider.dart';
import 'src/config/config_service.dart';

// In your widget
final config = context.watch<ConfigService>().config;

print('Base URL: ${config.baseUrl}');
print('Has API Key: ${config.hasApiKey}');
```

## Dependencies

- **flutter**: Flutter SDK
- **dio** (^5.4.0): HTTP client with interceptor support
- **provider** (^6.1.1): State management
- **flutter_secure_storage** (^9.0.0): Secure storage for Android/iOS
- **lottie** (^3.0.0): Lottie animations for weather effects
- **url_launcher** (^6.2.2): URL launching for downloads

## Architecture

### State Management

Uses **Provider** for dependency injection and state management:
- `ConfigService`: Manages app configuration (ChangeNotifier)
- `HttpClientService`: Provides HTTP client instance (Provider)

### Platform Abstraction

`StorageService` automatically detects the platform and uses:
- Secure storage on Android/iOS
- In-memory storage on Web/Desktop

### Error Normalization

All API errors are normalized through the `ApiError` model, ensuring consistent error handling across the app.

## Testing

The application can be tested on multiple platforms:

```bash
# Web
flutter run -d chrome

# Android Emulator
flutter run -d android

# Desktop
flutter run -d linux
```

## Production Build & Deployment

### Building for Production

To create a production-ready build for web deployment:

```bash
# Clean build
flutter clean
flutter pub get

# Analyze code
flutter analyze --no-fatal-infos

# Build for production (CanvasKit renderer - recommended)
flutter build web --release --web-renderer canvaskit
```

**Output:** Production-optimized files in `build/web/`

### Key Production Considerations

- **Debug UI Hidden**: All debug icons and panels are hidden in production builds
- **No Debug Mode**: `kDebugMode` flag ensures debug tools only appear in development
- **Optimized Assets**: Production builds are minified and optimized
- **CanvasKit Renderer**: Recommended for glass effects and blur features

### Comprehensive Guides

For complete production build and deployment instructions, see:

- **[PRODUCTION_BUILD_GUIDE.md](PRODUCTION_BUILD_GUIDE.md)** - Detailed build commands, testing procedures, deployment platforms (Netlify, Vercel, Firebase, GitHub Pages), server configuration, and security setup
- **[DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)** - Step-by-step deployment checklist covering pre-deployment, build verification, testing, deployment, post-deployment monitoring, and rollback procedures

### Quick Production Test

Test the production build locally before deployment:

```bash
cd build/web
python3 -m http.server 8000
# Open http://localhost:8000
```

Verify:
- ❌ No debug icon in AppBar
- ❌ No "Background Debug" panel visible
- ❌ No renderer badge (bottom-left)
- ✅ Glass effects render correctly
- ✅ Weather animations work
- ✅ All features functional

## Acceptance Criteria

✅ User can set base URL + API key
✅ API key attaches to every request
✅ Errors consistently show request ID
✅ Works on Android + Web/Desktop
✅ Platform-aware secure storage
✅ Test Connection functionality

## Future Enhancements

- Add refresh token support
- Implement OAuth 2.0 flows
- Add biometric authentication for API key access
- Support multiple environment configurations
- Add network connectivity detection

## License

[Your License Here]

## Support

For issues and questions, please contact [Your Support Channel].