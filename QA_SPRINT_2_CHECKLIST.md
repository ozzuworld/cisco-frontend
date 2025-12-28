# Sprint 2 QA & Performance Testing Checklist
**Date:** 2025-12-28
**Sprint:** Sprint 2 - Reduce Over-Engineering
**Tickets:** FE-REFACTOR-6, 7, 8, 9, 10, 11

---

## 🎯 TESTING SCOPE

### Code Changes Summary
1. **Glass Card Simplification (FE-REFACTOR-7)**
   - Reduced from 639 → 404 lines (-235 lines, 36.8%)
   - Reflection layers: 7+ → 3
   - Removed: Right edge, separate corners, specular hotspot, noise painter
   - Merged: Primary sheen + hotspot, top edge + catchlight, L+R corners

2. **Debug Modes Extraction (FE-REFACTOR-8)**
   - Created DebugGlassCard wrapper
   - Removed debug logic from production GlassCard
   - Cleaner separation of concerns

3. **Decisions Applied**
   - Decision 1 (A): KEPT interactive mouse tracking
   - Decision 2 (B): REMOVED noise painter
   - Decision 3 (B): TARGET 90% visual quality

---

## ✅ PRE-FLIGHT CHECKS

### Build & Compilation
- [ ] `flutter clean` completes successfully
- [ ] `flutter pub get` completes without errors
- [ ] `flutter analyze` shows no new errors/warnings
- [ ] `flutter build web` completes successfully
- [ ] No import errors related to glass_card.dart
- [ ] DebugGlassCard imports correctly

**Expected:** Clean build with no regressions

---

## 🎨 VISUAL REGRESSION TESTING

### Target: 90% Visual Quality Maintained

#### Test 1: Glass Card Transparency Check
**Location:** All screens with GlassCard

- [ ] Card center is transparent (no grey fog)
- [ ] Background visible through card
- [ ] Blur effect distorts background (refraction visible)
- [ ] No dark/muddy appearance

**Pass Criteria:** Card center ~identical to background with blur distortion

---

#### Test 2: Glass Edge Definition
**Location:** All glass cards

- [ ] Outer rim visible at 35-45% opacity
- [ ] Inner rim visible at 12-18% opacity
- [ ] Dual-stroke effect clear
- [ ] Borders crisp at 100% zoom

**Pass Criteria:** Clear edge definition, no blurry/muddy borders

---

#### Test 3: Reflection System Quality
**Location:** Hover over glass cards (mouse tracking)

**Before Changes (7+ layers):**
- Primary radial sheen
- Top edge highlight
- Left edge highlight
- Right edge highlight (barely visible)
- Secondary catchlight
- Top-left corner glow
- Top-right corner glow
- Specular hotspot

**After Changes (3 layers):**
- Enhanced primary sheen (merged hotspot)
- Unified top+left edge
- Centered corner glow

**Test Steps:**
1. [ ] Hover mouse over card center
2. [ ] Move mouse to top-left corner
3. [ ] Move mouse to top-right corner
4. [ ] Move mouse to bottom areas

**Check:**
- [ ] Primary sheen follows mouse (interactive lighting works)
- [ ] "Wet glass" appearance maintained
- [ ] Top edge has clear highlight
- [ ] Left edge has clear highlight
- [ ] Corner has subtle glow effect
- [ ] **Right edge** has NO highlight (removed - verify intentional)
- [ ] No noticeable quality loss vs. before

**Pass Criteria:** 90%+ visual fidelity, interactive lighting works

---

#### Test 4: Missing Features Verification
**These should be GONE (verify intentionally removed):**

- [ ] ❌ Right edge highlight - REMOVED (was barely visible)
- [ ] ❌ Separate top-left corner glow - MERGED (now centered)
- [ ] ❌ Separate top-right corner glow - MERGED (now centered)
- [ ] ❌ Separate specular hotspot - MERGED (into primary sheen)
- [ ] ❌ Noise/grain overlay - REMOVED (no subtle dots visible)
- [ ] ❌ Deprecated GlassChip class - REMOVED (use BreadcrumbChip)

**Pass Criteria:** All removed features are absent, no visual artifacts

---

#### Test 5: Noise Painter Removal
**Decision 2: B - Removed noise painter**

- [ ] No subtle grain/dots visible on glass
- [ ] Glass appearance is clean and smooth
- [ ] No noticeable quality degradation from missing noise
- [ ] Glass still looks "liquid" not "flat plastic"

**Pass Criteria:** No visible difference in glass quality without noise

---

### Cross-Screen Visual Testing
Test glass cards on all 7 screens:

1. [ ] **Home Screen** - Glass renders correctly
2. [ ] **Settings Screen** - Glass renders correctly
3. [ ] **Collection Wizard Screen** - Main glass card looks good
4. [ ] **Profile Selection Screen** - Glass renders correctly
5. [ ] **Discover Cluster Screen** - Glass renders correctly
6. [ ] **Job History Screen** - Glass renders correctly
7. [ ] **Job Status Screen** - Glass renders correctly
8. [ ] **Artifacts Screen** - Glass renders correctly

