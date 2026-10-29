import 'package:flutter/material.dart';
import 'package:zero_motion/zero_motion.dart';

void main() {
  runApp(const ZeroMotionShowcaseApp());
}

/// `zero_motion` paketinin 5 temel sütununu canlı olarak sergileyen 120Hz vitrin.
class ZeroMotionShowcaseApp extends StatefulWidget {
  /// Bir [ZeroMotionShowcaseApp] oluşturur.
  const ZeroMotionShowcaseApp({super.key});

  @override
  State<ZeroMotionShowcaseApp> createState() => _ZeroMotionShowcaseAppState();
}

class _ZeroMotionShowcaseAppState extends State<ZeroMotionShowcaseApp> {
  final CommandPaletteController _paletteController = CommandPaletteController();
  final PhysicsToastController _toastController = PhysicsToastController();
  final ValueNotifier<double> _trayProgress = ValueNotifier<double>(0.0);

  DynamicIslandMode _islandMode = DynamicIslandMode.compact;
  bool _isTrayOpen = false;
  int _trayStep = 1;
  double _springTarget = 0.0;

  List<ZeroCommandAction> _buildCommands() => [
    ZeroCommandAction(
      id: 'island_toggle',
      title: 'Dynamic Island Kipini Değiştir',
      shortcutLabel: '⌘I',
      onSelected: () => setState(() {
        _islandMode = _islandMode == DynamicIslandMode.expanded
            ? DynamicIslandMode.compact
            : DynamicIslandMode.expanded;
      }),
    ),
    ZeroCommandAction(
      id: 'tray_open',
      title: 'Akışkan Alt Çekmeceyi (FluidTray) Aç',
      shortcutLabel: '⌘B',
      onSelected: () => setState(() {
        _trayStep = 1;
        _isTrayOpen = true;
      }),
    ),
    ZeroCommandAction(
      id: 'toast_menu',
      title: '3D Fiziksel Bildirim Gönder',
      children: [
        ZeroCommandAction(
          id: 'toast_success',
          title: 'Başarı Bildirimi (Sonner 3D)',
          onSelected: () => _toastController.show(
            title: '120Hz Yay Motoru Aktif',
            subtitle: 'Hız koruyucu C1 türev sürekliliği doğrulandı.',
            type: PhysicsToastType.success,
          ),
        ),
      ],
    ),
  ];

  @override
  void dispose() {
    _paletteController.dispose();
    _toastController.dispose();
    _trayProgress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Zero Motion 120Hz Vitrin',
      theme: ThemeData.dark(useMaterial3: true),
      home: CommandPaletteHost(
        controller: _paletteController,
        actions: _buildCommands(),
        child: Scaffold(
          backgroundColor: const Color(0xFF09090F),
          body: Stack(
            children: [
              ScrimScaleHost(
                progressListenable: _trayProgress,
                child: SafeArea(child: _buildMainDashboard()),
              ),
              FluidTray(
                isOpen: _isTrayOpen,
                progressNotifier: _trayProgress,
                onDismissed: () => setState(() => _isTrayOpen = false),
                child: _buildTrayContent(),
              ),
              PhysicsToastDeck(controller: _toastController),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainDashboard() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        Center(
          child: DynamicIslandCapsule(
            mode: _islandMode,
            onModeChanged: (m) => setState(() => _islandMode = m),
            compactBuilder: (_) => const Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.graphic_eq, color: Color(0xFF38BDF8), size: 16),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Zero Motion',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              ],
            ),
            expandedBuilder: (_) => Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Dynamic Island 2D Yay Kapsülü', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ElevatedButton(
                    onPressed: () => setState(() => _islandMode = DynamicIslandMode.compact),
                    child: const Text('Kapsülü Daralt'),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: MorphSurface(
            closedBuilder: (context, open) => ElevatedButton.icon(
              onPressed: open,
              icon: const Icon(Icons.auto_awesome_motion),
              label: const Text('In-Place MorphSurface Aç'),
            ),
            expandedBuilder: (context, close) => Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Kesintisiz Geometrik Morphing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: close, child: const Text('Yuvaya Dön')),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            FilledButton.tonal(
              onPressed: () => setState(() {
                _trayStep = 1;
                _isTrayOpen = true;
              }),
              child: const Text('FluidTray Çekmecesini Aç'),
            ),
            FilledButton.tonal(
              onPressed: () => _toastController.show(
                title: 'Sonner 3D Bildirim',
                subtitle: 'Üzerine dokunarak desteyi yelpaze gibi açın!',
                type: PhysicsToastType.info,
              ),
              child: const Text('3D Bildirim Ekle'),
            ),
            FilledButton.tonal(onPressed: _paletteController.open, child: const Text('Cmd+K Komuta Paleti')),
            FilledButton.tonal(
              onPressed: () => setState(() => _springTarget = _springTarget == 0.0 ? 120.0 : 0.0),
              child: const Text('Hedefi Hareket Ortasında Ters Çevir'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ZeroSpringBuilder(
          value: _springTarget,
          profile: SpringProfile.bouncy,
          builder: (context, val, vel, _) => Center(
            child: Transform.translate(
              offset: Offset(val, 0),
              child: Chip(label: Text('Konum: ${val.toStringAsFixed(1)} | Hız: ${vel.toStringAsFixed(0)} px/s')),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrayContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: _trayStep == 1
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('FluidTray — Adım 1 (Kompakt Yükseklik)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                FilledButton(onPressed: () => setState(() => _trayStep = 2), child: const Text('Adım 2ye Geç (Dinamik Yay Yükseklik)')),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('FluidTray — Adım 2 (Genişletilmiş İçerik)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text(
                  'İçerik büyüdüğünde çekmece zıplamaz ve RenderFlex overflow vermeden 120Hz yay fiziğiyle yeni yüksekliğe esner.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton(onPressed: () => setState(() => _isTrayOpen = false), child: const Text('Kapat')),
              ],
            ),
    );
  }
}
