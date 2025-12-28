# Sprint Plan - App Refactoring & Optimization
**Total Duration:** 3 Sprints (6 weeks assuming 2-week sprints)
**Story Points:** 55 total

---

## 📊 SPRINT OVERVIEW

| Sprint | Focus | Story Points | Duration |
|--------|-------|--------------|----------|
| **Sprint 1** | Quick Wins & Dead Code Removal | 8 pts | 2 weeks |
| **Sprint 2** | Reduce Over-Engineering | 21 pts | 2 weeks |
| **Sprint 3** | Eliminate Repetition & Polish | 26 pts | 2 weeks |

---

# 🏃 SPRINT 1: Quick Wins & Dead Code Removal
**Goal:** Remove waste, enable prepared features
**Story Points:** 8
**Duration:** 2 weeks (but actual work ~1-2 days)

## Tickets

### FE-REFACTOR-1: Delete Dead Snow Effect Code
**Type:** Technical Debt
**Priority:** High
**Story Points:** 1

**Description:**
Remove unused `snow_effect.dart` file (424 lines) which contains a complex Canvas-based particle system that has been fully replaced by the Lottie-based weather system.

**Acceptance Criteria:**
- [ ] Delete `lib/src/ui/snow_effect.dart`
- [ ] Verify no imports reference this file
- [ ] Confirm app builds successfully
- [ ] Run smoke tests

**Impact:** Removes 3.4% of codebase (424 lines)

---

### FE-REFACTOR-2: Enable All Seasonal Lottie Weather Effects
**Type:** Feature Enhancement
**Priority:** High
**Story Points:** 2

**Description:**
Currently only winter (snow) Lottie animation is enabled. Enable spring (petals) and fall (leaves) animations which are already prepared and registered in pubspec.yaml.

**Technical Details:**
- File: `lib/src/ui/weather_effect.dart` line 87
- Change `_shouldShowWeather()` method to enable all seasons

**Acceptance Criteria:**
- [ ] Modify `_shouldShowWeather()` to return true for winter, spring, and fall
- [ ] Test winter season shows snow
- [ ] Test spring season shows petals
- [ ] Test fall season shows leaves
- [ ] Test summer season shows no weather (as designed)
- [ ] Verify performance mode still works
- [ ] Update debug panel if needed

**Impact:** Unlocks 3 prepared assets worth of seasonal ambiance

---

### FE-REFACTOR-3: Remove Auto-Enable Weather Logic
**Type:** Bug/UX Improvement
**Priority:** Medium
**Story Points:** 1

**Description:**
Remove auto-enable logic in `background_service.dart` that turns on snow without user consent when winter season is detected.

**Technical Details:**
- File: `lib/src/services/background_service.dart` lines 187-191
- Remove the conditional auto-enable in `_resolveAutoPreset()`

**Acceptance Criteria:**
- [ ] Remove auto-enable logic
- [ ] Weather effects remain off by default
- [ ] Users can manually enable via debug panel
- [ ] Verify saved preferences are respected
- [ ] Test session persistence

---

### FE-REFACTOR-4: QA & Regression Testing for Sprint 1
**Type:** QA
**Priority:** High
**Story Points:** 2

**Acceptance Criteria:**
- [ ] Full regression test on all 7 screens
- [ ] Test weather effects on all seasons
- [ ] Test performance mode
- [ ] Test debug panel controls
- [ ] Cross-browser testing (Chrome, Firefox, Safari)
- [ ] Mobile responsive testing
- [ ] Document any issues found

---

### FE-REFACTOR-5: Update Documentation
**Type:** Documentation
**Priority:** Medium
**Story Points:** 2

**Acceptance Criteria:**
- [ ] Update weather effects documentation
- [ ] Remove references to snow_effect.dart
- [ ] Document enabled seasonal effects
- [ ] Update QA guides if needed
- [ ] Add migration notes for developers

---

# 🏗️ SPRINT 2: Reduce Over-Engineering
**Goal:** Simplify complex components
**Story Points:** 21
**Duration:** 2 weeks

## Tickets

### FE-REFACTOR-6: Audit & Plan Glass Card Simplification
**Type:** Research/Planning
**Priority:** High
**Story Points:** 3

**Description:**
Analyze glass_card.dart (639 lines) and create detailed refactoring plan to reduce complexity while maintaining visual quality.

**Tasks:**
- [ ] Identify critical vs nice-to-have reflection layers
- [ ] Measure performance impact of each layer
- [ ] Create visual comparison tests
- [ ] Define acceptance criteria for "good enough" quality
- [ ] Create detailed refactoring sub-tickets

