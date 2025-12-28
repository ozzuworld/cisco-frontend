# FE-UI-095: FINAL PASS/FAIL GATE

## ⚠️ NO SUBJECTIVE APPROVAL - OBJECTIVE TESTS ONLY

This gate **CANNOT** be passed with "looks good to me."

**ALL 5 tests MUST pass**. No exceptions. No partial credit.

---

## Gate Status: ⬜ NOT PASSED

**Pass Criteria**: 5/5 tests passed + screenshots approved

**Current Status**: Awaiting test execution

---

## Test 1: Checkerboard Visibility Test

### Goal
Prove fill is 0% by showing background pattern through blur.

### Procedure
1. Open wizard: `flutter run -d chrome`
2. Click test pattern toggle (grid icon) → ON
3. Observe glass card center

### HARD Pass Conditions

- [ ] Colorful test pattern **visible through card**
- [ ] Colors shift/blend inside card (blur refraction)
- [ ] Pattern NOT solid grey or completely hidden
- [ ] Card center looks **different** from no-card area

### HARD Fail Conditions

- ❌ Card center is solid grey (opaque panel)
- ❌ Test pattern completely invisible
- ❌ No visible blur effect
- ❌ Looks like filled rectangle

### Measurement

**Luminance check** (Chrome DevTools color picker):
- Sample card center pixel
- Sample background pixel outside card
- **PASS**: Luminance delta < 5% (nearly identical)
- **FAIL**: Luminance delta > 10% (grey panel)

### Screenshot Required

`test1-checkerboard.png` - Must show pattern visible through glass

**Status**: ⬜ PENDING

---

## Test 2: Gradient Bend Test

### Goal
Prove blur distorts recognizable background features.

### Procedure
1. Enable test pattern (grid icon) → ON
2. Observe striped circle at (top: 250, left: 100)
3. Move glass card to partially cover circle
4. Compare covered vs uncovered edge

### HARD Pass Conditions

- [ ] Circle edge **visibly bends/softens** under glass
- [ ] Colors blend at glass boundary
- [ ] Sharp edge outside glass vs soft edge inside glass
- [ ] Refraction effect unmistakable

### HARD Fail Conditions

- ❌ Circle edge looks identical through glass
- ❌ No visible distortion or color shift
- ❌ Glass acts like transparent rectangle (no refraction)
- ❌ Can't tell where glass starts/ends

### Measurement

**Edge sharpness test**:
- Screenshot with glass over shape
- Measure pixel color gradient at edge
- **PASS**: Gradient spans > 5px (blur visible)
- **FAIL**: Gradient < 2px (sharp edge, no blur)

### Screenshot Required

`test2-gradient-bend.png` - Must show shape distortion

**Status**: ⬜ PENDING

---

## Test 3: Solid Black Failure Test

### Goal
Prove glass requires environment by showing it fails over solid black.

### Procedure
1. Click environment toggle (landscape icon) → OFF (red)
2. Observe glass card appearance
3. Compare to environment ON state

### HARD Pass Conditions

- [ ] Environment OFF → card becomes **grey fog/slab**
- [ ] Environment ON → card becomes **transparent glass**
- [ ] Toggle creates **drastic visual change**
- [ ] Repeatable A/B difference

### HARD Fail Conditions

- ❌ Environment OFF and card still looks like glass
- ❌ Toggle has no visible effect
- ❌ Can't see difference between ON/OFF
- ❌ Card always looks grey OR always looks clear

### Measurement

**A/B luminance test**:
- Screenshot with environment ON
- Screenshot with environment OFF
- **PASS**: Card luminance changes > 15%
- **FAIL**: Card luminance changes < 5%

### Screenshots Required

1. `test3-env-ON.png` - Environment ON (glass)
2. `test3-env-OFF.png` - Environment OFF (fog)

**Status**: ⬜ PENDING

---

## Test 4: Light Direction Visibility Test

### Goal
Prove glass has directional lighting (not flat panel).

