# Snow + Glass Compatibility QA Guide

## FE-BG-012: Snow Effect & Liquid Glass Integration Testing

This document outlines the quality assurance process for verifying that the snow particle system does not interfere with the liquid glass card effects.

---

## Test Environment Requirements

- **Browser**: Chrome 120+ and Edge 120+
- **Renderer**: CanvasKit (default for web)
- **Screen Resolution**: 1920x1080 minimum
- **Zoom Levels**: 100%, 125%, 150%

---

## QA Checklist

### 1. Glass Center Transparency (Critical)

**Objective**: Verify that snow does not cause grey fog regression in glass card centers.

**Test Steps**:
1. Set background to Winter preset
2. Enable snow at Medium intensity
3. View glass cards on the collection wizard screen
4. Check card centers for transparency

**Pass Criteria**:
- ✅ Glass card center is transparent (background visible through it)
- ✅ No grey "fog" or "frosted" appearance
- ✅ Environment blooms are visible through glass

**Fail Indicators**:
- ❌ Grey slab appearance
- ❌ Opaque card center
- ❌ Loss of refraction effect

**Debug**: Enable `debugShowFillProof` in GlassCard to verify fill is `Colors.transparent`.

---

### 2. Edge Rim Clarity (Critical)

**Objective**: Ensure glass card edge rims remain clean and visible at all zoom levels.

**Test Steps**:
1. Set snow intensity to High
2. Zoom to 100%, 125%, 150%
3. Inspect all 4 corners of glass cards
4. Check top, left, right edges for rim visibility

**Pass Criteria**:
- ✅ Dual-stroke rim visible at all zoom levels
- ✅ Outer rim (40% white) clearly defined
- ✅ Inner rim (15% white) visible
- ✅ No aliasing or jagged edges
- ✅ Snow particles do not obscure rim

**Fail Indicators**:
- ❌ Missing or faint rims
- ❌ Jagged/pixelated edges
- ❌ Snowflakes overlapping rim and reducing clarity

**Fix**: If snow obscures rims, add glass card bounding boxes to `safeArea` parameter in SnowEffect.

---

### 3. Refraction Visibility (Important)

**Objective**: Confirm that snow does not block or interfere with background refraction through glass.

**Test Steps**:
1. Enable Winter preset (blue/cyan blooms)
2. Set snow to Low, Medium, High (test all)
3. Observe background blooms refracted through glass card edges

**Pass Criteria**:
- ✅ Background blooms visible through glass at all snow intensities
- ✅ Refraction patterns intact (structured bands create visible distortion)
- ✅ No "white wash" from excessive snow density

**Fail Indicators**:
- ❌ Background blooms obscured
- ❌ Glass appears opaque
- ❌ Too much white (snow) blocking color refraction

**Fix**: Reduce snow particle density or increase particle transparency.

---

### 4. Specular Highlight Preservation (Important)

**Objective**: Verify that interactive lighting (specular reflections) remains visible with snow active.

**Test Steps**:
1. Enable Winter preset
2. Set snow to High
3. Hover mouse over glass cards
4. Observe dynamic specular highlights

**Pass Criteria**:
- ✅ Specular hotspot moves with mouse
- ✅ Edge highlights (top, left) visible
- ✅ Corner caustic glows intact
- ✅ Primary radial sheen (12-5% opacity) visible

**Fail Indicators**:
- ❌ Specular highlights obscured by snow
- ❌ Reduced highlight visibility
- ❌ Interactive lighting not responding

**Fix**: Reduce snow opacity or add Z-ordering to ensure glass renders above snow.

---

### 5. Performance Impact (Critical)

**Objective**: Ensure snow does not cause frame rate drops or input lag.

**Test Steps**:
1. Open DevTools → Performance tab
2. Set snow to High intensity
3. Hover mouse over cards (triggers specular updates)
4. Monitor frame time

**Pass Criteria**:
- ✅ Frame time <16ms (60fps) during idle
- ✅ Frame time <20ms during mouse interaction
- ✅ No input lag or stuttering
- ✅ Smooth snow animation

**Fail Indicators**:
- ❌ Frame time >16ms consistently
- ❌ Visible stuttering or jank
- ❌ Delayed mouse response

