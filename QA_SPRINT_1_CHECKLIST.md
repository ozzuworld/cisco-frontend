# Sprint 1 QA & Regression Testing Checklist
**Date:** 2025-12-28
**Sprint:** Sprint 1 - Quick Wins
**Tickets:** FE-REFACTOR-1, FE-REFACTOR-2, FE-REFACTOR-3

---

## 🎯 TESTING SCOPE

### Code Changes Summary
1. **Deleted:** `lib/src/ui/snow_effect.dart` (424 lines)
2. **Modified:** `lib/src/ui/weather_effect.dart` - Enable all seasonal weather
3. **Modified:** `lib/src/services/background_service.dart` - Remove auto-enable
4. **Modified:** `lib/src/ui/background_debug_panel.dart` - Update comment

---

## ✅ PRE-FLIGHT CHECKS

### Build & Compilation
- [ ] `flutter clean` completes successfully
- [ ] `flutter pub get` completes without errors
- [ ] `flutter analyze` shows no new errors/warnings
- [ ] `flutter build web` completes successfully
- [ ] `flutter build apk` completes successfully (if testing mobile)
- [ ] No import errors related to snow_effect.dart
- [ ] Bundle size analysis (compare before/after)

**Expected:** Build should complete ~2-3 seconds faster without snow_effect.dart

---

## 🌦️ WEATHER EFFECTS TESTING

### FE-REFACTOR-2: All Seasonal Weather Effects

#### Test 1: Winter Season (Snow)
- [ ] Open app
- [ ] Navigate to debug panel (if available) or settings
- [ ] Set season to "Winter"
- [ ] Set weather intensity to "Low" (0.33)
- [ ] **Verify:** Snow particles visible (weather_snow.json)
- [ ] Set intensity to "Medium" (0.66)
- [ ] **Verify:** More snow particles visible
- [ ] Set intensity to "High" (1.0)
- [ ] **Verify:** Heavy snow visible
- [ ] Set intensity to "Off" (0.0)
- [ ] **Verify:** No snow particles

#### Test 2: Spring Season (Petals) ⭐ NEW
- [ ] Set season to "Spring"
- [ ] Set weather intensity to "Low" (0.33)
- [ ] **Verify:** Petal particles visible (weather_petals.json)
- [ ] **Verify:** Petals animate and fall correctly
- [ ] **Verify:** Petals render ABOVE background, BELOW glass cards
- [ ] Set intensity to "Medium" (0.66)
- [ ] **Verify:** More petals visible
- [ ] Set intensity to "High" (1.0)
- [ ] **Verify:** Heavy petals visible
- [ ] Set intensity to "Off" (0.0)
- [ ] **Verify:** No petals

#### Test 3: Fall Season (Leaves) ⭐ NEW
- [ ] Set season to "Fall"
- [ ] Set weather intensity to "Low" (0.33)
- [ ] **Verify:** Leaf particles visible (weather_leaves.json)
- [ ] **Verify:** Leaves animate and fall correctly
- [ ] **Verify:** Leaves render ABOVE background, BELOW glass cards
- [ ] Set intensity to "Medium" (0.66)
- [ ] **Verify:** More leaves visible
- [ ] Set intensity to "High" (1.0)
- [ ] **Verify:** Heavy leaves visible
- [ ] Set intensity to "Off" (0.0)
- [ ] **Verify:** No leaves

#### Test 4: Summer Season (No Weather)
- [ ] Set season to "Summer"
- [ ] Set weather intensity to any value
- [ ] **Verify:** No weather effects shown (as designed)
- [ ] **Verify:** Background preset shows summer theme

### Time-of-Day Opacity Modulation
Test weather opacity changes based on time of day:

- [ ] **Day preset** + Winter/Low → Verify snow at 100% opacity
- [ ] **Night preset** + Winter/Low → Verify snow at 75% opacity (dimmer)
- [ ] **Dawn preset** + Winter/Low → Verify snow at 85% opacity
- [ ] **Dusk preset** + Winter/Low → Verify snow at 85% opacity
- [ ] Repeat above for Spring (petals)
- [ ] Repeat above for Fall (leaves)

