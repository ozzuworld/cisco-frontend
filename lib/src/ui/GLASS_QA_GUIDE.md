# Liquid Glass QA Guide

## FE-UI-081: Reference Match QA Pack

### 4-Test Checklist (Must Pass 4/4)

#### ✅ Test 1: Center Transparency Test
**Goal**: Verify card center looks nearly identical to background

**Steps**:
1. Open wizard with test pattern mode OFF
2. Look at center of GlassCard (away from edges)
3. Compare card center to background area outside card

**Pass Criteria**:
- Card center matches background within 2-3% luminance
- No visible grey fog or tint layer
- Background texture visible through blur

**Fail Indicators**:
- Card center looks like grey slab
- Blur creates fog/wash effect
- Cannot see environment detail through card

---

#### ✅ Test 2: Rim Readability Test
**Goal**: Verify borders are visible and crisp at 35-45% opacity

**Steps**:
1. Open wizard in dark mode
2. Look at card edges and borders
3. Verify rim is clearly visible but not glaring

**Pass Criteria**:
- Outer rim: 40% white opacity, 1px stroke
- Inner rim: 15% white opacity, 1px stroke
- Both rims readable on #05060A background
- Edges define glass shape clearly

**Fail Indicators**:
- Rims too dim to see (below 30%)
- Rims too bright, creating halo
- Single stroke instead of dual-stroke

---

#### ✅ Test 3: Refraction Test
**Goal**: Verify blur refracts environment detail (not grey fog)

**Steps**:
1. Toggle test pattern mode ON (grid icon in AppBar)
2. Observe colorful gradient and shapes through glass
3. Verify colors refract/blur realistically

**Pass Criteria**:
- Environment gradients visible through blur
- Blur sigma = 5.0 (subtle refraction)
- Colors shift/blend through card
- Background reads BLACK (not pink/purple wash)

**Fail Indicators**:
- Blur over black = solid grey
- Cannot see test pattern through card
- Background washes to purple/pink

---

#### ✅ Test 4: Child Surface Audit
**Goal**: Verify all widgets inside GlassCard have transparent fills

**Steps**:
1. Inspect TextFormFields inside wizard steps
2. Inspect BreadcrumbChip components
3. Inspect any Container widgets in card content

**Pass Criteria**:
- TextFormField fillColor: Colors.transparent ✓
- BreadcrumbChip unselected: Colors.transparent ✓
- No solid backgrounds inside GlassCard

**Fail Indicators**:
- Grey fills on inputs
- Colored backgrounds on chips
- Opaque containers inside card

---

## FE-UI-080: Web Blur Correctness Validation

### BackdropFilter Behavior Checklist

#### Browser Testing
**Supported**: Chrome, Edge (Chromium-based)

**Steps**:
1. Run: `flutter run -d chrome --web-renderer html`
2. Open DevTools → Performance monitor
3. Verify blur renders correctly

**Pass Criteria**:
- BackdropFilter applies sigma blur correctly
- No grey rectangle overlay
- Blur refracts background (not solid wash)
- Performance acceptable (<16ms frame time)

**Known Issues**:
- Safari: Limited BackdropFilter support
- Firefox: May show as solid overlay

---

#### Zoom Level Testing

**Steps**:
1. Test at 100% browser zoom
2. Test at 125% browser zoom
3. Test at 150% browser zoom

**Pass Criteria**:
- Blur sigma scales correctly
- No pixelation artifacts
- Rim strokes remain crisp (1px)

**Fail Indicators**:
- Blur disappears at high zoom
- Thick/fuzzy borders
- Artifacts around edges

---

#### Blur Implementation Verification

**Current Settings** (FE-UI-054):
```dart
BackdropFilter(
  filter: ImageFilter.blur(
    sigmaX: 5.0,  // Reduced 50% for web performance
    sigmaY: 5.0,
  ),
)
```

**Validation**:
- [ ] Blur sigma = 5.0 (not 10.0, not 0)
- [ ] Applied inside ClipRRect (for clean edges)
- [ ] Container inside has color: Colors.transparent
- [ ] Environment layer provides refraction detail

---

## FE-UI-078: Environment Detail Layer Verification

### Environment Stack (Bottom to Top)