**Benchmarks**:
| Snow Intensity | Target Frame Time | Max Acceptable |
|----------------|-------------------|----------------|
| Off            | <12ms             | <14ms          |
| Low (50)       | <13ms             | <16ms          |
| Medium (100)   | <14ms             | <18ms          |
| High (150)     | <15ms             | <20ms          |

**Fix**: Reduce particle count or optimize painter.

---

### 6. Z-Ordering Verification (Important)

**Objective**: Confirm correct render order (background → snow → glass → content).

**Test Steps**:
1. Enable Winter preset with Medium snow
2. Inspect layer stacking visually
3. Verify render order

**Expected Order** (bottom to top):
1. Background renderer (blooms, bands, noise, vignette)
2. Snow particles
3. Glass cards (with backdrop blur)
4. Card content (text, buttons)

**Pass Criteria**:
- ✅ Snow appears behind glass cards
- ✅ Snow visible in background areas
- ✅ Glass cards render above snow
- ✅ Content readable and unobstructed

**Fail Indicators**:
- ❌ Snow rendering above glass
- ❌ Snow overlapping card content
- ❌ Incorrect stacking order

**Fix**: Adjust widget tree order or use `Stack` with explicit `Positioned` layers.

---

### 7. Cross-Browser Consistency (Important)

**Objective**: Verify visual consistency across rendering engines.

**Test Browsers**:
- Chrome (CanvasKit)
- Edge (CanvasKit)
- Firefox (if HTML renderer fallback is supported)

**Test Steps**:
1. Load app in each browser
2. Set Winter preset + Medium snow
3. Compare visual appearance

**Pass Criteria**:
- ✅ Snow density consistent across browsers
- ✅ Glass transparency identical
- ✅ Refraction effects match
- ✅ Performance similar (<10% variance)

**Known Issues**:
- HTML renderer may have reduced blur quality (this is expected)

---

## Screenshot Pack Requirements

For each test run, capture the following screenshots:

### Required Screenshots (8 total)

1. **Baseline**: Winter preset, snow OFF, glass card visible
2. **Low Snow**: Winter preset, snow Low, glass card center (transparent check)
3. **Medium Snow**: Winter preset, snow Medium, glass card edges (rim clarity)
4. **High Snow**: Winter preset, snow High, full view
5. **Zoom 125%**: Medium snow, zoomed to 125%, corner detail
6. **Zoom 150%**: Medium snow, zoomed to 150%, edge detail
7. **Specular Test**: High snow, mouse hovering (specular visible)
8. **Performance**: DevTools Performance tab showing <16ms frame time

**File Naming Convention**:
```
snow-qa-{preset}-{intensity}-{aspect}.png

Examples:
- snow-qa-winter-off-baseline.png
- snow-qa-winter-low-center.png
- snow-qa-winter-medium-edges.png
- snow-qa-winter-high-fullview.png
- snow-qa-winter-medium-zoom125.png
- snow-qa-winter-high-specular.png
- snow-qa-winter-high-performance.png
```

**Save Location**: `/docs/qa/backgrounds/screenshots/`

---

## Known Issues & Workarounds

### Issue 1: Snow too dense near card edges
**Symptom**: Rim visibility reduced at High intensity
**Workaround**: Implement `safeArea` exclusion zones
**Status**: Feature available in SnowEffect widget

### Issue 2: Performance drop on older hardware
**Symptom**: Frame time >20ms on integrated GPUs
**Workaround**: Auto-detect hardware and cap snow at Medium
**Status**: Future enhancement

### Issue 3: Crossfade artifacts during preset transition
**Symptom**: Brief flicker when transitioning to/from Winter
**Workaround**: Fade snow intensity during preset transitions
**Status**: Future enhancement

---

## Regression Testing

Run this QA checklist whenever:

- ✅ Background presets are modified
- ✅ GlassCard component is updated
- ✅ Snow particle system is changed
- ✅ Blur sigma values are adjusted
- ✅ Before major releases

---

## Approval Criteria

A build passes Snow + Glass QA if:

1. ✅ All 7 test sections pass
2. ✅ 8 screenshot pack captured
3. ✅ No critical fail indicators
4. ✅ Performance targets met
5. ✅ Cross-browser consistency verified

**Approver**: Lead UI Engineer
**Next Review**: Before each release

---

## Version History
- **v1.0** (2024-01-15): Initial QA guide
- **v1.1** (2024-01-20): Added specular highlight test

