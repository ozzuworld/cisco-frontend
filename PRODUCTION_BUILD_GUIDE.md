# Production Build Guide
**Version:** 1.4.0
**Last Updated:** 2025-12-28

---

## 🎯 Overview

This guide explains how to build and deploy the Cisco Frontend app for production environments. Production builds are optimized, minified, and have all debug features disabled.

---

## 📋 Quick Start

### Web Production Build
```bash
# Build for web (production mode)
flutter build web --release --web-renderer canvaskit

# Output directory
ls build/web/
```

### Verify Production Build
```bash
# Serve locally to test
python3 -m http.server --directory build/web 8000

# Open browser
open http://localhost:8000
```

---

## 🔧 Build Commands

### Web Builds

#### CanvasKit (Recommended)
```bash
flutter build web --release --web-renderer canvaskit
```
**Use when:**
- Maximum visual quality needed
- Glass effects, blur, shadows important
- Target: Desktop browsers, modern mobile browsers

**Pros:**
- Best visual quality (glass effects, blur work perfectly)
- Consistent rendering across browsers
- Better for complex UI (gradients, shadows, blur)

**Cons:**
- Larger bundle size (~2-3MB)
- Slightly slower initial load

#### HTML (Lightweight)
```bash
flutter build web --release --web-renderer html
```
**Use when:**
- Smallest bundle size needed
- Target: Mobile browsers, slow connections
- Simple UI acceptable

**Pros:**
- Smaller bundle size (~1-2MB)
- Faster initial load
- Better for low-end devices

**Cons:**
- Some visual effects may not render (blur, advanced shadows)
- Glass card effects may look different

#### Auto (Adaptive)
```bash
flutter build web --release --web-renderer auto
```
**Use when:**
- Want automatic selection
- Mixed audience (desktop + mobile)

**Behavior:**
- Mobile browsers: HTML renderer
- Desktop browsers: CanvasKit renderer

---

## ✅ Production Checklist

### Before Building

- [ ] **Update Version**: Update version in `pubspec.yaml`
- [ ] **Test Debug Mode**: Verify all features work in `flutter run`
- [ ] **Code Quality**: Run `flutter analyze` (no errors)
- [ ] **Dependencies**: Run `flutter pub get`
- [ ] **Clean Build**: Run `flutter clean` to remove old artifacts

### During Build

```bash
# 1. Clean previous builds
flutter clean

# 2. Get dependencies
flutter pub get

# 3. Analyze code
flutter analyze --no-fatal-infos

# 4. Build for production
flutter build web --release --web-renderer canvaskit

# 5. Verify build output
ls -lh build/web/
```

### After Building

- [ ] **No Debug UI**: Verify no debug icons, panels, badges visible
- [ ] **Performance**: Test on target browsers (Chrome, Firefox, Safari)
- [ ] **Functionality**: Test critical user flows
- [ ] **Bundle Size**: Check `build/web/` size (should be ~2-5MB)
- [ ] **Console**: Check browser console (no errors/warnings)

---

## 🧪 Testing Production Builds

### Local Testing

#### Option 1: Python HTTP Server
```bash
cd build/web
python3 -m http.server 8000

# Open: http://localhost:8000
```

#### Option 2: Node HTTP Server
```bash
npx http-server build/web -p 8000 -c-1

# Open: http://localhost:8000
```

#### Option 3: Flutter Serve (Dev Server)
```bash
# Not recommended for production testing
# (runs in debug mode)
flutter run -d chrome --release
```

### What to Verify

1. **No Debug Elements**
   - ❌ No debug icon in AppBar
   - ❌ No "Background Debug" panel
   - ❌ No renderer badge (bottom-left)
   - ✅ Only "Reset Wizard" icon visible

2. **Visual Quality**
   - ✅ Glass cards render correctly
   - ✅ Background blurs work
   - ✅ Weather effects animate smoothly
   - ✅ Shadows and gradients look good