**Deliverable:** Technical design document with before/after comparisons

---

### FE-REFACTOR-7: Reduce Glass Card Reflection Layers
**Type:** Refactoring
**Priority:** High
**Story Points:** 8

**Description:**
Reduce glass card reflection system from 7+ layers to 3-4 essential layers while maintaining visual quality.

**Current Layers (7+):**
1. Primary radial sheen (light-position driven)
2. Top edge highlight
3. Left edge highlight
4. Right edge highlight
5. Secondary edge catchlight
6. Top-left corner caustic glow
7. Top-right corner caustic glow
8. Upper-left specular hotspot

**Proposed Simplified Layers (3-4):**
1. Primary radial sheen (keep - main glass effect)
2. Combined edge highlight (merge top/left/right)
3. Single corner glow (merge both corners)
4. (Optional) Minimal specular hotspot

**Acceptance Criteria:**
- [ ] Reduce to 3-4 reflection layers maximum
- [ ] Maintain visual quality at 80%+ of original
- [ ] Reduce glass_card.dart from 639 to ~400 lines
- [ ] No performance regression
- [ ] Side-by-side visual comparison approved
- [ ] Update all glass card documentation

**Dependencies:** FE-REFACTOR-6

---

### FE-REFACTOR-8: Extract Glass Card Debug Modes
**Type:** Refactoring
**Priority:** Medium
**Story Points:** 3

**Description:**
Extract debug modes (`debugShowFillProof`, `debugDisableBlur`, `debugExaggerateReflections`) from GlassCard into a separate debug wrapper component.

**Acceptance Criteria:**
- [ ] Create `DebugGlassCard` wrapper widget
- [ ] Move all debug logic to wrapper
- [ ] Clean up GlassCard to production-only code
- [ ] Update debug panel to use wrapper
- [ ] Verify debug modes still work
- [ ] Update documentation

---

### FE-REFACTOR-9: Evaluate Interactive Mouse Lighting
**Type:** Research/Decision
**Priority:** Low
**Story Points:** 2

**Description:**
Evaluate whether interactive mouse tracking for lighting is necessary or can be removed/simplified.

**Tasks:**
- [ ] Gather user feedback on interactive lighting
- [ ] Measure usage analytics (if available)
- [ ] Test with lighting disabled
- [ ] Make keep/remove decision
- [ ] Document decision rationale

**Outcome:** Decision document + optional removal ticket

---

### FE-REFACTOR-10: Simplify Noise Painter
**Type:** Refactoring
**Priority:** Low
**Story Points:** 2

**Description:**
Evaluate if custom noise painter adds sufficient value for its complexity. Consider removing or using simpler implementation.

**Acceptance Criteria:**
- [ ] A/B test with noise vs without
- [ ] Measure performance impact
- [ ] Make keep/remove/simplify decision
- [ ] Implement decision
- [ ] Update documentation

---

### FE-REFACTOR-11: QA & Performance Testing for Sprint 2
**Type:** QA
**Priority:** High
**Story Points:** 3

**Acceptance Criteria:**
- [ ] Visual regression testing (before/after screenshots)
- [ ] Performance benchmarking (FPS, render time)
- [ ] Cross-browser testing
- [ ] Mobile testing
- [ ] Accessibility testing
- [ ] Document performance improvements

---

# 🔧 SPRINT 3: Eliminate Repetition & Polish
**Goal:** Reduce code duplication, improve maintainability
**Story Points:** 26
**Duration:** 2 weeks

## Tickets

### FE-REFACTOR-12: Create PersistedService Base Class
**Type:** Refactoring
**Priority:** High
**Story Points:** 5

**Description:**
Extract common service pattern into abstract base class to reduce duplication across ConfigService, BackgroundService, and future services.

**Acceptance Criteria:**
- [ ] Create `PersistedService` abstract base class
- [ ] Implement common initialization pattern
- [ ] Implement common load/save pattern
- [ ] Implement common error handling
- [ ] Refactor ConfigService to extend base class
- [ ] Refactor BackgroundService to extend base class
- [ ] No behavior changes (regression test)
- [ ] Update service documentation

---

### FE-REFACTOR-13: Create GlassScaffold Reusable Widget
**Type:** Refactoring
**Priority:** High
**Story Points:** 5

**Description:**
Extract common screen scaffold pattern (Stack → BackgroundRenderer → WeatherEffect → SafeArea → GlassCard) into reusable widget to eliminate duplication across 7 screens.

