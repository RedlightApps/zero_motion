# Changelog

All notable changes to this project will be documented in this file.

## 1.0.1

- Added high-resolution iOS Simulator showcase screenshots (`pubspec.yaml` gallery & `README.md`) and upgraded the interactive 120Hz Bento + Dynamic Island + Harmonic Profile selector example app.

## 1.0.0

* **Initial Stable Release (`RedLight Apps` — `redlightapps.com` / Yusuf Kaval)**
* **Pillar 1 — 120Hz Velocity-Preserving 1D/2D/Rect Analytical Spring Solver (`SpringProfile`, `SpringSolver1D`, `SpringSolver2D`, `SpringRectSolver`, `GestureSpringController`, `ZeroSpringBuilder`):**
  * Closed-form differential equation solver preserving instantaneous position and velocity ($C^1$ continuity) during mid-flight retargeting.
  * Under-damped ($\zeta < 1$), critically damped ($\zeta = 1$), and over-damped ($\zeta > 1$) regimes with preset profiles (`snappy`, `bouncy`, `fluid`, `gentle`, `interactive`).
* **Pillar 2 — In-Place Geometric Morphing & Dynamic Island (`MorphSurface`, `DynamicIslandCapsule`):**
  * Transforms compact buttons or pills into interactive cards/overlays with continuous `Rect`, `BorderRadius`, and backdrop Gaussian blur interpolation without pushing a new `Route`.
  * Hyperbolic rubber-band drag resistance and velocity-aware release snapping.
  * Multi-mode (`minimal`, `compact`, `expanded`) `DynamicIslandCapsule` widget.
* **Pillar 3 — Dynamic-Height & Keyboard-Aware Fluid Bottom Tray (`FluidTray`, `ScrimScaleHost`):**
  * Automatically measures child layout height changes (`FluidChildSizeMeasure`) and springs smoothly between steps without `RenderFlex overflow` errors.
  * Multi-detent snapping and 3D background scaling/blurring (`ScrimScaleHost`).
* **Pillar 4 — Sonner-Style 3D Stackable Toast Deck (`PhysicsToastController`, `PhysicsToastDeck`, `PhysicsToastItem`):**
  * 3D stacked notification cards that pause timers and fan out on hover/tap, with momentum swipe-to-dismiss physics.
* **Pillar 5 — `Cmd+K` / Spotlight Fuzzy Command Palette (`FuzzyCommandScorer`, `CommandPaletteHost`, `ZeroCommandAction`):**
  * Zero-dependency $O(N)$ subsequence fuzzy scorer with character highlighting, nested breadcrumb sub-menus, and full keyboard navigation.
