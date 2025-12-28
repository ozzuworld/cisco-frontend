# FE-UI-112: Glass QA Harness (One Screen, No App Noise)

## Status
**PLANNED** - Implementation guide for dedicated glass testing screen

---

## Goal
Build a dedicated test screen that isolates the glass effect from wizard UI complexity. Enables rapid iteration and A/B testing without navigating the full app.

---

## Problem Statement

Currently testing glass effects requires:
1. Navigating to Collection Wizard
2. Dealing with form inputs, steps, state
3. Toggling debug buttons in AppBar
4. No way to adjust parameters in real-time

**We need:**
- Isolated glass card test environment
- Live parameter adjustments (sliders)
- Multiple background presets
- One-click screenshot export
- Reproduce "good liquid" vs "fog" in <10 seconds

---

## Implementation Plan

### Route Setup

**Location:** `/lib/main.dart` or `/lib/src/app.dart`

```dart
routes: {
  '/': (context) => const CollectionWizardScreen(),
  '/settings': (context) => const SettingsScreen(),
  '/glass_lab': (context) => const GlassQAHarnessScreen(), // FE-UI-112
},
```

**Access:** Navigate to `/#/glass_lab` in browser

---

## Screen Layout

```
┌─────────────────────────────────────────────────────┐
│  Glass QA Harness                           [Export]│ AppBar
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌─────────────────────────────────────────┐       │
│  │                                         │       │
│  │         GLASS CARD PREVIEW              │       │
│  │                                         │  70%  │
│  │  (Live glass card with current params)  │       │
│  │                                         │       │
│  │                                         │       │
│  └─────────────────────────────────────────┘       │
│                                                     │
├─────────────────────────────────────────────────────┤
│  Controls Panel                                     │  30%
│  ┌───────────────────────────────────────────────┐ │
│  │ Background:  [Flat][Stage][Photo][Checkerboard]│
│  │ Toggles:     [Blur] [Reflections] [Rims]      │ │
│  │              [Glass Stage] [Fill Proof]       │ │
│  │                                               │ │
│  │ Blur Sigma:      [═══════○═] 5.0             │ │
│  │ Reflection Int:  [═══○═════] 0.12             │ │
│  │ Rim Opacity:     [═════○═══] 0.40             │ │
│  │ Sheen Opacity:   [════○════] 0.12             │ │
│  │                                               │ │
│  │ [Export Screenshot] [Reset to Defaults]       │ │
│  └───────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

---

## Features

### 1. Background Selector

**Options:**
- **Flat:** Solid black (#05060A) - proves grey fog failure
- **Stage:** Glass stage layer (FE-UI-109 bands + blooms)
- **Photo:** Test photo with high-contrast patterns
- **Checkerboard:** Black/white alternating squares (refraction proof)

**Implementation:**
```dart
enum BackgroundType { flat, stage, photo, checkerboard }

BackgroundType _selectedBackground = BackgroundType.stage;

Widget _buildBackground() {
  switch (_selectedBackground) {
    case BackgroundType.flat:
      return Container(color: DesignTokens.backgroundBase);
    case BackgroundType.stage:
      return _buildGlassStageBackground();
    case BackgroundType.photo:
      return Image.asset('assets/test_photo.jpg', fit: BoxFit.cover);
    case BackgroundType.checkerboard:
      return CustomPaint(painter: _CheckerboardPainter());
  }
}
```

---

### 2. Toggles (On/Off Switches)

**Toggles:**
- **Blur:** Enable/disable `BackdropFilter`
- **Reflections:** Show/hide FE-UI-110 reflection system
- **Rims:** Show/hide dual-stroke rim borders
- **Glass Stage:** Show/hide FE-UI-109 hard-edge bands
- **Fill Proof:** Hot pink overlay if fill > 0%

**Implementation:**
```dart
bool _blurEnabled = true;
bool _reflectionsEnabled = true;
bool _rimsEnabled = true;
bool _glassStageEnabled = true;
bool _fillProofEnabled = false;

// Pass to GlassCard
GlassCard(
  debugDisableBlur: !_blurEnabled,
  debugShowFillProof: _fillProofEnabled,
  // ... other params
)
```

---

### 3. Parameter Sliders

**Sliders:**
1. **Blur Sigma** (0.0 - 20.0, default: 5.0)
2. **Reflection Intensity** (0.0 - 1.0, default: 0.12)
3. **Rim Opacity** (0.0 - 1.0, default: 0.40)
4. **Sheen Opacity** (0.0 - 1.0, default: 0.12)

**Implementation:**
```dart
double _blurSigma = 5.0;
double _reflectionIntensity = 0.12;
double _rimOpacity = 0.40;
double _sheenOpacity = 0.12;

Slider(
  value: _blurSigma,
  min: 0.0,
  max: 20.0,
  divisions: 40,
  label: _blurSigma.toStringAsFixed(1),
  onChanged: (value) {
    setState(() => _blurSigma = value);
  },
)
```

**Apply to GlassCard:**
```dart
GlassCard(
  blurStrength: _blurSigma,
  borderOpacity: _rimOpacity,
  // Custom reflection intensity (requires GlassCard enhancement)
)
```

---

### 4. Screenshot Export

**Button:** "Export Screenshot"

**Naming Convention:**
```
glass_qa_<timestamp>_<background>_blur-<value>.png
```

**Example:**
```
glass_qa_20251228_143022_stage_blur-5.0.png
```

**Implementation:**
```dart
import 'dart:html' as html;
import 'dart:ui' as ui;

