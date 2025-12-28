# Production QA Test Plan
**Ticket:** FE-UI-PROD-6
**Type:** QA Testing
**Date:** 2025-12-28
**Sprint:** Sprint 4 - Production UI Cleanup
**Version:** 1.4.0

---

## 📋 Overview

Comprehensive test plan for verifying production build quality before deployment. Covers functionality, visual quality, performance, and cross-browser compatibility.

**Test Environment:**
- **Debug Build:** `flutter run -d chrome`
- **Production Build:** `flutter build web --release --web-renderer canvaskit`
- **Local Server:** `python3 -m http.server 8000` (from build/web/)

---

## 🧪 Test Scenarios

### 1. Debug Mode Verification ✅

**Build Command:**
```bash
flutter run -d chrome
```

**Expected Behavior:** All debug tools accessible

#### Test Cases:

**TC-1.1: Debug Menu Accessible**
- [ ] AppBar shows developer_mode icon (gear icon)
- [ ] Clicking icon opens debug menu modal
- [ ] Modal has dark background with rounded corners
- [ ] "Debug Tools" header visible
- [ ] Close button (X) works

**TC-1.2: Glass QA Tools Section**
- [ ] "Glass QA Tools" section header visible
- [ ] Fill Proof toggle present (hot pink color indicator)
- [ ] Test Pattern toggle present (orange color indicator)
- [ ] Glass Stage toggle present (purple color indicator)
- [ ] Disable Blur toggle present (amber color indicator)
- [ ] All toggles work (state changes on click)
- [ ] Active toggles show colored border/background

**TC-1.3: Background Tools Section**
- [ ] "Background Tools" section header visible
- [ ] Environment Plate toggle present (green color indicator)
- [ ] Background Debug Panel toggle present (blue color indicator)
- [ ] Both toggles work correctly

**TC-1.4: Glass QA Features Work**
- [ ] Fill Proof ON: Card fills show hot pink (proves transparency)
- [ ] Test Pattern ON: Grid pattern appears behind cards
- [ ] Glass Stage ON: Hard-edge bands visible for refraction testing
- [ ] Disable Blur ON: Glass cards show no blur effect
- [ ] Environment Plate OFF: Background becomes black

**TC-1.5: Background Debug Panel**
- [ ] Toggle "Background Debug Panel" ON
- [ ] Panel appears at top-right of screen
- [ ] Panel shows:
  - Preset selector dropdown
  - Time-of-day indicator
  - Season indicator
  - Weather controls (intensity, enable/disable)
  - Performance mode toggle
- [ ] All controls functional

**TC-1.6: Renderer Badge**
- [ ] Badge visible at bottom-left corner
- [ ] Shows "Renderer: CanvasKit"
- [ ] Badge has dark background with white text
- [ ] Web icon visible in badge

**Expected Result:** ✅ All debug features accessible and functional

---

### 2. Production Mode Verification ✅

**Build Command:**
```bash
flutter clean
flutter pub get
flutter build web --release --web-renderer canvaskit
cd build/web
python3 -m http.server 8000
# Open http://localhost:8000
```

**Expected Behavior:** Clean UI, no debug elements

#### Test Cases:

**TC-2.1: No Debug UI Elements**
- [ ] ❌ No developer_mode icon in AppBar
- [ ] ❌ No debug menu accessible
- [ ] ❌ No "Background Debug Panel" visible
- [ ] ❌ No renderer badge at bottom-left
- [ ] ✅ Only "Reset Wizard" icon visible in AppBar
- [ ] ✅ AppBar looks clean and professional

**TC-2.2: Console Verification**
- [ ] Open browser DevTools (F12)
- [ ] Check Console tab
- [ ] ❌ No red errors
- [ ] ❌ No yellow warnings (or only expected framework warnings)
- [ ] ❌ No "kDebugMode" references in console
- [ ] ✅ Clean console output

**TC-2.3: Network Tab Verification**
- [ ] Open DevTools Network tab
- [ ] Reload page
- [ ] Verify all assets load successfully:
  - [ ] main.dart.js (200 OK)
  - [ ] canvaskit.js (200 OK)
  - [ ] canvaskit.wasm (200 OK)
  - [ ] weather_snow.json (200 OK)
  - [ ] weather_petals.json (200 OK)
  - [ ] weather_leaves.json (200 OK)
- [ ] No 404 errors
- [ ] No failed requests

**TC-2.4: Bundle Size Check**
- [ ] Check total bundle size in Network tab
- [ ] Expected range: 2-5 MB
- [ ] main.dart.js should be minified (no readable code)
- [ ] canvaskit.wasm size: ~2-3 MB

**Expected Result:** ✅ Clean production UI, no debug elements, no console errors