### Procedure
1. Open wizard at 100% browser zoom
2. Observe glass card edges
3. Compare top-left vs bottom-right brightness

### HARD Pass Conditions

- [ ] Top-left edge **visibly brighter** than bottom-right
- [ ] Diagonal specular sweep visible (top-left → bottom-right)
- [ ] Card feels **tilted** in 3D space (not flat)
- [ ] Light direction unmistakable at 100% zoom

### HARD Fail Conditions

- ❌ All edges same brightness (flat lighting)
- ❌ No diagonal highlight visible
- ❌ Card feels pasted/flat (no perceived depth)
- ❌ Can't identify light source direction

### Measurement

**Edge brightness comparison**:
- Sample top-left edge pixel (RGB)
- Sample bottom-right edge pixel (RGB)
- Calculate luminance: (0.2126×R + 0.7152×G + 0.0722×B)
- **PASS**: Top-left luminance > bottom-right by ≥ 30%
- **FAIL**: Luminance difference < 15%

### Screenshot Required

`test4-light-direction.png` - Must show brighter top-left

**Status**: ⬜ PENDING

---

## Test 5: Zero Fill Proof Test

### Goal
Prove fill opacity is exactly 0.0% (not 1%, not 5%, ZERO).

### Procedure
1. Click fill proof toggle (bug icon) → ON
2. Observe debug overlay on glass card
3. Read label text

### HARD Pass Conditions

- [ ] Green border around card (debug mode active)
- [ ] Label reads: **"PASS: Fill = 0% (transparent)"**
- [ ] Label color is **GREEN** (not hot pink)
- [ ] NO hot pink overlay visible anywhere

### HARD Fail Conditions

- ❌ Hot pink overlay visible
- ❌ Label reads "FAIL: Fill opacity = X%"
- ❌ Label color is hot pink (failure state)
- ❌ Any fill percentage > 0.0%

### Measurement

**Code verification**:
```bash
# Verify _glassFillColor is transparent
grep "_glassFillColor = " lib/src/ui/glass_card.dart

# Expected output:
# static const Color _glassFillColor = Colors.transparent;
```

**PASS**: Output exactly matches expected

**FAIL**: Any other color or opacity value

### Screenshot Required

`test5-fill-proof.png` - Must show green "PASS" label

**Status**: ⬜ PENDING

---

## Scoring Matrix

| Test # | Test Name | Status | Screenshot |
|--------|-----------|--------|------------|
| 1 | Checkerboard Visibility | ⬜ PENDING | ⬜ MISSING |
| 2 | Gradient Bend | ⬜ PENDING | ⬜ MISSING |
| 3 | Solid Black Failure | ⬜ PENDING | ⬜ MISSING (2 req) |
| 4 | Light Direction | ⬜ PENDING | ⬜ MISSING |
| 5 | Zero Fill Proof | ⬜ PENDING | ⬜ MISSING |

**Total**: 0/5 tests passed

**Screenshots**: 0/6 captured

---

## Gate Rules

### Pass Requirements

**ALL of the following MUST be true**:

1. Test 1: ✅ PASS (checkerboard visible)
2. Test 2: ✅ PASS (gradient bends)
3. Test 3: ✅ PASS (environment toggle works)
4. Test 4: ✅ PASS (light direction visible)
5. Test 5: ✅ PASS (fill = 0%)
6. Screenshots: ✅ All 6 captured and saved
7. Review: ✅ Screenshots approved by lead

### Fail Conditions

**ANY of the following causes FAIL**:

- ❌ ANY test shows FAIL status
- ❌ ANY screenshot missing
- ❌ ANY measurement outside pass range
- ❌ Subjective "looks good" without tests

---

## What Happens If Gate Fails

### Failure = Blocker

**Liquid glass ticket CANNOT close** until gate passes.

### Debug Path

**If Test 1 fails** (checkerboard not visible):
- Problem: Fill opacity > 0% OR blur not working
- Fix: Check `_glassFillColor = Colors.transparent`
- Verify: BackdropFilter present in widget tree