**Acceptance Criteria:**
- [ ] Create `GlassScaffold` widget
- [ ] Support customizable maxWidth
- [ ] Support optional appBar
- [ ] Integrate with BackgroundService
- [ ] Refactor collection_wizard_screen to use GlassScaffold
- [ ] Refactor other screens (6 more)
- [ ] Verify all screens work identically
- [ ] Update screen documentation

---

### FE-REFACTOR-14: Refactor Large Collection Wizard Screen
**Type:** Refactoring
**Priority:** Medium
**Story Points:** 8

**Description:**
Break down collection_wizard_screen.dart (3,065 lines) into smaller, more manageable components.

**Proposed Structure:**
- Main wizard orchestrator (200-300 lines)
- Step 1: Profile selection widget
- Step 2: Cluster discovery widget
- Step 3: Node selection widget
- Step 4: Artifact selection widget
- Step 5: Summary widget

**Acceptance Criteria:**
- [ ] Create separate widget files for each step
- [ ] Reduce main file to <500 lines
- [ ] Extract shared step logic
- [ ] No behavior changes
- [ ] Improved testability
- [ ] Update documentation

---

### FE-REFACTOR-15: Clean Up Feature ID Comments
**Type:** Code Cleanup
**Priority:** Low
**Story Points:** 3

**Description:**
Reduce excessive inline feature ID comments (100+ throughout codebase) to improve code readability while maintaining traceability.

**Approach:**
- Keep feature IDs in commit messages
- Keep feature IDs in documentation
- Remove most inline comments
- Keep only critical architectural notes in code

**Acceptance Criteria:**
- [ ] Audit all feature ID comments
- [ ] Remove 70%+ of inline feature IDs
- [ ] Keep critical architectural comments
- [ ] Update CONTRIBUTING.md with new convention
- [ ] Ensure traceability maintained via git history

---

### FE-REFACTOR-16: Evaluate Background Preset System Complexity
**Type:** Research/Decision
**Priority:** Low
**Story Points:** 2

**Description:**
Evaluate if background preset system (854 lines across 3 files) matches product requirements or is over-engineered.

**Questions to Answer:**
- Do we need auto-updating backgrounds based on time-of-day?
- Do we need hemisphere-aware seasons?
- Do we need smooth crossfade transitions?
- Could we use simpler static preset selector?

**Deliverable:** Decision document with keep/simplify recommendation

---

### FE-REFACTOR-17: Final QA & Performance Testing
**Type:** QA
**Priority:** High
**Story Points:** 3

**Acceptance Criteria:**
- [ ] Full end-to-end regression testing
- [ ] Performance benchmarking vs Sprint 1 baseline
- [ ] Bundle size analysis (before/after)
- [ ] Code coverage report
- [ ] Cross-browser final testing
- [ ] Mobile final testing
- [ ] Accessibility audit
- [ ] Security scan

---

# 📈 SUCCESS METRICS

## Code Quality Metrics
- **Lines of Code Reduction:** Target 800-1000 lines (6-8%)
- **File Count Reduction:** Target -1 file minimum
- **Cyclomatic Complexity:** Reduce by 20% in refactored files
- **Code Duplication:** Reduce by 30%

## Performance Metrics
- **Build Time:** Maintain or improve
- **Bundle Size:** Reduce by 5-10%
- **Runtime Performance:** Maintain 60 FPS
- **Initial Load Time:** Maintain or improve

## Developer Experience Metrics
- **Time to Onboard New Developer:** Reduce by 20%
- **Time to Add New Screen:** Reduce by 30% (via GlassScaffold)
- **Test Coverage:** Maintain or improve

---

# 🎯 DELIVERABLES BY SPRINT

## Sprint 1 Deliverables
- ✅ snow_effect.dart deleted
- ✅ All seasonal Lottie weather enabled
- ✅ Auto-enable logic removed
- ✅ Updated documentation
- ✅ QA report

## Sprint 2 Deliverables
- ✅ Glass card simplified (639 → ~400 lines)
- ✅ Debug modes extracted
- ✅ Performance report
- ✅ Visual regression test suite
- ✅ Updated design documentation

## Sprint 3 Deliverables
- ✅ PersistedService base class
- ✅ GlassScaffold widget
- ✅ Collection wizard refactored
- ✅ Clean codebase (reduced feature ID noise)
- ✅ Final QA & performance report
- ✅ Updated developer documentation

---

# 🚀 GETTING STARTED

**Sprint 1 can start immediately** with tickets:
1. FE-REFACTOR-1 (Delete snow_effect.dart) - 1 SP
2. FE-REFACTOR-2 (Enable all Lottie weather) - 2 SP

These are ~1-2 hours of work and unlock immediate value.
