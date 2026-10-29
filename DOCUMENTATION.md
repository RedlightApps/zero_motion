# ZERO MOTION (`package:zero_motion`) — Çok Dilli Tam Dokümantasyon

---

<a id="tr-guide"></a>
## 🇹🇷 Türkçe Tam Rehber (`zero_motion`)

### 1. Mimari Felsefe
`zero_motion`, Flutter'ın standart süre-tabanlı (`Duration` / `Curve`) animasyonlarının en büyük kusuru olan **hareket ortasında hız kaybı (velocity discontinuity)** sorununu kapalı-form sönümlü harmonik osilatör denklemiyle ($m \ddot{x} + c \dot{x} + k(x - x_{\text{target}}) = 0$) çözer.

### 2. 5 Temel Sütun
1. **1D/2D/4D Hız Koruyucu Yay Çözücü (`SpringProfile`, `SpringSolver1D`, `SpringSolver2D`, `SpringRectSolver`, `GestureSpringController`, `ZeroSpringBuilder`):** 60Hz, 120Hz ve 240Hz ekranlarda kare hızından bağımsız analitik çözüm.
2. **Aynı Ekranda Geometrik Morphing (`MorphSurface`, `DynamicIslandCapsule`):** Yeni bir `Route` açmadan kaynak widget'ın ekran koordinatlarını (`Rect` + `BorderRadius`) yakalayıp bulanık arka plan üzerinde genişleten ve parmakla sürüklenip bırakıldığında hız vektörüyle yuvasına dönen yüzey.
3. **Akışkan Alt Çekmece (`FluidTray`, `ScrimScaleHost`):** Alt widget'ın yüksekliği değiştiğinde (Step 1 -> Step 2) veya klavye açıldığında `RenderFlex overflow` üretmeden yay fiziğiyle boyutlanan çekmece.
4. **3D Fiziksel Bildirim Destesi (`PhysicsToastController`, `PhysicsToastDeck`):** Bildirimleri 3D derinlikle üst üste dizen, üzerine gelince/dokununca yelpaze gibi açan ve hızlı sürüklemede fırlatılan deste.
5. **`Cmd+K` Komuta Paleti (`CommandPaletteHost`, `FuzzyCommandScorer`):** Sıfır bağımlılıklı $O(N)$ bulanık arama puanlayıcısı, harf vurgulayıcı ve alt menü (breadcrumb) navigasyonu.

---

<a id="en-guide"></a>
## 🇬🇧 English Guide (`zero_motion`)

`zero_motion` unifies 120Hz analytical velocity-preserving 2D/4D spring physics (`SpringSolver1D`, `SpringSolver2D`, `SpringRectSolver`), in-place geometric container morphing (`MorphSurface`, `DynamicIslandCapsule`), dynamic-height fluid bottom sheets (`FluidTray`, `ScrimScaleHost`), Sonner-style 3D stackable toast decks (`PhysicsToastDeck`), and a `Cmd+K` fuzzy command palette (`CommandPaletteHost`) in a single zero-dependency Flutter package.

---

<a id="es-guide"></a>
## 🇪🇸 Guía en Español (`zero_motion`)

Motor de física de resortes de 120Hz sin interrupciones, superficies de transformación geométrica (`MorphSurface`, `DynamicIslandCapsule`), bandejas inferiores dinámicas (`FluidTray`), notificaciones apilables 3D (`PhysicsToastDeck`) y paleta de comandos `Cmd+K` (`CommandPaletteHost`) para Flutter.

---

<a id="de-guide"></a>
## 🇩🇪 Handbuch auf Deutsch (`zero_motion`)

120Hz unterbrechbare Federphysik, geometrisches In-Place-Morphing (`MorphSurface`, `DynamicIslandCapsule`), dynamische Bottom-Sheets (`FluidTray`), 3D-Toast-Stapel (`PhysicsToastDeck`) und `Cmd+K`-Befehlspalette (`CommandPaletteHost`) für Flutter.

---

<a id="fr-guide"></a>
## 🇫🇷 Guide en Français (`zero_motion`)

Moteur physique à ressort 120Hz interruptible, morphing géométrique sur place (`MorphSurface`, `DynamicIslandCapsule`), tiroirs fluides (`FluidTray`), notifications 3D empilables (`PhysicsToastDeck`) et palette de commandes `Cmd+K` (`CommandPaletteHost`) pour Flutter.

---

<a id="zh-guide"></a>
## 🇨🇳 简体中文指南 (`zero_motion`)

面向 Flutter 的 120Hz 可中断弹簧物理引擎、原地几何变形组件 (`MorphSurface`, `DynamicIslandCapsule`)、自适应高度底部抽屉 (`FluidTray`)、Sonner 风格 3D 通知堆叠 (`PhysicsToastDeck`) 以及 `Cmd+K` 模糊搜索命令面板 (`CommandPaletteHost`)。

---

<a id="ja-guide"></a>
## 🇯🇵 日本語ガイド (`zero_motion`)

Flutter 向け 120Hz 速度保持スプリング物理エンジン、インプレース幾何モーフィング (`MorphSurface`, `DynamicIslandCapsule`)、動的サイズ調整ボトムシート (`FluidTray`)、3D トーストデッキ (`PhysicsToastDeck`)、および `Cmd+K` コマンドパレット (`CommandPaletteHost`)。

---

<a id="ko-guide"></a>
## 🇰🇷 한국어 가이드 (`zero_motion`)

Flutter용 120Hz 속도 보존 스프링 물리 엔진, 인플레이스 모핑 표면 (`MorphSurface`, `DynamicIslandCapsule`), 동적 높이 바텀 시트 (`FluidTray`), 3D 토스트 덱 (`PhysicsToastDeck`), `Cmd+K` 커맨드 팔레트 (`CommandPaletteHost`).

---

<a id="pt-guide"></a>
## 🇧🇷 Guia em Português (`zero_motion`)

Física de molas de 120Hz interrompível, morphing geométrico no local (`MorphSurface`, `DynamicIslandCapsule`), gavetas inferiores dinâmicas (`FluidTray`), pilha de notificações 3D (`PhysicsToastDeck`) e paleta de comandos `Cmd+K` (`CommandPaletteHost`) para Flutter.

---

<a id="ru-guide"></a>
## 🇷🇺 Руководство на русском (`zero_motion`)

Пружинная физика 120 Гц с сохранением скорости, геометрический морфинг (`MorphSurface`, `DynamicIslandCapsule`), адаптивные нижние панели (`FluidTray`), 3D-стек уведомлений (`PhysicsToastDeck`) и командная палитра `Cmd+K` (`CommandPaletteHost`) для Flutter.

---

<a id="ar-guide"></a>
## 🇸🇦 الدليل باللغة العربية (`zero_motion`)

محرك فيزياء النوابض 120 هرتز القابل للمقاطعة، والتحويل الهندسي الفوري (`MorphSurface`, `DynamicIslandCapsule`)، والأدراج السفلية الديناميكية (`FluidTray`)، وإشعارات ثلاثية الأبعاد (`PhysicsToastDeck`) ولوحة أوامر `Cmd+K` (`CommandPaletteHost`) لـ Flutter.
