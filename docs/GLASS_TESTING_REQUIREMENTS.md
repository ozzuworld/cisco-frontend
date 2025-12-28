# FE-UI-114: Glass Effect Testing Requirements

## Overview
This document establishes mandatory testing requirements for glass effect development. Every completed ticket must include proof of testing via command output and screenshots.

---

## ⚠️ HARD REQUIREMENT: Ticket Not Done Without Proof

A ticket is **NOT COMPLETE** unless it includes:

1. ✅ Terminal output for required commands
2. ✅ Screenshots from the Glass QA Harness (FE-UI-112)
3. ✅ Validation checklist results

**No exceptions.** This prevents "looks good to me" commits without actual testing.

---

## Required Commands (Mandatory for Every Ticket)

### 1. Static Analysis
```bash
flutter analyze
```

**Required output:**
- No analysis issues found, OR
- Justification for each warning/error

**Example:**
```
Analyzing cisco-frontend...
No issues found!
```

---

### 2. Tests (If Present)
```bash
flutter test
```

**Required output:**
- All tests passing, OR
- Explanation for any failures and plan to fix

**Example:**
```
00:03 +24: All tests passed!
```

---

### 3. Build/Run Verification

**For web renderer validation:**
```bash
flutter run -d chrome --web-renderer html
# OR
flutter run -d chrome --web-renderer canvaskit
```

**For production builds:**
```bash
flutter build web --release --web-renderer <target>
```

**Required output:**
- Build completes successfully
- No runtime errors on startup
- Glass effect renders correctly

**Example:**
```
Building web...
Built build/web
```

---

## Glass Effect Validation Checklist

For **every** glass effect change, verify ALL of the following:

### Visual Tests (Use Glass QA Harness - FE-UI-112)

- [ ] **Zero Fill Test:** Toggle "Fill Proof" - card should NEVER show pink
- [ ] **Environment A/B Test:** Toggle "Environment Plate" - clear difference between ON (liquid glass) and OFF (grey fog)
- [ ] **Blur Toggle Test:** Toggle "Blur" - environment visible when OFF, refracted when ON
- [ ] **Glass Stage Test:** Toggle "Glass Stage" - hard-edge bands clearly visible and intersect card
- [ ] **Reflection Test:** Card shows specular highlights (sheen, catchlights, corner glows) even with blur OFF
- [ ] **Thin Sheet Test:** No dark banding inside card at 100% zoom - reads like thin glass, not thick panel

### Refraction Quality Tests

- [ ] **Band Refraction:** At least 2 diagonal bands visibly warp/distort through blurred glass
- [ ] **Bloom Refraction:** At least 1 bloom visibly distorts (not just fades)
- [ ] **Sharp Edge Test:** Hard-edge elements maintain recognizable shape when blurred (warped but not completely smeared)

### Cross-Browser Tests (Spot Check)

- [ ] Chrome 120+ (primary target)
- [ ] Safari 16+ (macOS/iOS - if available)
- [ ] Firefox 115+ (limited backdrop-filter support)

### Zoom Level Tests

- [ ] 100% zoom - all effects render correctly
- [ ] 125% zoom - no degradation, reflections still visible
- [ ] 150% zoom (optional) - document if effects degrade

---

## Screenshot Requirements

### Naming Convention
```
screenshots/FE-UI-XXX_<description>_<renderer>_<zoom>.png
```

**Examples:**
- `screenshots/FE-UI-109_glass-stage-on_html_100.png`
- `screenshots/FE-UI-110_reflections-exaggerated_canvaskit_125.png`

### Required Screenshot Set (Per Ticket)

1. **Normal state** - All effects ON, default settings
2. **Blur OFF** - Environment visible, no refraction
3. **Environment OFF** - Proves grey fog failure mode
4. **Debug mode** - Fill proof, test pattern, or exaggerated mode (if applicable)

**Minimum: 4 screenshots per ticket**

---

## Example Ticket Completion Checklist

```markdown
## FE-UI-XXX: [Ticket Title]

### Testing Evidence

#### 1. Static Analysis
```bash
flutter analyze
```
Output:
```
Analyzing cisco-frontend...
No issues found!
```

#### 2. Tests
```bash
flutter test
```
Output:
```
00:03 +24: All tests passed!
```

#### 3. Runtime Verification
```bash
flutter run -d chrome --web-renderer html
```
Output:
```
Launching lib/main.dart on Chrome in debug mode...
✓ Built build/web
```

### Visual Validation Checklist
- [x] Zero Fill Test - PASS
- [x] Environment A/B Test - PASS (clear difference)
- [x] Blur Toggle Test - PASS (refraction visible)
- [x] Glass Stage Test - PASS (2 bands intersect card)
- [x] Reflection Test - PASS (5 distinct highlights)
- [x] Thin Sheet Test - PASS (no dark banding)
- [x] Band Refraction - PASS (diagonal bands warp)
- [x] Bloom Refraction - PASS (top bloom distorts)
- [x] Chrome 120 - PASS
- [x] 100% zoom - PASS
- [x] 125% zoom - PASS

### Screenshots
- `screenshots/FE-UI-XXX_normal_html_100.png`
- `screenshots/FE-UI-XXX_blur-off_html_100.png`
- `screenshots/FE-UI-XXX_env-off_html_100.png`
- `screenshots/FE-UI-XXX_debug_html_125.png`

### Notes
[Any additional observations, known issues, or follow-up tasks]
```

---

## Enforcement

### Code Review Checklist
Reviewers **MUST** verify:
- [ ] All required commands executed with output provided
- [ ] Screenshots present and properly named
- [ ] Validation checklist completed
- [ ] No "trust me, it works" claims without evidence

### Auto-Rejection Criteria
Reject PR immediately if:
- Missing command output
- Missing screenshots
- Incomplete validation checklist
- Claims not backed by evidence

---

## Tools & Setup

### Glass QA Harness (FE-UI-112)
Route: `/glass_lab`

**Features:**
- Background selector (flat, stage, photo, checkerboard)
- Toggles: blur, reflections, rims, glass stage
- Sliders: blur sigma, reflection intensity, rim opacity
- Screenshot export with auto-naming

**Usage:**
```bash
flutter run -d chrome
# Navigate to /glass_lab
# Test configurations
# Export screenshots
```

---

## FAQ

**Q: What if I can't run Flutter locally?**
**A:** Use Flutter Web online tools or request a teammate to run tests. No exceptions - proof is mandatory.

**Q: What if tests fail?**
**A:** Document the failure, explain why it's acceptable (if it is), or fix before marking ticket complete.

**Q: Can I skip screenshots for "small" changes?**
**A:** No. Even small changes can have unexpected visual effects. Screenshots are mandatory.

**Q: How do I know if refraction is "good enough"?**
**A:** Use the Glass Stage toggle (FE-UI-109). If disabling it makes the card go from "liquid" to "grey fog", refraction is working.

---

## Version History

- **2025-12-28:** FE-UI-114 - Initial documentation
- Purpose: Stop auto-commit lies, require proof of testing

---

## Related Documentation

- [Web Renderer Validation](./WEB_RENDERER_VALIDATION.md) - FE-UI-103
- Glass QA Harness - FE-UI-112 (implementation in progress)
- Design Tokens - `/lib/src/ui/design_tokens.dart`
