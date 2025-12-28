# FE-UI-087: Glass Reference Match Tests

## ⚠️ CRITICAL: Cannot Close Ticket Without Passing ALL Tests

This document provides **MEASURABLE, OBJECTIVE tests** to prove liquid glass implementation matches reference behavior.

---

## Test Suite Overview

| Test # | Test Name | Pass Criteria | Debug Tool |
|--------|-----------|---------------|------------|
| 1 | Fill Test (Checkerboard) | Checkerboard visible through blur | Test pattern toggle |
| 2 | Child Paint Test | 0 children painting backgrounds | Fill proof overlay |
| 3 | Web Zoom Test | Glass crisp at 100%/125%/150% | Chrome DevTools |
| 4 | Refraction Test | Environment ON = glass, OFF = fog | Environment toggle |

**All 4 tests MUST pass. No exceptions.**

---

## Test 1: Fill Test (Checkerboard Proof)

**Goal**: Prove fill is actually 0% by showing background pattern through blur.

### Procedure:

1. Open wizard: `flutter run -d chrome`
2. Click **Test Pattern toggle** (grid icon) in AppBar → **ON**
3. Observe colorful gradient pattern through glass card

### Pass Criteria:

- [ ] Colorful test pattern **visible through card center**
- [ ] Blur refracts colors (subtle color shift inside card)
- [ ] Pattern NOT completely hidden by grey fog
- [ ] Card center looks **different** from edges (blur effect present)

### Fail Indicators:

- ❌ Card center is solid grey (no pattern visible)
- ❌ Pattern completely blocked
- ❌ No color variation inside card
- ❌ Looks like opaque panel

### Screenshot Requirements:

**Required**: 2 side-by-side screenshots
1. `test-pattern-OFF.png` - Normal view (subtle environment)
2. `test-pattern-ON.png` - Test pattern visible through glass

**Location**: Save to `/docs/qa/fe-ui-087/`

---

## Test 2: Child Paint Test (Zero Background Audit)

**Goal**: Prove NO child widgets inside GlassCard are painting backgrounds.

### Procedure:

1. Open wizard
2. Click **Fill Proof toggle** (bug icon) in AppBar → **ON**
3. Observe debug overlay on glass card

### Pass Criteria:

- [ ] Green border around card (debug mode active)
- [ ] Text reads: **"PASS: Fill = 0% (transparent)"**
- [ ] NO hot pink fill visible
- [ ] Label is GREEN color (not hot pink)

### Fail Indicators:

- ❌ Hot pink overlay visible anywhere
- ❌ Text reads "FAIL: Fill opacity = X%"
- ❌ Hot pink label color
- ❌ Any non-zero fill percentage

### Screenshot Requirements:

**Required**: 1 screenshot
1. `fill-proof-debug.png` - Debug overlay showing PASS state

**Location**: Save to `/docs/qa/fe-ui-087/`

### Code Verification:

```bash
# Search for non-transparent fills
grep -r "withOpacity(0\.[1-9]" lib/src/ui/glass_card.dart

# Should return ONLY:
# - Border opacities (0.40, 0.15) ✓
# - Highlight opacities (0.10, 0.17, etc.) ✓
# - Shadow opacity (0.15) ✓
# - NOT fill color (must be 0.0) ✓
```

---

## Test 3: Web Zoom Test (Crisp at All Scales)

**Goal**: Verify glass renders correctly at different browser zoom levels.

### Procedure:

1. Run: `flutter run -d chrome --web-renderer html`
2. Open Chrome DevTools (F12)
3. Test at multiple zoom levels:
   - 100% (Ctrl+0)
   - 125% (Ctrl++)
   - 150% (Ctrl++)
   - 175% (Ctrl++)

### Pass Criteria:

- [ ] **100% zoom**: Glass borders crisp, blur smooth
- [ ] **125% zoom**: No pixelation, borders remain 1px
- [ ] **150% zoom**: Blur scales correctly, no artifacts
- [ ] **175% zoom**: Still readable, no broken layout

### Fail Indicators:

- ❌ Blur disappears at high zoom
- ❌ Borders become thick/fuzzy
- ❌ Pixelation or jagged edges
- ❌ Layout breaks or overlaps
- ❌ Performance drops below 60fps

### Screenshot Requirements:

**Required**: 4 screenshots
1. `zoom-100.png` - Chrome at 100% zoom
2. `zoom-125.png` - Chrome at 125% zoom
3. `zoom-150.png` - Chrome at 150% zoom
4. `zoom-175.png` - Chrome at 175% zoom

**Location**: Save to `/docs/qa/fe-ui-087/`

### Performance Check:

- Open Chrome DevTools → Performance monitor
- Record 5 seconds of scrolling
- **Pass**: Frame time < 16ms (60fps)
- **Fail**: Frame time > 16ms or dropped frames

---

## Test 4: Refraction Test (Environment Plate A/B)

**Goal**: Prove blur refracts environment detail (NOT grey fog over flat black).

### Procedure:

1. Open wizard
2. Click **Environment toggle** (landscape icon) in AppBar
3. Toggle **ON → OFF → ON** and observe card appearance

### Pass Criteria:

- [ ] **Environment ON** (green icon):
  - Glass card has subtle detail through blur
  - Card interior looks like transparent glass
  - Background reads as BLACK overall (not pink/purple)
  - Blur refracts subtle texture/blooms

- [ ] **Environment OFF** (red icon):
  - Glass card becomes GREY FOG
  - Card looks like solid grey panel
  - Blur over pure black = grey slab
  - NO detail visible inside card

- [ ] **Toggle proves causation**:
  - ON → OFF: glass becomes fog
  - OFF → ON: fog becomes glass
  - Repeatable behavior

### Fail Indicators:

- ❌ Environment OFF and card still looks like glass (not using environment)
- ❌ Environment ON and card still grey fog (blur broken)
- ❌ Toggle has no visible effect
- ❌ Background washes to purple/pink (blooms too strong)

### Screenshot Requirements:

**Required**: 2 screenshots
1. `environment-ON.png` - Green icon, glass appearance
2. `environment-OFF.png` - Red icon, grey fog appearance

**Location**: Save to `/docs/qa/fe-ui-087/`

### A/B Comparison Checklist:

| Feature | Environment ON | Environment OFF |
|---------|----------------|-----------------|
| Card appearance | Transparent glass | Grey fog/slab |
| Interior detail | Subtle refraction | Flat grey |
| Background | Black with blooms | Pure black |
| Glass definition | Rim + environment | Rim only (fails) |

---

## One-Line Truth (Paste to Team)

**If the card still looks grey with '0% fill', then either:**

**(A)** A child widget is still painting a surface (run Test 2: Fill Proof), **OR**

**(B)** The blur is averaging a too-uniform background (run Test 4: Environment A/B).

**Prove which with debug overlays + A/B toggles. No more "implemented ✅" without screenshots.**

---

## Test Execution Checklist

Before closing FE-UI-087 ticket:

- [ ] Test 1: Fill test passed (checkerboard visible)
- [ ] Test 2: Child paint test passed (0 backgrounds)
- [ ] Test 3: Web zoom test passed (100/125/150/175%)
- [ ] Test 4: Refraction test passed (A/B proof)
- [ ] All 8 screenshots captured and saved
- [ ] Screenshots reviewed by team lead
- [ ] No visual regressions from previous version

**Pass Criteria**: 4/4 tests passed + all screenshots approved

---

## Debug Tools Quick Reference

| Tool | Icon | Color When Active | Purpose |
|------|------|-------------------|---------|
| Fill Proof | Bug | Hot Pink | Detect non-transparent fills |
| Environment | Landscape | Green (ON) / Red (OFF) | Prove refraction vs fog |
| Test Pattern | Grid | Orange | Show checkerboard through blur |
| Reset | Refresh | White | Clear wizard state |

**Location**: AppBar actions (top-right corner)

---

## Common Failure Modes & Fixes

### Failure: Card looks grey even with fill = 0%