**If Test 2 fails** (no gradient bend):
- Problem: Blur sigma too low OR shapes not positioned correctly
- Fix: Increase blur sigma to 5.0+
- Verify: Shapes actually behind glass card

**If Test 3 fails** (environment toggle no effect):
- Problem: Environment plate too subtle OR toggle not working
- Fix: Increase bloom opacity to 12-18%
- Verify: `if (_showEnvironmentPlate)` wraps environment

**If Test 4 fails** (no light direction):
- Problem: Flat lighting OR highlights too subtle
- Fix: Increase top-left edge opacity, reduce bottom-right
- Verify: Diagonal gradient visible

**If Test 5 fails** (fill not zero):
- Problem: Fill color has opacity > 0.0
- Fix: Change to `Colors.transparent` (strict)
- Verify: Code shows `opacity == 0.0`

---

## Approval Process

### Step 1: Execute All Tests

Run wizard and perform all 5 tests systematically.

Mark each test ✅ PASS or ❌ FAIL.

### Step 2: Capture Screenshots

Save all 6 required screenshots:
1. `test1-checkerboard.png`
2. `test2-gradient-bend.png`
3. `test3-env-ON.png`
4. `test3-env-OFF.png`
5. `test4-light-direction.png`
6. `test5-fill-proof.png`

**Location**: `/docs/qa/fe-ui-095/`

### Step 3: Measurements

Record actual measurements:
- Test 1: Luminance delta = ___% (must be < 5%)
- Test 2: Edge gradient span = ___px (must be > 5px)
- Test 3: A/B luminance change = ___% (must be > 15%)
- Test 4: Top-left vs bottom-right = ___% (must be > 30%)
- Test 5: Code output = ___ (must match exactly)

### Step 4: Review

Submit to tech lead for approval:
- All 5 tests PASS ✓
- All 6 screenshots present ✓
- All measurements in range ✓

### Step 5: Gate Opens

**Only when**:
- Tests: 5/5 PASS
- Screenshots: 6/6 captured
- Measurements: All in range
- Review: Approved by lead

**Then**: Liquid glass ticket can close ✅

---

## One-Line Pass Criteria

**"5 objective tests passed with measurements + 6 screenshots approved. No subjective 'looks good'. No partial credit."**

---

## Final Checklist

Before submitting for approval:

- [ ] All 5 tests executed
- [ ] All 5 tests show PASS status
- [ ] All 6 screenshots captured
- [ ] All measurements recorded
- [ ] Screenshots saved to `/docs/qa/fe-ui-095/`
- [ ] No FAIL results
- [ ] No missing data
- [ ] Ready for lead review

**Gate Status**: ⬜ NOT PASSED

**When checklist complete**: Update to ✅ READY FOR REVIEW

**When approved**: Update to ✅ GATE PASSED

---

## Current Blocker Status

🔴 **BLOCKER: Gate not executed**

**Action Required**: Run all 5 tests and capture screenshots.

**Cannot proceed** until: 5/5 tests PASS + 6/6 screenshots approved.

**No workarounds**. **No exceptions**. **No "implemented ✅" without gate pass**.

---

## Appendix: Quick Test Commands

```bash
# Run wizard in Chrome
flutter run -d chrome --web-renderer html

# Open Chrome DevTools
# Press F12 in browser

# Color picker tool
# DevTools → More tools → Rendering → Color picker

# Screenshot tool
# DevTools → Device mode → Screenshot icon
```

---

## Success Criteria

✅ **Test 1**: Checkerboard visible (< 5% luminance delta)

✅ **Test 2**: Gradient bends (> 5px edge span)

✅ **Test 3**: Environment toggle (> 15% A/B change)

✅ **Test 4**: Light direction (> 30% edge brightness difference)

✅ **Test 5**: Zero fill (code matches exactly)

✅ **Screenshots**: All 6 captured and approved

✅ **Review**: Approved by tech lead

**ONLY THEN → GATE OPENS ✅**
