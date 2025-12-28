# Background System Tuning Guide

## FE-BG-021: Edge Artifact Cleanup & Blur Parameter Tuning

This document provides recommended settings and troubleshooting for background presets to avoid edge artifacts, banding, and aliasing issues.

---

## Recommended Backdrop Blur Settings

### GlassCard Component
- **Blur Sigma**: `5.0` (current production value)
- **Alternative for sharper edges**: `3.0` (reduces bloom bleed)
- **Alternative for softer glass**: `8.0` (more diffusion)

**Location**: `/lib/src/ui/glass_card.dart` line ~200

```dart
BackdropFilter(
  filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
  child: ...
)
```

### Performance Impact
- Lower sigma (3.0-5.0): **Faster**, sharper edges, less bloom interaction
- Higher sigma (8.0-12.0): **Slower**, softer edges, more environment refraction

---

## Background Preset Intensity Guidelines

### Bloom Opacity Ranges
Recommended opacity ranges to avoid "muddy" overlays while maintaining visual richness:

| Bloom Type | Min Opacity | Max Opacity | Recommended |
|------------|-------------|-------------|-------------|
| Primary    | 0.14        | 0.22        | 0.18        |
| Secondary  | 0.10        | 0.18        | 0.14        |
| Tertiary   | 0.06        | 0.14        | 0.10        |

**Rule**: Primary + Secondary + Tertiary total opacity should not exceed **0.50** in any single region.

### Band Opacity Ranges
| Band Type      | Min Opacity | Max Opacity | Recommended |
|----------------|-------------|-------------|-------------|
| Diagonal       | 0.10        | 0.16        | 0.12        |
| Structured     | 0.08        | 0.14        | 0.10        |

### Vignette Settings
- **Standard**: 0.10 opacity
- **Night presets**: 0.15 opacity (deeper shadows)
- **Bright presets**: 0.08 opacity (subtle darkening)

---

## Edge Artifact Troubleshooting

### Problem: Harsh Banding on Card Corners

**Symptoms**:
- Visible stair-stepping on glass card borders
- Color bands instead of smooth gradients

**Solutions**:
1. Reduce bloom opacity by 2-4%
2. Increase bloom radius by 0.1-0.2
3. Add more gradient stops for smoother transitions
4. Enable anti-aliasing in CustomPaint if using custom shapes

**Example Fix**:
```dart
// Before (harsh banding)
BackgroundBloom(
  colors: [Color(0xFF5B8DEE).withOpacity(0.30), Colors.transparent],
  stops: [0.0, 1.0],
)

// After (smooth gradient)
BackgroundBloom(
  colors: [
    Color(0xFF5B8DEE).withOpacity(0.22),
    Color(0xFF5B8DEE).withOpacity(0.12),
    Colors.transparent
  ],
  stops: [0.0, 0.5, 1.0],
)
```

### Problem: Aliasing on Diagonal Bands

**Symptoms**:
- Jagged edges on diagonal gradients
- "Staircase" effect across screen

**Solutions**:
1. Ensure band colors have alpha values (no 100% opacity)
2. Add intermediate color stops
3. Use softer alignment values (avoid extreme angles)

**Example Fix**:
```dart
// Before (harsh diagonal)
BackgroundBand(
  begin: Alignment(-2.0, -2.0),
  end: Alignment(2.0, 2.0),
)

// After (gentler slope)
BackgroundBand(
  begin: Alignment(-1.2, -0.9),
  end: Alignment(1.2, 0.9),
)
```

### Problem: Grey Fog on Glass Cards

**Symptoms**:
- Glass cards appear grey instead of transparent
- Loss of "liquid glass" effect

**Root Cause**: Background blooms are too intense near cards

**Solutions**:
1. Reduce total bloom opacity in card intersection zones
2. Move bloom alignments away from center screen
3. Verify glass card fill is `Colors.transparent` (NOT `Colors.white.withOpacity(0.05)`)
4. Check that backdrop blur is enabled

**Verification**:
- Enable `debugShowFillProof` in GlassCard
- If hot pink appears, fill is non-transparent (BAD)
- If no hot pink, fill is transparent (GOOD)

### Problem: Noise Pattern Interference

**Symptoms**:
- Visible grid pattern on glass cards
- "Pixelated" appearance

**Solutions**:
1. Reduce noise opacity from 0.04 to 0.02
2. Increase sampling grid from 6.0 to 8.0 (less dense)
3. Lower draw probability from 0.4 to 0.3

---

## Blur Sigma Tuning by Preset

### Dawn/Dusk Presets
- **Recommended Sigma**: 5.0-6.0
- **Reason**: Warmer colors benefit from slight diffusion

### Day Preset
- **Recommended Sigma**: 4.0-5.0
- **Reason**: Brighter blooms need sharper edges to avoid washout

### Night Preset
- **Recommended Sigma**: 5.0-7.0
- **Reason**: Darker base allows for softer blur without losing definition

### Seasonal Presets
- **Spring/Summer**: 4.0-5.0 (vibrant, sharp)
- **Fall**: 5.0-6.0 (warm, soft)
- **Winter**: 5.0-6.0 (icy, diffused)

---

## Testing Checklist

Before marking a preset as "production-ready":

- [ ] **Zoom Test**: View at 100%, 125%, 150% zoom (no banding)
- [ ] **Corner Test**: Check all 4 card corners for aliasing
- [ ] **Center Test**: Glass card center is transparent (not grey)
- [ ] **Edge Test**: Card rims are clean and visible
- [ ] **Transition Test**: Smooth crossfade from/to other presets (no hard cuts)
- [ ] **Performance Test**: <16ms frame time during animations (60fps)
- [ ] **Contrast Test**: Text passes WCAG AA (4.5:1 ratio)

---

## Performance Benchmarks

### Target Frame Times (60fps = 16.67ms)
- **Background render**: <2ms
- **Snow particles (Low)**: <1ms
- **Snow particles (High)**: <3ms
- **Glass card blur**: <4ms
- **Total budget**: <12ms (leaves 4ms for app logic)

### Optimization Tips
1. Limit blooms to 3 per preset
2. Limit bands to 2 per preset
3. Keep snow particle count under 150
4. Use cached CustomPaint where possible
5. Avoid nested BackdropFilters

---

## Visual Reference

### Good vs Bad Examples

**GOOD**: Smooth gradient, transparent glass center, clean edges
- Bloom opacity: 0.18 / 0.14 / 0.10
- Blur sigma: 5.0
- No visible banding

**BAD**: Grey fog on glass, harsh banding, muddy overlay
- Bloom opacity: 0.40 / 0.35 / 0.30 (TOO HIGH)
- Blur sigma: 12.0 (TOO HIGH)
- Visible stair-stepping on corners

---

## Quick Reference Table

| Issue | Likely Cause | Solution |
|-------|--------------|----------|
| Grey fog on glass | Blooms too intense | Reduce opacity by 5-10% |
| Banding on corners | Hard gradient stops | Add intermediate stops |
| Aliased diagonals | Extreme angles | Use gentler alignments |
| Muddy appearance | Too many overlapping blooms | Reduce total opacity |
| Performance lag | Too many particles | Lower snow intensity |
| Text unreadable | Low contrast | Enable ReadabilityOverlay |

---

## Version History
- **v1.0** (2024-01-15): Initial tuning guide
- **v1.1** (2024-01-20): Added snow particle benchmarks