**Pass Criteria:** Consistent glass quality across all screens

---

## 🔧 DEBUG MODE TESTING (FE-REFACTOR-8)

### Test DebugGlassCard Wrapper

#### Test 1: Production Mode (No Debug)
- [ ] Use regular `GlassCard` in production
- [ ] No debug overlays visible
- [ ] No debug logic executed
- [ ] Normal glass appearance

**Pass Criteria:** Production code is clean, no debug artifacts

---

#### Test 2: Debug Mode - debugShowFillProof
- [ ] Import `DebugGlassCard` instead of `GlassCard`
- [ ] Set `debugShowFillProof: true`
- [ ] **Verify:** Green border appears (debug mode active)
- [ ] **Verify:** "PASS: Fill = 0% (transparent)" message shows
- [ ] **Verify:** NO hot pink overlay (fill is transparent)

**Pass Criteria:** Debug overlay shows PASS for transparent fill

---

#### Test 3: Debug Mode - debugDisableBlur
- [ ] Set `debugDisableBlur: true`
- [ ] **Verify:** Background visible WITHOUT blur distortion
- [ ] **Verify:** Background features sharp/clear (no refraction)
- [ ] Toggle `debugDisableBlur: false`
- [ ] **Verify:** Background blurs again (refraction visible)

**Pass Criteria:** Blur toggles correctly, proves refraction working

---

#### Test 4: Debug Mode - debugExaggerateReflections
- [ ] Set `debugExaggerateReflections: true`
- [ ] **Verify:** Reflections are 3x brighter/stronger
- [ ] **Verify:** Primary sheen very visible
- [ ] **Verify:** Corner glow very prominent
- [ ] Toggle `debugExaggerateReflections: false`
- [ ] **Verify:** Reflections return to normal intensity

**Pass Criteria:** Reflection multiplier works, helps tuning

---

## ⚡ PERFORMANCE TESTING

### Baseline Metrics (Before Sprint 2)
Record these for comparison:
- FPS with glass cards: _____ fps
- Render time (DevTools): _____ ms
- Memory usage: _____ MB
- Bundle size: _____ KB

### Sprint 2 Metrics (After Changes)
- [ ] FPS with glass cards: _____ fps (Expected: 60 fps or better)
- [ ] Render time (DevTools): _____ ms (Expected: same or faster)
- [ ] Memory usage: _____ MB (Expected: same or lower)
- [ ] Bundle size: _____ KB (Expected: -10KB from code reduction)

### Performance Goals
- [ ] Maintain 60 FPS with glass cards
- [ ] No regression in render time
- [ ] Potential improvement (fewer layers = faster rendering)
- [ ] Bundle size reduced due to code removal

---

## 🌐 CROSS-BROWSER TESTING

### Desktop Browsers
- [ ] **Chrome** (latest) - Glass effects work
- [ ] **Firefox** (latest) - Glass effects work
- [ ] **Safari** (latest) - Glass effects work
- [ ] **Edge** (latest) - Glass effects work

### Known Issues to Watch:
- Safari: Backdrop blur may render slightly differently
- Firefox: Reflection gradients may have slight variations

---

## 📱 RESPONSIVE & MOBILE TESTING

### Viewport Sizes
- [ ] **Desktop (1920x1080)** - Glass scales correctly
- [ ] **Laptop (1366x768)** - Glass scales correctly
- [ ] **Tablet (768x1024)** - Glass scales correctly
- [ ] **Mobile (375x667)** - Glass scales correctly

### Mobile Browsers (if applicable)
- [ ] iOS Safari - Glass effects work (no mouse tracking, but ok)
- [ ] Android Chrome - Glass effects work

---

## 🎯 INTERACTIVE LIGHTING TESTING (Decision 1: A - KEPT)

### Mouse Tracking Verification
- [ ] Move mouse over glass card
- [ ] **Verify:** Primary sheen follows mouse position
- [ ] **Verify:** Light position updates smoothly
- [ ] **Verify:** No lag or jank
- [ ] **Verify:** Transitions are smooth
- [ ] Move mouse quickly
- [ ] **Verify:** Tracking keeps up, no flickering

**Pass Criteria:** Interactive lighting works smoothly, premium feel maintained

---

## 🐛 REGRESSION TESTING

### Verify Nothing Broke

#### Glass Card Features Still Work
- [ ] Backdrop blur works
- [ ] Dual-stroke rim visible
- [ ] Inner shadow visible
- [ ] Contact shadow visible
- [ ] Header/body layout correct
- [ ] Padding respected
- [ ] Border radius correct
- [ ] Margin correct

#### BreadcrumbChip Still Works
- [ ] Chips render correctly
- [ ] isSelected state works
- [ ] isCompleted state works
- [ ] onTap callbacks work
- [ ] No errors about GlassChip (deprecated, removed)