---

### 3. Visual Quality Verification ✅

**Build:** Production (`flutter build web --release`)

#### Test Cases:

**TC-3.1: Glass Card Rendering**
- [ ] Glass cards have transparent center
- [ ] Blur effect visible (environment refracts through card)
- [ ] Rim borders visible and crisp (dual-stroke)
- [ ] Specular highlights visible
- [ ] Inner shadow creates depth
- [ ] No "grey fog" appearance
- [ ] Cards look premium and liquid-like

**TC-3.2: Background System**
- [ ] Background gradients render smoothly
- [ ] No banding artifacts
- [ ] Transitions are smooth (if auto-updating enabled)
- [ ] Colors look rich and vibrant

**TC-3.3: Weather Effects**
- [ ] Weather animations play smoothly (60fps target)
- [ ] Lottie animations load correctly:
  - [ ] Snow particles (winter)
  - [ ] Flower petals (spring)
  - [ ] Falling leaves (fall)
- [ ] No stuttering or lag
- [ ] Particles layer correctly over background

**TC-3.4: Interactive Lighting**
- [ ] Move mouse over glass cards
- [ ] Specular highlight follows mouse position
- [ ] Highlight is subtle and smooth
- [ ] No jank or lag in mouse tracking

**TC-3.5: Typography & Colors**
- [ ] All text is readable
- [ ] Text colors have good contrast
- [ ] Primary text: ~92% white (light grey)
- [ ] Secondary text: ~70% white (medium grey)
- [ ] No pure white text (too harsh)

**Expected Result:** ✅ Premium visual quality, smooth animations, no artifacts

---

### 4. Functionality Testing ✅

**Build:** Production

#### Test Cases:

**TC-4.1: Collection Wizard - Step 1 (API Config)**
- [ ] Form loads correctly
- [ ] Base URL input field works
- [ ] API Key input field works
- [ ] "Test Connection" button present
- [ ] Form validation works:
  - [ ] Empty URL shows error
  - [ ] Invalid URL format shows error
  - [ ] Valid URL removes error
- [ ] "Save & Continue" enables when valid
- [ ] Clicking "Save & Continue" advances to next step

**TC-4.2: Collection Wizard - Step 2 (Cluster Discovery)**
- [ ] Step 2 unlocks after Step 1 completion
- [ ] Form renders correctly
- [ ] "Discover Clusters" button works
- [ ] List of clusters appears (if API configured)
- [ ] Cluster selection works
- [ ] "Continue" button enables when cluster selected

**TC-4.3: Collection Wizard - Step 3 (Node Selection)**
- [ ] Step 3 unlocks after Step 2 completion
- [ ] Node list displays
- [ ] Node selection checkboxes work
- [ ] "Select All" / "Deselect All" work
- [ ] "Continue" enables when nodes selected

**TC-4.4: Collection Wizard - Step 4 (Collection Config)**
- [ ] Step 4 unlocks correctly
- [ ] Collection name input works
- [ ] Collection type dropdown works
- [ ] Advanced options toggle works
- [ ] Form validation works
- [ ] "Continue" enables when valid

**TC-4.5: Collection Wizard - Step 5 (Job Submission)**
- [ ] Step 5 unlocks correctly
- [ ] Job summary displays
- [ ] "Submit Job" button works
- [ ] Success/error messages display correctly

**TC-4.6: Reset Wizard**
- [ ] "Reset Wizard" icon (refresh) in AppBar
- [ ] Clicking shows confirmation dialog
- [ ] Dialog has "Cancel" and "Reset" buttons
- [ ] "Cancel" closes dialog, no changes
- [ ] "Reset" returns wizard to Step 1
- [ ] All form data cleared

**TC-4.7: Navigation & Scrolling**
- [ ] Page scrolls smoothly
- [ ] Auto-scroll to active step works
- [ ] Expanding/collapsing steps works
- [ ] Locked steps cannot be expanded
- [ ] Completed steps show checkmark icon

**Expected Result:** ✅ All wizard features work end-to-end

---

### 5. Performance Testing ✅

**Build:** Production
**Tool:** Browser DevTools Performance tab

#### Test Cases:

**TC-5.1: Page Load Performance**
- [ ] Open DevTools Performance tab
- [ ] Reload page (Ctrl+Shift+R)
- [ ] Stop recording after full load
- [ ] Metrics:
  - [ ] First Contentful Paint (FCP): < 1.5s ✅
  - [ ] Largest Contentful Paint (LCP): < 2.5s ✅
  - [ ] Total page load: < 3s ✅
  - [ ] Time to Interactive (TTI): < 3.5s ✅

