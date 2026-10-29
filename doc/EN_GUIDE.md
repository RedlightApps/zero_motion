# Zero Motion (`package:zero_motion`) — Complete English Guide

## 1. Analytical Velocity-Preserving Spring Physics (`SpringSolver1D`, `SpringSolver2D`, `SpringRectSolver`)
Unlike curve-based tweens that reset velocity when interrupted, `zero_motion` solves the damped harmonic oscillator equation in closed form on every tick:

```dart
final solver = SpringSolver1D(
  initialValue: 0.0,
  profile: SpringProfile.snappy,
)..setTarget(100.0);

// Retarget mid-flight: instantaneous velocity is preserved!
solver.setTarget(-50.0);
```

## 2. `MorphSurface` and `DynamicIslandCapsule`
Morph any button or pill into an expanded card in-place using `OverlayPortal`, with rubber-band drag resistance and velocity-preserving collapse.

## 3. `FluidTray` and `ScrimScaleHost`
When inner step content changes height, `FluidChildSizeMeasure` captures the new layout dimensions and springs the sheet height without `RenderFlex overflow`.

## 4. `PhysicsToastDeck`
Sonner-style 3D stacked notifications that automatically pause auto-dismiss timers and fan out when hovered or tapped.

## 5. `CommandPaletteHost`
`Cmd+K` / `Ctrl+K` Spotlight overlay powered by `FuzzyCommandScorer` with matched character highlighting and nested breadcrumb sub-commands.