#### Background System Still Works
- [ ] Weather effects render correctly
- [ ] Weather renders ABOVE background, BELOW glass cards
- [ ] Glass transparency shows weather particles
- [ ] No z-index issues

---

## 📊 COMPARISON TEST

### Before/After Visual Comparison

**Test Setup:**
1. Take screenshots of collection wizard screen:
   - Before: Use git to checkout before FE-REFACTOR-7
   - After: Current state
2. Compare side-by-side

**Comparison Checklist:**
- [ ] Overall appearance ~90% similar
- [ ] Main glass effect preserved
- [ ] Edge definition maintained
- [ ] Corner treatment acceptable
- [ ] No noticeable degradation for average user
- [ ] "Wet glass" appearance still present

**Pass Criteria:** 90%+ visual similarity, no obvious quality loss

---

## ✅ ACCEPTANCE CRITERIA CHECKLIST

### FE-REFACTOR-6: Audit & Plan
- [x] Comprehensive refactoring plan created
- [x] All reflection layers analyzed
- [x] Line reduction strategy defined
- [x] Visual quality target set (90%)

### FE-REFACTOR-7: Reduce Glass Card Layers
- [ ] Reduced from 639 → 404 lines (✅ 235 lines saved)
- [ ] Reflection layers: 7+ → 3 (✅ Done)
- [ ] Maintain 90%+ visual quality (⏳ Test)
- [ ] No performance regression (⏳ Test)
- [ ] Side-by-side comparison approved (⏳ Test)

### FE-REFACTOR-8: Extract Debug Modes
- [x] Created DebugGlassCard wrapper
- [ ] All debug modes work in wrapper (⏳ Test)
- [x] Production GlassCard has no debug logic
- [ ] Debug features still accessible (⏳ Test)

### FE-REFACTOR-9: Mouse Tracking Decision
- [x] Interactive mouse tracking KEPT (Decision 1: A)
- [ ] Mouse tracking works correctly (⏳ Test)
- [x] No regression in interactivity

### FE-REFACTOR-10: Noise Painter Decision
- [x] Noise painter REMOVED (Decision 2: B)
- [ ] No visual degradation from removal (⏳ Test)
- [x] -36 lines saved

---

## 📈 SUCCESS METRICS

Track these to measure Sprint 2 success:

### Code Quality
- [ ] Lines of Code: -235 lines from glass_card.dart (36.8% reduction)
- [ ] Reflection Layers: 7+ → 3 (57% reduction)
- [ ] Code Complexity: Reduced (fewer nested conditionals)
- [ ] Debug Logic: 100% extracted to wrapper

### Visual Quality
- [ ] 90%+ fidelity maintained (comparison test)
- [ ] No grey fog regression
- [ ] Edge definition preserved
- [ ] Interactive lighting works

### Performance
- [ ] 60 FPS maintained
- [ ] No render time regression
- [ ] Potential improvement (fewer layers)
- [ ] Bundle size reduced

### Developer Experience
- [ ] Cleaner code structure
- [ ] Easier to understand
- [ ] Easier to debug (debug wrapper separate)
- [ ] Easier to maintain

---

## 🚦 GATE CRITERIA

Sprint 2 QA is COMPLETE when:

- ✅ All 7 screens tested successfully
- ✅ Visual quality ≥ 90% of original
- ✅ No performance regressions detected
- ✅ Cross-browser testing passed
- ✅ Debug modes work in wrapper
- ✅ No critical bugs found
- ✅ Comparison test approved

---

## 🎉 FINAL VALIDATION

Before marking Sprint 2 complete:

- [ ] All acceptance criteria met
- [ ] All regression tests passed
- [ ] Performance benchmarks met
- [ ] Visual quality approved
- [ ] Documentation updated
- [ ] Team demo completed

---

## 📝 QA SUMMARY TEMPLATE

```
Sprint 2 QA Report
==================

Date: _____________
Tester: _____________
Environment: _____________

PASSED: _____ / _____
FAILED: _____ / _____

Visual Quality Score: _____% (Target: 90%+)
Performance Score: _____ FPS (Target: 60)

Critical Issues: _____
Major Issues: _____
Minor Issues: _____

Comparison Test: [ ] APPROVED  [ ] NEEDS WORK

Recommendation: [ ] PASS  [ ] PASS WITH ISSUES  [ ] FAIL

Notes:
```

---

## 🆘 TROUBLESHOOTING

### If visual quality < 90%:
1. Check reflection multiplier is 1.0 (not 3.0)
2. Verify all merged layers are working
3. Compare with before screenshots
4. Adjust opacity values if needed

### If performance regressed:
1. Check for unnecessary rebuilds
2. Verify no setState loops
3. Profile with DevTools
4. Consider further optimization

### If debug modes don't work:
1. Verify kDebugMode is true
2. Check DebugGlassCard import
3. Verify reflectionMultiplier parameter works
4. Check blur strength can be set to 0

---

**Ready to test!** 🚀