**TC-5.2: Animation Performance**
- [ ] Record performance while hovering over glass cards
- [ ] Check FPS (Frames Per Second):
  - [ ] Target: 60 FPS ✅
  - [ ] Acceptable: 55+ FPS ⚠️
  - [ ] Poor: < 50 FPS ❌
- [ ] No dropped frames during mouse movement
- [ ] Smooth specular highlight movement

**TC-5.3: Weather Animation Performance**
- [ ] Record performance with weather effects enabled
- [ ] Check FPS:
  - [ ] Snow: 55+ FPS ✅
  - [ ] Petals: 55+ FPS ✅
  - [ ] Leaves: 55+ FPS ✅
- [ ] No stuttering or jank
- [ ] CPU usage reasonable (< 50%)

**TC-5.4: Memory Usage**
- [ ] Open DevTools Memory tab
- [ ] Take initial snapshot
- [ ] Use app for 2 minutes (navigate, interact)
- [ ] Take second snapshot
- [ ] Check for memory leaks:
  - [ ] Memory increase < 20 MB ✅
  - [ ] No continuous growth ✅
  - [ ] No detached DOM nodes ✅

**TC-5.5: Bundle Size Analysis**
- [ ] Total initial load: < 5 MB ✅
- [ ] main.dart.js: < 2 MB (minified) ✅
- [ ] canvaskit.wasm: ~2-3 MB ✅
- [ ] Lottie files: < 500 KB total ✅

**Expected Result:** ✅ Fast load times, smooth 60fps animations, no memory leaks

---

### 6. Cross-Browser Compatibility ✅

**Build:** Production (same build for all browsers)

#### Browsers to Test:

**TC-6.1: Chrome/Chromium (Primary)**
- **Version:** Latest stable (120+)
- [ ] All features work
- [ ] Glass effects render correctly
- [ ] Blur effects work
- [ ] Weather animations smooth
- [ ] No console errors
- [ ] Performance: 60fps ✅

**TC-6.2: Microsoft Edge (Chromium)**
- **Version:** Latest stable (120+)
- [ ] All features work
- [ ] Visual quality matches Chrome
- [ ] No Edge-specific issues
- [ ] Performance: 60fps ✅

**TC-6.3: Firefox**
- **Version:** Latest stable (120+)
- [ ] All features work
- [ ] Glass blur effects work (may differ slightly)
- [ ] Weather animations smooth
- [ ] Form controls work correctly
- [ ] Performance: 55+ fps ⚠️ (Firefox can be slower)
- [ ] Check for Firefox-specific console warnings

**TC-6.4: Safari (macOS/iOS)**
- **Version:** Latest stable (17+)
- [ ] All features work
- [ ] Backdrop blur support verified
- [ ] Glass effects render correctly
- [ ] Weather animations work
- [ ] Touch events work (iOS)
- [ ] Performance: 55+ fps ⚠️
- [ ] No Safari-specific errors

**TC-6.5: Mobile Chrome (Android)**
- **Version:** Latest stable
- [ ] App loads on mobile viewport
- [ ] Responsive layout works
- [ ] Touch interactions work
- [ ] Glass effects render (may be simplified)
- [ ] Performance acceptable on mid-range device

**TC-6.6: Mobile Safari (iOS)**
- **Version:** Latest stable
- [ ] App loads correctly
- [ ] Touch interactions work
- [ ] Responsive layout works
- [ ] Performance acceptable

**Expected Result:** ✅ Works on all major browsers with acceptable quality

---

### 7. Responsive Design Testing ✅

**Build:** Production
**Tool:** Browser DevTools Device Emulation

#### Test Cases:

**TC-7.1: Mobile (375px width)**
- [ ] Viewport: iPhone 12 Pro (390x844)
- [ ] Layout adapts to mobile
- [ ] Cards stack vertically
- [ ] Text is readable (no truncation)
- [ ] Buttons are tap-able (min 44x44px)
- [ ] No horizontal scroll
- [ ] Forms fit on screen

**TC-7.2: Tablet (768px width)**
- [ ] Viewport: iPad (768x1024)
- [ ] Layout adapts to tablet
- [ ] Card width appropriate
- [ ] Two-column layout if applicable
- [ ] Touch targets adequate
- [ ] No layout breaking

**TC-7.3: Desktop (1024px width)**
- [ ] Viewport: 1024x768
- [ ] Card centered with max width
- [ ] Background fills viewport
- [ ] Content readable
- [ ] No wasted space

**TC-7.4: Large Desktop (1920px width)**
- [ ] Viewport: 1920x1080
- [ ] Content max width enforced (1200px)
- [ ] Content centered
- [ ] Background fills entire screen
- [ ] No layout issues