**Diagnosis**:
```bash
# Check environment plate is enabled
grep "bool _showEnvironmentPlate" lib/src/screens/collection_wizard_screen.dart
# Should default to: true
```

**Fix**: Ensure environment toggle is ON (green icon)

---

### Failure: Hot pink overlay visible (Test 2 fails)

**Diagnosis**:
```bash
# Find non-transparent fill
grep "_glassFillColor" lib/src/ui/glass_card.dart
# Should be: static const Color _glassFillColor = Colors.transparent;
```

**Fix**: Verify `_glassFillColor.opacity == 0.0`

---

### Failure: Blur doesn't show through card (Test 1 fails)

**Diagnosis**:
```bash
# Check BackdropFilter is present
grep "BackdropFilter" lib/src/ui/glass_card.dart
# Should wrap Container with blur filter
```

**Fix**: Ensure `ClipRRect → BackdropFilter → Container` structure

---

### Failure: Zoom breaks layout (Test 3 fails)

**Diagnosis**:
- Check browser: Chrome/Edge only (Firefox/Safari limited support)
- Check renderer: Must use `--web-renderer html`

**Fix**:
```bash
flutter run -d chrome --web-renderer html
```

---

## Regression Prevention

**Before each commit to liquid glass code**:

1. Run all 4 tests
2. Capture new screenshots
3. Compare with baseline screenshots
4. Pass visual diff review

**Before merge to main**:

1. All 4 tests passing
2. Screenshot approval from design lead
3. No performance regressions (<16ms frame time)
4. Cross-browser testing (Chrome + Edge minimum)

---

## Measured Values (Reference)

| Property | Value | Test |
|----------|-------|------|
| Glass fill opacity | 0.0% | Test 2 |
| Outer rim opacity | 40% | Visual |
| Inner rim opacity | 15% | Visual |
| Blur sigma | 5.0 | Code |
| Shadow opacity | 15% | Visual |
| Shadow blur | 12px | Code |
| Shadow offset | (0, 2) | Code |
| Environment blooms | 4-7% | Visual |
| Test pattern opacity | 10-15% | Test 1 |

---

## Appendix: Manual Verification (No Debug Tools)

If debug toggles unavailable, manual checks:

### Check 1: Fill = 0%
```dart
// lib/src/ui/glass_card.dart:109
color: _glassFillColor,  // Must be Colors.transparent

// lib/src/ui/glass_card.dart:39
static const Color _glassFillColor = Colors.transparent;
```

### Check 2: Environment Plate Exists
```dart
// lib/src/screens/collection_wizard_screen.dart
// Lines 222-394: Must have bloom gradients, noise, vignette
if (_showEnvironmentPlate) ...[
  // Large blooms (700-800px)
  // Background noise (4%)
  // Micro vignette (15%)
  // Charcoal gradients
  // Shape blobs
  // Micro blooms (180-250px)
]
```

### Check 3: BackdropFilter Active
```dart
// lib/src/ui/glass_card.dart:92
BackdropFilter(
  filter: ImageFilter.blur(
    sigmaX: 5.0,  // Must be > 0
    sigmaY: 5.0,
  ),
)
```

### Check 4: No Material Surface Bleed
```dart
// lib/main.dart:50
dialogBackgroundColor: Colors.transparent,

// lib/main.dart:56
fillColor: Colors.transparent,

// lib/main.dart:184-186
backgroundColor: isDark
    ? DesignTokens.backgroundBase.withOpacity(0.95)
    : Colors.white.withOpacity(0.95),
```

---

## Success Criteria Summary

✅ **Test 1 PASS**: Colorful test pattern visible through blur

✅ **Test 2 PASS**: Debug overlay shows "PASS: Fill = 0%" in green

✅ **Test 3 PASS**: Glass crisp at 100%, 125%, 150%, 175% zoom

✅ **Test 4 PASS**: Environment ON = glass, OFF = grey fog (A/B proven)

✅ **Screenshots**: All 8 captured and approved

✅ **Performance**: <16ms frame time in Chrome

✅ **Code Review**: No regressions, zero-fill enforced

**Only when ALL criteria met → FE-UI-087 can close ✅**
