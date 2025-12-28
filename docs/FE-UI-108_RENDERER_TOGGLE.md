# FE-UI-108: Lock Web Renderer & Document Baseline

## Status
**PLANNED** - Implementation guide and baseline requirements

---

## Goal
Stop guessing which renderer produces the best liquid glass effect. Establish renderer baseline and make it switchable for A/B testing.

---

## Problem Statement

Flutter Web supports two rendering backends:
1. **HTML renderer** (`--web-renderer html`) - CSS/Canvas2D based
2. **CanvasKit renderer** (`--web-renderer canvaskit`) - WebAssembly Skia

The `BackdropFilter` blur behaves differently on each:
- **HTML:** Uses CSS `backdrop-filter: blur()` - browser-dependent quality
- **CanvasKit:** Custom Skia blur - high fidelity, consistent, but larger bundle

**We need to:**
1. Test both renderers systematically
2. Choose the target renderer for "liquid glass" production
3. Document the decision with evidence

---

## Implementation Tasks

### 1. Add Runtime Renderer Badge

**Location:** `/lib/src/screens/collection_wizard_screen.dart` (AppBar)

**Code:**
```dart
// FE-UI-108: Renderer badge (shows active web renderer)
Positioned(
  bottom: 8,
  left: 16,
  child: Container(
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.7),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Colors.white.withOpacity(0.3),
        width: 1,
      ),
    ),
    child: Text(
      'Renderer: ${_getActiveRenderer()}',
      style: TextStyle(
        color: Colors.white.withOpacity(0.9),
        fontSize: 11,
        fontFamily: 'monospace',
      ),
    ),
  ),
),
```

**Helper method:**
```dart
String _getActiveRenderer() {
  // Flutter Web doesn't expose renderer at runtime easily
  // Use build-time constant or UA detection
  return kIsWeb ? 'HTML (detected)' : 'N/A';
}
```

**Alternative:** Use conditional compilation:
```dart
const String kWebRenderer = String.fromEnvironment('FLUTTER_WEB_RENDERER', defaultValue: 'auto');
```

---

### 2. Build Scripts for Each Renderer