Future<void> _exportScreenshot() async {
  // Use RepaintBoundary to capture widget
  final boundary = _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 2.0);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final bytes = byteData!.buffer.asUint8List();

  // Create download link
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', _generateFilename())
    ..click();
  html.Url.revokeObjectUrl(url);
}

String _generateFilename() {
  final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
  final bg = _selectedBackground.toString().split('.').last;
  return 'glass_qa_${timestamp}_${bg}_blur-${_blurSigma.toStringAsFixed(1)}.png';
}
```

---

## Glass Card Preview

**Content:**
```dart
GlassCard(
  blurStrength: _blurSigma,
  borderOpacity: _rimOpacity,
  debugDisableBlur: !_blurEnabled,
  debugShowFillProof: _fillProofEnabled,
  debugExaggerateReflections: _reflectionIntensity > 0.5, // FE-UI-110
  body: Padding(
    padding: const EdgeInsets.all(24.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Glass QA Test',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: DesignTokens.textPrimary,
          ),
        ),
        SizedBox(height: 16),
        Text(
          'This card demonstrates the glass effect with current parameters.',
          style: TextStyle(
            color: DesignTokens.textSecondary,
          ),
        ),
        SizedBox(height: 24),
        // Test input field
        TextField(
          decoration: InputDecoration(
            labelText: 'Test Input',
            hintText: 'Type to test input glass effect',
          ),
        ),
      ],
    ),
  ),
)
```

---

## Controls Panel Implementation

```dart
class _ControlsPanel extends StatelessWidget {
  final BackgroundType selectedBackground;
  final Function(BackgroundType) onBackgroundChanged;
  final bool blurEnabled;
  final bool reflectionsEnabled;
  final bool rimsEnabled;
  final bool glassStageEnabled;
  final bool fillProofEnabled;
  final Function(bool) onToggle;
  // ... sliders

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.2))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Background selector
          _buildBackgroundSelector(),
          SizedBox(height: 16),
          // Toggles
          _buildToggles(),
          SizedBox(height: 16),
          // Sliders
          _buildSliders(),
          SizedBox(height: 16),
          // Actions
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _exportScreenshot,
                icon: Icon(Icons.download),
                label: Text('Export Screenshot'),
              ),
              SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _resetToDefaults,
                icon: Icon(Icons.refresh),
                label: Text('Reset'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

---

## File Structure

```
lib/
├── src/
│   ├── screens/
│   │   ├── collection_wizard_screen.dart
│   │   ├── glass_qa_harness_screen.dart  ← NEW (FE-UI-112)
│   │   └── settings_screen.dart
│   └── ui/
│       ├── glass_card.dart
│       └── design_tokens.dart
```

---

## Acceptance Criteria

- [ ] `/glass_lab` route accessible
- [ ] 4 background options functional (flat, stage, photo, checkerboard)
- [ ] 5 toggles working (blur, reflections, rims, glass stage, fill proof)
- [ ] 4 sliders adjusting parameters in real-time
- [ ] Export screenshot button with auto-naming
- [ ] Can reproduce "liquid" vs "fog" in <10 seconds
- [ ] Screenshot pack consistent and comparable

---

## Testing Workflow (Example)

### Test: Prove Glass Stage Prevents Grey Fog

1. Navigate to `/glass_lab`
2. Set background to "Flat" → Card looks grey fog ❌
3. Toggle "Glass Stage" ON → Card shows refraction ✅
4. Export screenshot: `glass_qa_flat_stage-on.png`
5. Toggle "Glass Stage" OFF → Grey fog returns ❌
6. Export screenshot: `glass_qa_flat_stage-off.png`

**Result:** Side-by-side proof that glass stage prevents grey fog

---

## Future Enhancements

- [ ] Animation toggle (rotate light source)
- [ ] Multiple card sizes (small, medium, large)
- [ ] Custom background image upload
- [ ] Parameter presets (load/save configurations)
- [ ] Diff mode (compare two screenshots side-by-side)
- [ ] Performance metrics overlay (FPS, memory)

---

## Related Tickets

- **FE-UI-109:** Glass Stage layer (background option)
- **FE-UI-110:** Reflection system v2 (toggle + intensity slider)
- **FE-UI-111:** Thin sheet mode (validates no panel look)
- **FE-UI-114:** Testing requirements (screenshot export)

---

## Implementation Priority

**Phase 1 (MVP):**
- Basic screen with glass card preview
- Background selector (flat, stage)
- Blur toggle
- Export screenshot button

**Phase 2 (Full):**
- All 4 backgrounds
- All 5 toggles
- All 4 sliders
- Auto-naming convention

**Phase 3 (Polish):**
- Presets
- Animation
- Diff mode

---

## Version History

- **2025-12-28:** FE-UI-112 - Implementation plan created