### Performance Mode Testing
- [ ] Enable "Performance Mode" in debug panel
- [ ] **Verify:** Weather effects use `FrameRate.composition`
- [ ] **Verify:** FPS maintains 60fps or close
- [ ] Disable "Performance Mode"
- [ ] **Verify:** Weather effects use `FrameRate.max`
- [ ] **Verify:** No performance degradation

### Tab Lifecycle Testing
- [ ] Enable winter weather (snow)
- [ ] Switch to another browser tab
- [ ] Wait 5 seconds
- [ ] **Verify:** Animation pauses when tab inactive
- [ ] Switch back to app tab
- [ ] **Verify:** Animation resumes smoothly

---

## 🚫 NO AUTO-ENABLE TESTING

### FE-REFACTOR-3: Auto-Enable Removed

#### Test 5: Fresh App Start (No Saved Preferences)
- [ ] Clear browser storage/cache (or fresh install)
- [ ] Launch app for first time
- [ ] **Verify:** Weather intensity is OFF (0.0) by default
- [ ] Check current season (should be based on current date)
- [ ] **Verify:** Even if winter, weather does NOT auto-enable
- [ ] **Expected:** User must manually enable weather

#### Test 6: Season Change While Weather Off
- [ ] Ensure weather intensity is OFF (0.0)
- [ ] Change from Spring → Winter
- [ ] **Verify:** Weather stays OFF (does not auto-enable)
- [ ] Change from Summer → Winter
- [ ] **Verify:** Weather stays OFF

#### Test 7: Preference Persistence
- [ ] Set weather intensity to "Medium" (0.66)
- [ ] Close app
- [ ] Reopen app
- [ ] **Verify:** Weather intensity remains at "Medium"
- [ ] Change to "Off"
- [ ] Close app
- [ ] Reopen app
- [ ] **Verify:** Weather intensity remains at "Off"

---

## 🎨 VISUAL REGRESSION TESTING

### Layout & Rendering
- [ ] Weather renders BEHIND glass cards
- [ ] Weather renders ABOVE background gradient
- [ ] Glass card blur does NOT blur weather (correct z-index)
- [ ] Weather particles do NOT block user interactions
- [ ] Weather particles stay within viewport bounds
- [ ] No visual artifacts or glitches

### All 7 Screens Testing
Test on each screen to ensure weather works everywhere:

1. [ ] **Home Screen** - Weather renders correctly
2. [ ] **Settings Screen** - Weather renders correctly
3. [ ] **Collection Wizard Screen** - Weather renders correctly
4. [ ] **Profile Selection Screen** - Weather renders correctly
5. [ ] **Discover Cluster Screen** - Weather renders correctly
6. [ ] **Job History Screen** - Weather renders correctly
7. [ ] **Job Status Screen** - Weather renders correctly
8. [ ] **Artifacts Screen** - Weather renders correctly

---

## 🌐 CROSS-BROWSER TESTING

### Desktop Browsers
- [ ] **Chrome** (latest) - All weather effects work
- [ ] **Firefox** (latest) - All weather effects work
- [ ] **Safari** (latest) - All weather effects work
- [ ] **Edge** (latest) - All weather effects work

### Known Issues to Watch:
- Safari: Lottie animations may have slight performance differences
- Firefox: Backdrop blur may render slightly differently

---

## 📱 RESPONSIVE & MOBILE TESTING

### Viewport Sizes
- [ ] **Desktop (1920x1080)** - Weather scales correctly
- [ ] **Laptop (1366x768)** - Weather scales correctly
- [ ] **Tablet (768x1024)** - Weather scales correctly
- [ ] **Mobile (375x667)** - Weather scales correctly

### Mobile Browsers (if applicable)
- [ ] iOS Safari - Weather effects work
- [ ] Android Chrome - Weather effects work

---

## ⚡ PERFORMANCE BENCHMARKING

### Baseline Metrics (Before Sprint 1)
Record baseline for comparison:
- Bundle size: _____ KB
- Initial load time: _____ ms
- FPS with weather enabled: _____ fps
- Memory usage: _____ MB