1. **Base**: `#05060A` solid color
2. **Large blooms**: 700-800px radial gradients @ 4-7% opacity
3. **Charcoal bands**: Linear gradient 3-4% opacity
4. **Shape blobs**: 300-400px @ 4-5% opacity
5. **Noise texture**: 4% grain overlay
6. **Micro vignette**: 15% radial darkening
7. **Micro blooms**: 180-250px @ 3-5% opacity
8. **Test pattern** (debug): Colorful gradients + shapes

### Validation Steps

1. **Check background reads as BLACK**:
   - Open wizard → background should be #05060A
   - No pink/purple wash visible
   - Blooms extremely subtle

2. **Verify blur has detail to refract**:
   - Toggle test pattern ON
   - See colors through glass blur
   - Toggle test pattern OFF
   - See subtle texture through glass

3. **Prevent grey fog**:
   - Glass WITHOUT environment = grey fog ❌
   - Glass WITH environment = transparent refraction ✓

---

## FE-UI-077: Stroke-First Enforcement

### Zero-Fill Audit Path

1. **GlassCard.dart**:
   ```dart
   // Line 124
   color: _glassFillColor,  // Colors.transparent
   ```

2. **BreadcrumbChip**:
   ```dart
   // Line 380-381 (unselected state)
   color: Colors.transparent,  // Was 5% fill - now 0%
   ```

3. **InputDecorationTheme**:
   ```dart
   // main.dart line 56
   fillColor: Colors.transparent,
   ```

4. **Dialog/SnackBar Themes**:
   ```dart
   // main.dart lines 172-199
   backgroundColor: Colors.transparent,
   ```

### Regression Prevention

**Before Merge Checklist**:
- [ ] GlassCard._glassFillColor = Colors.transparent
- [ ] No frost gradient in Stack
- [ ] BreadcrumbChip unselected = transparent
- [ ] Input fillColor = transparent
- [ ] Dialog backgroundColor = transparent

**Code Review Keywords** (search for these):
- `withOpacity(0.05)` → Should be 0.0 for glass fills
- `LinearGradient` inside GlassCard → Should only be for highlights, not fills
- `color: Colors.white` → Verify it's for borders/highlights only

---

## FE-UI-082: Micro Motion (Optional)

### Animated Specular Sweep

**Implementation** (if requested):
```dart
// Inside GlassCard build method
AnimatedPositioned(
  duration: Duration(seconds: 3),
  curve: Curves.easeInOut,
  top: _sweepPosition,
  left: 0,
  right: 0,
  child: Container(
    height: 100,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(0.08),
          Colors.transparent,
        ],
      ),
    ),
  ),
)
```

**Requirements**:
- EXTREMELY subtle (barely noticeable)
- 3-5 second loop duration
- Only on hover (desktop) or mount (mobile)
- Must not distract from content

**When to Use**:
- Premium feel for marketing pages
- NOT for functional UI (wizard forms)

---

## Common Issues & Fixes

### Issue: Glass looks grey/foggy
**Cause**: Fill opacity > 0% or insufficient environment detail
**Fix**: Verify `color: Colors.transparent` and add environment blooms

### Issue: Glass borders invisible
**Cause**: Border opacity too low (< 30%)
**Fix**: Increase to 35-45% range for outer rim

### Issue: Blur doesn't show through card
**Cause**: Web renderer issue or missing BackdropFilter
**Fix**: Use `--web-renderer html` and verify ClipRRect wrapper

### Issue: Background looks pink/purple
**Cause**: Bloom opacity too high
**Fix**: Reduce large blooms to 4-7% max

---

## Success Criteria Summary

**Pass All 4 Tests**:
1. ✅ Center transparency matches background
2. ✅ Rim readable at 35-45% opacity
3. ✅ Refraction shows environment detail
4. ✅ All children have transparent fill

**Measured Values**:
- Glass fill: 0.0% (Colors.transparent)
- Outer rim: 40% white
- Inner rim: 15% white
- Blur sigma: 5.0
- Shadow: 15% @ 12px blur @ 2px offset

**One-Line Diagnosis for Team**:
"Liquid glass = 0% fill + dual rim (40%/15%) + blur refracts environment (not grey fog)"
