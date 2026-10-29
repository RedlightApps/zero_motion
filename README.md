# ⚡ ZERO MOTION (`package:zero_motion`)

[![Pub Version](https://img.shields.io/pub/v/zero_motion.svg?style=for-the-badge&color=00E5FF)](https://pub.dev/packages/zero_motion)
[![License: MIT](https://img.shields.io/badge/License-MIT-00E676.svg?style=for-the-badge)](LICENSE)
[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20a%20Coffee-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/yusufkaval)
[![GitHub Sponsors](https://img.shields.io/badge/Sponsor-EA4AAA?style=for-the-badge&logo=github-sponsors&logoColor=white)](https://github.com/sponsors/kvlyusuf)

**Next-Generation 120Hz Interruptible 2D/4D Spring Physics, In-Place Geometric Morphing Surfaces, Dynamic Island Capsules, Fluid Bottom Sheets (`FluidTray`), Sonner-Style 3D Toast Decks, and `Cmd+K` Command Palette Engine for Flutter.**

Published and maintained by **[RedLight Apps](https://redlightapps.com)** (`redlightapps.com`) • Created by **Yusuf Kaval**

---

### 🌍 Multi-Language Documentation (Zero-to-Hero Guides)

| Language | Complete Manual Link |
| :--- | :--- |
| 🇬🇧 **English** | [Read English Guide in `DOCUMENTATION.md`](DOCUMENTATION.md#en-guide) • [`doc/EN_GUIDE.md`](doc/EN_GUIDE.md) |
| 🇹🇷 **Türkçe** | [`DOCUMENTATION.md` Türkçe Tam Rehber](DOCUMENTATION.md#tr-guide) • [`doc/TR_GUIDE.md`](doc/TR_GUIDE.md) |
| 🇪🇸 **Español** | [Leer la Guía en Español en `DOCUMENTATION.md`](DOCUMENTATION.md#es-guide) |
| 🇩🇪 **Deutsch** | [Handbuch auf Deutsch in `DOCUMENTATION.md`](DOCUMENTATION.md#de-guide) |
| 🇫🇷 **Français** | [Guide en Français dans `DOCUMENTATION.md`](DOCUMENTATION.md#fr-guide) |
| 🇨🇳 **简体中文** | [`DOCUMENTATION.md` 简体中文指南](DOCUMENTATION.md#zh-guide) |
| 🇯🇵 **日本語** | [`DOCUMENTATION.md` 日本語ガイド](DOCUMENTATION.md#ja-guide) |
| 🇰🇷 **한국어** | [`DOCUMENTATION.md` 한국어 가이드](DOCUMENTATION.md#ko-guide) |
| 🇧🇷 **Português** | [Guia em Português em `DOCUMENTATION.md`](DOCUMENTATION.md#pt-guide) |
| 🇷🇺 **Русский** | [Руководство на русском в `DOCUMENTATION.md`](DOCUMENTATION.md#ru-guide) |
| 🇸🇦 **العربية** | [الدليل باللغة العربية في `DOCUMENTATION.md`](DOCUMENTATION.md#ar-guide) |

---

## 1. Why `zero_motion` Exists

Traditional Flutter animations (`AnimatedContainer`, `TweenAnimationBuilder`, `CurvedAnimation`, `OpenContainer`) are **duration and curve based**. When a user grabs a card mid-flight (at 40% expansion) or when target coordinates change dynamically, instantaneous velocity is discarded and motion snaps robotically.

Furthermore, Flutter's built-in `Hero` widget only works **across two separate `Route`s**—you cannot morph a button or pill into an interactive card on the same screen. Standard `BottomSheet` packages either jump abruptly or throw `RenderFlex overflow` exceptions when inner step content changes height.

**`zero_motion` unifies the 5 most sought-after physical UI primitives from modern Web and iOS (`Motion` + `Vaul` + `Family Dynamic Tray` + `Sonner` + `Cmd+K`) into a single, zero-dependency, 120Hz Flutter engine:**

| Capability | `animations` (`OpenContainer`) | `modal_bottom_sheet` / `wolt_modal_sheet` | `toastification` / `fluttertoast` | **`zero_motion`** |
| :--- | :---: | :---: | :---: | :---: |
| **Mid-Flight Velocity Preservation ($C^1$ Continuity)** | ❌ (Duration-based) | ⚠️ (Vertical axis only) | ❌ | **✅ (`SpringSolver1D/2D/Rect`)** |
| **In-Place Geometric Morphing (No Route Push)** | ❌ (Forces Route) | ❌ | ❌ | **✅ (`MorphSurface` & `DynamicIslandCapsule`)** |
| **Auto-Measuring Spring Height Bottom Sheet** | ❌ | ❌ (Jumps / Overflows) | ❌ | **✅ (`FluidTray` + `ScrimScaleHost`)** |
| **3D Depth & Fan-Out Toast Notification Deck** | ❌ | ❌ | ⚠️ (Flat list) | **✅ (`PhysicsToastDeck`)** |
| **Built-In `Cmd+K` Fuzzy Search Command Palette** | ❌ | ❌ | ❌ | **✅ (`CommandPaletteHost` + `FuzzyCommandScorer`)** |

---

## 2. 5-Minute Quick Start

Add `zero_motion` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  zero_motion: ^1.0.0
```

### 2.1 Pillar 1: `ZeroSpringBuilder` & `SpringSolver` (120Hz Velocity-Preserving Physics)

```dart
import 'package:flutter/material.dart';
import 'package:zero_motion/zero_motion.dart';

ZeroSpringBuilder(
  value: isToggled ? 160.0 : 0.0,
  profile: SpringProfile.bouncy, // snappy, bouncy, fluid, gentle, interactive
  builder: (context, currentValue, velocity, child) {
    return Transform.translate(
      offset: Offset(currentValue, 0),
      child: Text('Velocity: ${velocity.toStringAsFixed(0)} px/s'),
    );
  },
);
```

### 2.2 Pillar 2: `MorphSurface` & `DynamicIslandCapsule` (In-Place Geometric Morphing)

```dart
MorphSurface(
  profile: SpringProfile.fluid,
  closedBuilder: (context, open) => FilledButton(
    onPressed: open,
    child: const Text('Quick Transfer'),
  ),
  expandedBuilder: (context, close) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text('Interactive Morphed Card'),
      ElevatedButton(onPressed: close, child: const Text('Collapse')),
    ],
  ),
);
```

### 2.3 Pillar 3: `FluidTray` & `ScrimScaleHost` (Dynamic Height Bottom Sheet)

```dart
final trayProgress = ValueNotifier<double>(0.0);

Stack(
  children: [
    ScrimScaleHost(
      progressListenable: trayProgress,
      child: PrimaryScreenWidget(),
    ),
    FluidTray(
      isOpen: isSheetOpen,
      progressNotifier: trayProgress,
      onDismissed: () => setState(() => isSheetOpen = false),
      child: step == 1 ? CompactStepWidget() : ExpandedStepWidget(),
    ),
  ],
);
```

### 2.4 Pillar 4: `PhysicsToastDeck` (Sonner-Style 3D Toast Stack)

```dart
final toastController = PhysicsToastController();

// Trigger a 3D toast:
toastController.show(
  title: 'Deployment Complete',
  subtitle: 'Hover or tap the deck to fan out all notifications.',
  type: PhysicsToastType.success,
);

// Mount inside your Stack:
PhysicsToastDeck(controller: toastController);
```

### 2.5 Pillar 5: `CommandPaletteHost` (`Cmd+K` / `Ctrl+K` Fuzzy Command Palette)

```dart
CommandPaletteHost(
  controller: paletteController,
  actions: [
    ZeroCommandAction(
      id: 'deploy',
      title: 'Deploy to Production',
      shortcutLabel: '⌘D',
      onSelected: () {},
    ),
  ],
  child: Scaffold(...),
);
```

---

## 3. License & Support

MIT License • Copyright (c) 2026 **RedLight Apps & Yusuf Kaval** (`https://redlightapps.com`)