**Location:** `/scripts/` (create if doesn't exist)

**`build_html.sh`:**
```bash
#!/bin/bash
echo "Building with HTML renderer..."
flutter build web --release --web-renderer html
echo "Build complete: build/web (HTML)"
```

**`build_canvaskit.sh`:**
```bash
#!/bin/bash
echo "Building with CanvasKit renderer..."
flutter build web --release --web-renderer canvaskit
echo "Build complete: build/web (CanvasKit)"
```

**Make executable:**
```bash
chmod +x scripts/build_html.sh scripts/build_canvaskit.sh
```

---

### 3. Baseline Screenshot Requirements

**Directory:** `/screenshots/baseline/`

**Naming Convention:**
```
FE-UI-108_<renderer>_<zoom>_<state>.png
```

**Required Screenshots (8 total):**

| Renderer | Zoom | State | Filename |
|----------|------|-------|----------|
| HTML | 100% | normal | `FE-UI-108_html_100_normal.png` |
| HTML | 100% | blur-off | `FE-UI-108_html_100_blur-off.png` |
| HTML | 100% | env-off | `FE-UI-108_html_100_env-off.png` |
| HTML | 100% | test-pattern | `FE-UI-108_html_100_test-pattern.png` |
| CanvasKit | 100% | normal | `FE-UI-108_canvaskit_100_normal.png` |
| CanvasKit | 100% | blur-off | `FE-UI-108_canvaskit_100_blur-off.png` |
| CanvasKit | 100% | env-off | `FE-UI-108_canvaskit_100_env-off.png` |
| CanvasKit | 100% | test-pattern | `FE-UI-108_canvaskit_100_test-pattern.png` |

**Additional (Optional):**
- 125% zoom versions (8 more screenshots)
- 150% zoom versions (8 more screenshots)

---

### 4. Comparison Matrix

**Location:** `/docs/RENDERER_COMPARISON.md`

**Template:**
```markdown
# Renderer Comparison Results

## Test Date: [YYYY-MM-DD]
## Tested By: [Name]
## Browser: Chrome [Version]

---

## Visual Quality Comparison

| Feature | HTML Renderer | CanvasKit Renderer |
|---------|---------------|-------------------|
| Blur Quality | [Rating 1-5] | [Rating 1-5] |
| Refraction Visible | [Yes/No] | [Yes/No] |
| Band Sharpness | [Rating 1-5] | [Rating 1-5] |
| Reflection Fidelity | [Rating 1-5] | [Rating 1-5] |
| Specular Highlights | [Rating 1-5] | [Rating 1-5] |
| 100% Zoom | [Pass/Fail] | [Pass/Fail] |
| 125% Zoom | [Pass/Fail] | [Pass/Fail] |

---

## Performance Comparison

| Metric | HTML Renderer | CanvasKit Renderer |
|--------|---------------|-------------------|
| Bundle Size | ~X MB | ~X MB |
| Initial Load | ~X ms | ~X ms |
| Frame Rate (Blur ON) | X fps | X fps |
| Memory Usage | ~X MB | ~X MB |

---

## Browser Support

| Browser | HTML Renderer | CanvasKit Renderer |
|---------|---------------|-------------------|
| Chrome 120+ | [Pass/Fail] | [Pass/Fail] |
| Safari 16+ | [Pass/Fail] | [Pass/Fail] |
| Firefox 115+ | [Pass/Fail] | [Pass/Fail] |
| Edge 120+ | [Pass/Fail] | [Pass/Fail] |

---

## Decision

**Chosen Renderer:** [HTML / CanvasKit]

**Rationale:**
[Explain why this renderer was chosen based on quality, performance, and compatibility]

**Trade-offs Accepted:**
[List any known limitations of the chosen renderer]

**Fallback Strategy:**
[What to do if the chosen renderer fails on a browser]

---

## Evidence

- See `/screenshots/baseline/` for visual comparison
- Performance metrics from Chrome DevTools
- Cross-browser testing results attached
```

---

## Acceptance Criteria

- [ ] Runtime renderer badge displays in Collection Wizard
- [ ] Build scripts for both renderers created and tested
- [ ] 8 baseline screenshots captured (4 per renderer)
- [ ] Comparison matrix completed with ratings
- [ ] Team agrees on target renderer for production
- [ ] Decision documented with rationale

---

## Implementation Notes

### Detecting Active Renderer at Runtime

Flutter Web doesn't expose the renderer choice at runtime easily. Options:

**Option 1: Build-time constant**
```dart
const String kWebRenderer = String.fromEnvironment('FLUTTER_WEB_RENDERER', defaultValue: 'auto');
```

Build with:
```bash
flutter build web --dart-define=FLUTTER_WEB_RENDERER=html
```

**Option 2: User Agent detection**
```dart
import 'dart:html' as html;

String detectRenderer() {
  // CanvasKit uses WebAssembly
  if (html.window.navigator.userAgent.contains('wasm')) {
    return 'CanvasKit (detected)';
  }
  return 'HTML (detected)';
}
```

**Option 3: Manual toggle**
```dart
// Dev-only toggle
bool _useCanvasKitBadge = false; // Set manually based on build
```

---

## Testing Workflow

### 1. Build HTML Version
```bash
./scripts/build_html.sh
cd build/web
python3 -m http.server 8000
```

Open `http://localhost:8000` and capture 4 screenshots

### 2. Build CanvasKit Version
```bash
./scripts/build_canvaskit.sh
cd build/web
python3 -m http.server 8000
```

Open `http://localhost:8000` and capture 4 screenshots

### 3. Compare Side-by-Side
- Open both sets in image viewer
- Look for blur quality, refraction visibility, reflection fidelity
- Test at 100%, 125%, 150% zoom
- Test on Chrome, Safari, Firefox if available

### 4. Document Decision
- Fill out comparison matrix
- Capture performance metrics
- Write rationale for chosen renderer

---

## Expected Outcome

**Recommended Renderer: HTML** (Predicted)

**Reasoning:**
- Smaller bundle size (~2MB less)
- Faster initial load
- Native browser support for `backdrop-filter`
- Good enough quality for most users

**Trade-off:**
- Blur quality may vary by browser
- Older browsers may not support `backdrop-filter`

**Fallback:**
- Use CanvasKit for browsers without `backdrop-filter` support
- Or provide "basic" theme without blur

---

## Related Tickets

- **FE-UI-103:** Web Renderer Validation Matrix (documentation)
- **FE-UI-112:** Glass QA Harness (screenshot capture tool)
- **FE-UI-114:** Testing Requirements (command output + screenshots)

---

## Version History

- **2025-12-28:** FE-UI-108 - Implementation plan created