### Sprint 1 Metrics (After Changes)
- [ ] Bundle size: _____ KB (Expected: -13KB from snow_effect removal)
- [ ] Initial load time: _____ ms (Expected: same or faster)
- [ ] FPS with weather enabled: _____ fps (Expected: 60 fps)
- [ ] Memory usage: _____ MB (Expected: same or lower)

### Performance Goals
- [ ] Bundle size reduced by at least 10KB
- [ ] 60 FPS maintained with weather effects
- [ ] No memory leaks detected
- [ ] Load time not degraded

---

## 🐛 ERROR HANDLING TESTING

### Error Scenarios
- [ ] Missing Lottie file → App shows nothing, no crash
- [ ] Corrupted Lottie JSON → Error builder catches, shows SizedBox.shrink
- [ ] Invalid season value → App handles gracefully
- [ ] Invalid intensity value → Clamped to 0.0-1.0 range

### Console Checks
- [ ] No errors in browser console
- [ ] No warnings about missing assets
- [ ] No errors about snow_effect.dart imports
- [ ] Debug messages (if any) are appropriate

---

## 🔒 REGRESSION TESTING

### Verify Nothing Broke

#### Background System
- [ ] Background presets still work
- [ ] Auto mode (time-of-day) still works
- [ ] Manual mode still works
- [ ] Season calculation still accurate
- [ ] Hemisphere setting still works
- [ ] Smooth transitions between presets work
- [ ] Debug panel controls work

#### Glass Card System
- [ ] Glass cards render correctly
- [ ] Blur effect works
- [ ] Reflections work
- [ ] Interactive lighting works (if applicable)
- [ ] Borders visible
- [ ] Content readable

#### Navigation & Routing
- [ ] All screens accessible
- [ ] Navigation doesn't break
- [ ] Back button works
- [ ] Deep links work (if applicable)

#### Data Persistence
- [ ] Settings persist correctly
- [ ] Weather preferences persist
- [ ] Background preferences persist
- [ ] API config persists

---

## ✅ ACCEPTANCE CRITERIA CHECKLIST

### FE-REFACTOR-1: Delete snow_effect.dart
- [x] File deleted from codebase
- [x] No imports reference snow_effect.dart
- [x] App builds successfully
- [x] No runtime errors

### FE-REFACTOR-2: Enable All Seasonal Weather
- [ ] Winter shows snow (weather_snow.json)
- [ ] Spring shows petals (weather_petals.json)
- [ ] Fall shows leaves (weather_leaves.json)
- [ ] Summer shows no weather (as designed)
- [ ] All intensity levels work (Off, Low, Medium, High)
- [ ] Time-of-day opacity modulation works
- [ ] Performance mode works
- [ ] Tab lifecycle (pause/resume) works

### FE-REFACTOR-3: Remove Auto-Enable
- [ ] Weather does NOT auto-enable on winter
- [ ] Weather starts at OFF by default
- [ ] User must manually enable weather
- [ ] Preferences persist correctly
- [ ] No unexpected weather activation

---

## 📊 QA SUMMARY TEMPLATE

```
Sprint 1 QA Report
=================

Date: _____________
Tester: _____________
Environment: _____________

PASSED: _____ / _____
FAILED: _____ / _____

Critical Issues: _____
Major Issues: _____
Minor Issues: _____

Recommendation: [ ] PASS  [ ] PASS WITH ISSUES  [ ] FAIL

Notes:
```

---

## 🎉 SUCCESS CRITERIA

Sprint 1 QA is COMPLETE when:
- ✅ All 3 seasonal weather effects work (winter, spring, fall)
- ✅ No auto-enable behavior detected
- ✅ No crashes or errors
- ✅ All 7 screens tested successfully
- ✅ Cross-browser testing passed
- ✅ Performance benchmarks met
- ✅ No regressions detected

---

## 🚀 NEXT STEPS

After QA passes:
1. Update documentation (FE-REFACTOR-5)
2. Create release notes
3. Demo to stakeholders
4. Begin Sprint 2 planning