**TC-7.5: Zoom Levels**
- [ ] Zoom 50%: Layout intact
- [ ] Zoom 100%: Normal
- [ ] Zoom 150%: Layout still works
- [ ] Zoom 200%: Text readable, no breaking

**Expected Result:** ✅ Responsive across all screen sizes

---

## ✅ Acceptance Criteria Checklist

### Debug Mode
- [ ] Debug menu accessible ✅
- [ ] All Glass QA tools work ✅
- [ ] Background debug panel works ✅
- [ ] Renderer badge visible ✅
- [ ] Fill proof test passes ✅
- [ ] Test pattern works ✅
- [ ] Glass stage works ✅
- [ ] Blur toggle works ✅

### Production Mode
- [ ] ❌ No debug icon in AppBar ✅
- [ ] ❌ No debug menu ✅
- [ ] ❌ No background debug panel ✅
- [ ] ❌ No renderer badge ✅
- [ ] ✅ Only reset wizard icon ✅
- [ ] Clean console (no errors) ✅
- [ ] All assets load (200 OK) ✅
- [ ] Bundle size < 5 MB ✅

### Visual Quality
- [ ] Glass effects look premium ✅
- [ ] Blur refracts background ✅
- [ ] No grey fog appearance ✅
- [ ] Weather animations smooth ✅
- [ ] Specular highlights work ✅
- [ ] Colors look rich ✅
- [ ] Typography readable ✅

### Functionality
- [ ] Collection wizard works end-to-end ✅
- [ ] All 5 steps functional ✅
- [ ] Form validation works ✅
- [ ] Navigation works ✅
- [ ] Reset wizard works ✅
- [ ] Auto-scroll works ✅

### Performance
- [ ] Page load < 3s ✅
- [ ] Animations 55+ fps ✅
- [ ] No memory leaks ✅
- [ ] CPU usage reasonable ✅

### Cross-Browser
- [ ] Chrome/Edge: All features work ✅
- [ ] Firefox: All features work ✅
- [ ] Safari: All features work ✅
- [ ] Mobile: Responsive & functional ✅

### Responsive
- [ ] Mobile (375px): Works ✅
- [ ] Tablet (768px): Works ✅
- [ ] Desktop (1024px): Works ✅
- [ ] Large (1920px): Works ✅

---

## 🐛 Issue Tracking

### Known Issues
None identified during Sprint 4 development.

### Issue Template
If issues found during QA, document using this format:

```
**Issue ID:** QA-001
**Severity:** Critical / High / Medium / Low
**Browser:** Chrome 120 / Firefox 120 / Safari 17 / etc.
**Build:** Debug / Production
**Steps to Reproduce:**
1. Step 1
2. Step 2
3. Step 3

**Expected Result:**
[What should happen]

**Actual Result:**
[What actually happened]

**Screenshot:**
[Attach if applicable]

**Console Errors:**
[Paste console output]

**Fix Priority:** Blocker / High / Medium / Low
```

---

## 📊 Test Results Summary

**Test Execution Date:** _____________

### Overall Status: ✅ / ⚠️ / ❌

| Test Area | Status | Pass Rate | Notes |
|-----------|--------|-----------|-------|
| Debug Mode Verification | ☐ | ___/6 | |
| Production Mode Verification | ☐ | ___/4 | |
| Visual Quality | ☐ | ___/5 | |
| Functionality | ☐ | ___/7 | |
| Performance | ☐ | ___/5 | |
| Cross-Browser | ☐ | ___/6 | |
| Responsive Design | ☐ | ___/5 | |

**Total:** ___/38 tests passed

### Pass Criteria:
- **Ship-Ready:** 36+/38 tests passed (95%+) ✅
- **Acceptable:** 34+/38 tests passed (90%+) ⚠️
- **Needs Work:** < 34/38 tests passed (< 90%) ❌

---

## 🚀 Deployment Readiness

### Pre-Deployment Checklist
- [ ] All critical tests passed
- [ ] No blocker or high severity issues
- [ ] Production build tested locally
- [ ] Cross-browser compatibility verified
- [ ] Performance benchmarks met
- [ ] Visual quality approved
- [ ] Stakeholder sign-off received

### Sign-Off

**QA Engineer:**
- Name: _______________
- Date: _______________
- Signature: _______________

**Developer:**
- Name: _______________
- Date: _______________
- Signature: _______________

**Product Owner:**
- Name: _______________
- Date: _______________
- Signature: _______________

---

## 📝 Notes & Comments

[Add any additional notes, observations, or recommendations here]

---

**Status:** ✅ Test Plan Complete
**Next Steps:** Execute tests and document results
**Reference:** See PRODUCTION_BUILD_GUIDE.md for build instructions
**Reference:** See DEPLOYMENT_CHECKLIST.md for deployment procedures