3. **Functionality**
   - ✅ Collection wizard works end-to-end
   - ✅ API calls succeed
   - ✅ Navigation works
   - ✅ Forms validate correctly

4. **Performance**
   - ✅ Page loads in <3 seconds
   - ✅ Animations run at 60fps
   - ✅ No console errors
   - ✅ No memory leaks

### How Debug UI is Hidden (Technical)

The app uses Flutter's `kDebugMode` constant to conditionally render debug elements:

**Renderer Badge** (collection_wizard_screen.dart:368):
```dart
if (kDebugMode && kIsWeb)
  Positioned(
    bottom: 16,
    left: 16,
    child: Container(
      // Badge showing "Renderer: CanvasKit"
    ),
  ),
```

**Debug Menu Icon** (collection_wizard_screen.dart:186):
```dart
if (kDebugMode)
  IconButton(
    icon: const Icon(Icons.developer_mode),
    tooltip: 'Debug Tools',
    onPressed: () => DebugMenu.show(context, ...),
  ),
```

**Background Debug Panel** (collection_wizard_screen.dart:406):
```dart
if (kDebugMode && _showBackgroundDebugPanel)
  const BackgroundDebugPanel(),
```

**How kDebugMode Works:**
- `kDebugMode = true` → Debug builds (`flutter run`)
- `kDebugMode = false` → Production builds (`flutter build web --release`)
- When `false`, all code inside `if (kDebugMode)` blocks is **tree-shaken** (removed from compiled output)
- Result: Zero debug UI in production builds, smaller bundle size

**Verification:**
✅ Build with `flutter build web --release`
✅ Check `build/web/main.dart.js` - debug code is completely removed
✅ Run locally - no debug UI elements visible
✅ Performance improved due to smaller bundle

---

## 🌐 Deployment

### Static Hosting (Recommended)

#### Netlify
```bash
# 1. Build
flutter build web --release --web-renderer canvaskit

# 2. Deploy
netlify deploy --prod --dir=build/web
```

#### Vercel
```bash
# 1. Build
flutter build web --release --web-renderer canvaskit

# 2. Deploy
vercel --prod build/web
```

#### Firebase Hosting
```bash
# 1. Build
flutter build web --release --web-renderer canvaskit

# 2. Deploy
firebase deploy --only hosting
```

#### GitHub Pages
```bash
# 1. Build
flutter build web --release --web-renderer canvaskit --base-href "/repo-name/"

# 2. Copy to gh-pages branch
cp -r build/web/* gh-pages/

# 3. Commit and push
cd gh-pages
git add .
git commit -m "Deploy production build"
git push origin gh-pages
```

### Server Configuration

#### MIME Types (Required for CanvasKit)
Ensure your server serves these MIME types:

```
.wasm → application/wasm
.js   → application/javascript
.json → application/json
```

#### nginx Example
```nginx
server {
    listen 80;
    server_name your-domain.com;
    root /var/www/flutter-app;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # MIME types
    types {
        application/wasm wasm;
        application/javascript js;
        application/json json;
    }

    # Caching
    location ~* \.(wasm|js|json)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

---

## 🐛 Debugging Production Builds

### Common Issues

#### 1. Debug UI Still Visible
**Problem:** Debug icons/panels visible in production

**Solution:**
```bash
# Verify you're building with --release flag
flutter build web --release --web-renderer canvaskit

# Check Flutter mode in code
if (kDebugMode) {
  // This should NOT run in production
}
```

#### 2. White Screen / Loading Forever
**Problem:** App doesn't load

**Check:**
- Browser console for errors
- Network tab for failed requests
- Base URL configuration
- CORS issues (if calling APIs)

**Solution:**
```bash
# Test locally first
python3 -m http.server --directory build/web 8000

# Check browser console (F12)
```

#### 3. Glass Effects Not Working
**Problem:** Blur, shadows don't render

**Cause:** Using HTML renderer instead of CanvasKit

**Solution:**
```bash
# Force CanvasKit renderer
flutter build web --release --web-renderer canvaskit
```

#### 4. Large Bundle Size
**Problem:** build/web/ is >10MB

**Solutions:**
```bash
# 1. Check if you have debug symbols
flutter build web --release --web-renderer canvaskit

