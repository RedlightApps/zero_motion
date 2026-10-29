# Zero Motion (`package:zero_motion`) — Sıfırdan Uzmanlığa Türkçe Rehber

## 1. Hız Koruyucu Yay Fiziği (`SpringSolver1D`, `SpringSolver2D`, `SpringRectSolver`)
Geleneksel `Tween` animasyonları hedef değiştiğinde hızı sıfırlar. `zero_motion` içindeki çözücüler ise diferansiyel denklemi analitik olarak çözerek anlık hızı ($v_t$) korur:

```dart
final solver = SpringSolver1D(
  initialValue: 0.0,
  profile: SpringProfile.snappy,
)..setTarget(100.0);

// Hareket ortasında hedefi değiştirin: hız sıfırlanmaz!
solver.setTarget(-50.0);
```

## 2. `MorphSurface` ve `DynamicIslandCapsule`
Aynı sayfa içinde bir butonu veya bilgi kapsülünü yay fiziğiyle genişletin ve parmakla sürükleyip bırakarak yuvasına geri döndürün.

## 3. `FluidTray` ve `ScrimScaleHost`
Çekmece içindeki içerik büyüdüğünde veya küçüldüğünde `FluidChildSizeMeasure` yeni boyutu yakalar ve `RenderFlex overflow` üretmeden yüksekliği yaylandırır.

## 4. `PhysicsToastDeck`
Sonner tarzı 3D derinlikli bildirim yığını; dokunulduğunda veya fareyle üzerine gelindiğinde otomatik kapanma sayaçlarını durdurur ve yelpaze gibi açılır.

## 5. `CommandPaletteHost`
`Cmd+K` / `Ctrl+K` kısayoluyla açılan, $O(N)$ bulanık arama (`FuzzyCommandScorer`) ve alt menü (breadcrumb) destekli komuta merkezi.
