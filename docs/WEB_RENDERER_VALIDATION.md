# FE-UI-103: Web Renderer Validation Matrix

## Overview
Flutter Web supports two rendering backends that behave differently with `BackdropFilter` blur effects. This document validates which renderer provides the best glass/liquid effect for the Collection Wizard card.

---

## Rendering Backends

### 1. **HTML Renderer** (`--web-renderer html`)
- Uses HTML/CSS/Canvas2D
- Lighter weight, faster initial load
- **Blur behavior:** Uses CSS `backdrop-filter: blur()`
- Browser support: Chrome 76+, Safari 9+, Firefox with flag

### 2. **CanvasKit Renderer** (`--web-renderer canvaskit`)
- Uses WebAssembly-compiled Skia engine
- Higher fidelity, matches mobile Flutter exactly
- **Blur behavior:** Custom Skia blur implementation
- Larger bundle size (~2MB additional)

---

## Test Matrix

Test the glass card effect under these conditions:

| Renderer | Browser Zoom | Blur Quality | Refraction Visible | Performance | Status |
|----------|--------------|--------------|-------------------|-------------|--------|
| HTML | 100% | ⚠️ CSS blur | ✅ Yes (if env has contrast) | ⚡ Fast | To Test |
| HTML | 125% | ⚠️ May degrade | ❓ Needs validation | ⚡ Fast | To Test |
| CanvasKit | 100% | ✅ High fidelity | ✅ Yes | 🐢 Slower | To Test |
| CanvasKit | 125% | ✅ Consistent | ✅ Yes | 🐢 Slower | To Test |

---

## How to Test

### Build with HTML Renderer
```bash
flutter build web --web-renderer html --release
```

### Build with CanvasKit Renderer
```bash
flutter build web --web-renderer canvaskit --release
```

### Run Local Server
```bash
cd build/web
python3 -m http.server 8000
```

Then open: `http://localhost:8000`

---

## Validation Checklist

For **each** renderer + zoom combination, verify:

- [ ] **Environment visibility:** Can you see at least 2 blooms + 1 diagonal band behind the card?
- [ ] **Blur refraction:** With blur ON, environment elements visibly distort/warp
- [ ] **Fill proof test:** Toggle the "Fill Proof" button - card should NOT turn pink
- [ ] **A/B environment test:** Toggle "Environment Plate" - card should change from "glass" to "grey fog"
- [ ] **Blur toggle test:** Toggle "Blur" - environment should appear sharp when blur is OFF
- [ ] **Specular highlights:** Can you see rim strokes, top highlight, corner glows?
- [ ] **Input fields:** Are inputs transparent with rim-only borders?

---

## Known Issues & Workarounds

### HTML Renderer
**Issue:** Some browsers don't support `backdrop-filter` or require prefixes
**Workaround:** Check `CSS.supports('backdrop-filter', 'blur(10px)')` and provide fallback

**Issue:** Blur quality may vary by browser/GPU
**Workaround:** Test on Chrome/Edge (best support), Safari (good), Firefox (limited)

### CanvasKit Renderer
**Issue:** Large bundle size (~2MB extra)
**Workaround:** Use lazy loading or progressive web app caching

**Issue:** Slower initial paint
**Workaround:** Show loading spinner, use `flutter build web --profile` for debugging

---

## Recommendation

### Development
Use **auto** renderer (Flutter chooses based on browser):
```bash
flutter run -d chrome --web-renderer auto
```

### Production
**Primary:** HTML renderer (smaller bundle, better performance)
**Fallback:** CanvasKit if blur quality is insufficient on target browsers

Test on:
- Chrome 120+ (primary target)
- Safari 16+ (macOS/iOS)
- Edge 120+
- Firefox 115+ (limited backdrop-filter support)

---

## Test Screenshots

When completing validation, capture 4 screenshots:

1. **HTML @ 100%** - Blur ON, Environment ON
2. **HTML @ 125%** - Blur ON, Environment ON
3. **CanvasKit @ 100%** - Blur ON, Environment ON
4. **CanvasKit @ 125%** - Blur ON, Environment ON

Save to: `/docs/screenshots/renderer_validation/`

---

## Decision Log

**Date:** 2025-12-28
**Status:** Pending validation
**Recommendation:** Will be determined after testing

**Critical Success Criteria:**
1. ✅ Blur must visibly distort at least 2 environment elements
2. ✅ Card fill must remain 0% (passes Fill Proof test)
3. ✅ Specular highlights must be visible (rim strokes, corner glows)
4. ✅ Performance acceptable on target devices

---

## Related Tickets

- **FE-UI-101:** Environment intersection requirement (fixed - increased contrast)
- **FE-UI-102:** Environment A/B toggle (implemented - `_showEnvironmentPlate`)
- **FE-UI-104:** Minimal shadow requirement (implemented - 10% opacity, 8px blur)
- **FE-UI-105:** Specular/reflection pass (implemented - highlights + rim strokes)
- **FE-UI-106:** Glass input fields (implemented - transparent fill, rim borders)
- **FE-UI-107:** Glass stage background (fixed - diagonal bands + increased bloom contrast)

---

## Browser DevTools Validation

### Check Blur Support
```javascript
// In browser console
CSS.supports('backdrop-filter', 'blur(10px)')  // Should return true
CSS.supports('-webkit-backdrop-filter', 'blur(10px)')  // Safari fallback
```

### Inspect Rendered Blur
1. Right-click card → Inspect
2. Look for `backdrop-filter: blur(5px)` in Computed styles (HTML renderer)
3. Or check Canvas element rendering (CanvasKit renderer)

---

## Performance Benchmarks

| Renderer | Initial Load | Frame Rate (Blur ON) | Memory Usage |
|----------|--------------|---------------------|--------------|
| HTML | ~500ms | 60fps | ~50MB | To Measure |
| CanvasKit | ~1200ms | 60fps | ~80MB | To Measure |

Target: **60fps** with blur enabled on mid-range devices (2019+ laptops/tablets)