# 2. Remove unused dependencies (pub get outdated)

# 3. Use tree-shaking (automatic in release mode)

# 4. Consider HTML renderer for smaller size
flutter build web --release --web-renderer html
```

---

## 📊 Build Optimization

### Reduce Bundle Size

```bash
# 1. Analyze bundle
flutter build web --release --analyze-size

# 2. Check for large assets
du -sh build/web/assets/*

# 3. Optimize images
# (compress PNGs, convert to WebP)

# 4. Remove unused dependencies
flutter pub outdated
```

### Improve Performance

1. **Enable Caching**
   - Configure CDN/server caching headers
   - Use service workers (PWA)

2. **Lazy Loading**
   - Split code into chunks
   - Load routes on-demand

3. **Image Optimization**
   - Use compressed images
   - Lazy load images
   - Use appropriate formats (WebP)

---

## 🔒 Security Considerations

### Before Deployment

- [ ] **Remove Debug Code**: All `kDebugMode` blocks work
- [ ] **API Keys**: No hardcoded secrets
- [ ] **HTTPS**: Use HTTPS in production
- [ ] **CORS**: Configure allowed origins
- [ ] **Headers**: Set security headers
  - Content-Security-Policy
  - X-Frame-Options
  - X-Content-Type-Options

### Security Headers Example

```nginx
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'";
add_header X-Frame-Options "SAMEORIGIN";
add_header X-Content-Type-Options "nosniff";
add_header X-XSS-Protection "1; mode=block";
```

---

## 📝 Version Management

### Versioning Strategy

```yaml
# pubspec.yaml
version: 1.4.0+4

# Format: MAJOR.MINOR.PATCH+BUILD
# 1.4.0 = User-facing version
# +4 = Build number (auto-increment)
```

### Git Tagging

```bash
# Tag production release
git tag -a v1.4.0 -m "Sprint 4: Production UI Cleanup"
git push origin v1.4.0
```

---

## 🎯 Environment Configuration

### Development
```bash
flutter run  # Debug mode, all debug tools enabled
```

### Production
```bash
flutter build web --release  # Production mode, debug tools hidden
```

### Feature Flags (Future)
```dart
// lib/src/config/environment.dart
class Environment {
  static const bool isProduction = bool.fromEnvironment('PRODUCTION', defaultValue: false);
  static const String apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8000');
}
```

---

## 📞 Support

### Build Issues
- Check Flutter version: `flutter --version`
- Check dependencies: `flutter pub get`
- Clean build: `flutter clean`
- Analyze code: `flutter analyze`

### Deployment Issues
- Verify server configuration
- Check browser console
- Test locally first
- Review deployment logs

---

## ✅ Production Readiness Checklist

### Code Quality
- [x] No debug UI elements in production
- [x] All features tested
- [x] No console errors
- [x] Code analyzed (`flutter analyze`)
- [x] Performance acceptable

### Build Configuration
- [ ] Version updated in `pubspec.yaml`
- [ ] Correct renderer selected (CanvasKit recommended)
- [ ] Build with `--release` flag
- [ ] Assets optimized

### Deployment
- [ ] Server configured (MIME types, caching)
- [ ] HTTPS enabled
- [ ] Security headers set
- [ ] CORS configured
- [ ] DNS configured

### Testing
- [ ] Test on Chrome
- [ ] Test on Firefox
- [ ] Test on Safari
- [ ] Test on mobile browsers
- [ ] Cross-browser compatibility verified

---

**Ready to deploy!** 🚀

For more details, see:
- [DEPLOYMENT_CHECKLIST.md](./DEPLOYMENT_CHECKLIST.md)
- [Flutter Web Deployment](https://docs.flutter.dev/deployment/web)
