import 'dart:async';
import 'package:flutter/material.dart';
import 'package:zero_motion/zero_motion.dart';

void main() => runApp(const ZeroMotionShowcaseApp());

/// Studio-grade 120Hz interactive & auto-choreographed showcase for `zero_motion`.
class ZeroMotionShowcaseApp extends StatefulWidget {
  /// Creates a [ZeroMotionShowcaseApp].
  const ZeroMotionShowcaseApp({super.key});

  @override
  State<ZeroMotionShowcaseApp> createState() => _ZeroMotionShowcaseAppState();
}

class _ZeroMotionShowcaseAppState extends State<ZeroMotionShowcaseApp> {
  final CommandPaletteController _paletteController = CommandPaletteController();
  final PhysicsToastController _toastController = PhysicsToastController();
  final ValueNotifier<double> _trayProgress = ValueNotifier<double>(0.0);

  DynamicIslandMode _islandMode = DynamicIslandMode.expanded;
  SpringProfile _activeProfile = SpringProfile.bouncy;
  bool _isTrayOpen = false;
  int _trayStep = 1;
  double _springTarget = 86.0;
  int _tourPhase = 0;
  Timer? _tourTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _toastController.show(
        title: 'Velocity-Preserving C1 Solver',
        subtitle: 'Mid-flight retargeting active @ 120Hz',
        type: PhysicsToastType.info,
        duration: const Duration(seconds: 60),
      );
      _toastController.show(
        title: '120Hz Spring Engine Ready',
        subtitle: 'Analytical damped harmonic oscillator online',
        type: PhysicsToastType.success,
        duration: const Duration(seconds: 60),
      );
      _tourTimer = Timer.periodic(const Duration(milliseconds: 950), (_) {
        if (mounted) _advanceTour();
      });
    });
  }

  void _advanceTour() {
    _tourPhase = (_tourPhase + 1) % 6;
    switch (_tourPhase) {
      case 0:
        _paletteController.close();
        setState(() {
          _islandMode = DynamicIslandMode.expanded;
          _activeProfile = SpringProfile.bouncy;
          _springTarget = 88.0;
          _isTrayOpen = false;
        });
      case 1:
        setState(() {
          _islandMode = DynamicIslandMode.compact;
          _activeProfile = SpringProfile.snappy;
          _springTarget = 18.0;
        });
      case 2:
        setState(() {
          _islandMode = DynamicIslandMode.expanded;
          _activeProfile = SpringProfile.fluid;
          _springTarget = 94.0;
          _isTrayOpen = true;
          _trayStep = 1;
        });
      case 3:
        setState(() {
          _trayStep = 2;
          _springTarget = 38.0;
        });
      case 4:
        setState(() => _isTrayOpen = false);
        _paletteController.open();
      case 5:
        _paletteController.close();
        _toastController.show(
          title: 'Mid-Flight Retarget Triggered',
          subtitle: 'Zero momentum loss during C1 transition',
          type: PhysicsToastType.warning,
          duration: const Duration(seconds: 4),
        );
    }
  }

  @override
  void dispose() {
    _tourTimer?.cancel();
    _paletteController.dispose();
    _toastController.dispose();
    _trayProgress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: CommandPaletteHost(
        controller: _paletteController,
        actions: [
          ZeroCommandAction(
            id: 'island_toggle',
            title: 'Toggle Dynamic Island Capsule',
            subtitle: 'Switch between minimal, compact, and expanded 2D springs',
            shortcutLabel: '⌘I',
            onSelected: () => setState(() => _islandMode = DynamicIslandMode.expanded),
          ),
          ZeroCommandAction(
            id: 'tray_open',
            title: 'Open FluidTray Dynamic Bottom Sheet',
            subtitle: 'Spring-driven height morphing with 3D background scale',
            shortcutLabel: '⌘B',
            onSelected: () => setState(() => _isTrayOpen = true),
          ),
        ],
        child: Scaffold(
          backgroundColor: const Color(0xFF070911),
          body: Stack(
            children: [
              ScrimScaleHost(progressListenable: _trayProgress, child: SafeArea(child: _buildDashboard())),
              FluidTray(isOpen: _isTrayOpen, progressNotifier: _trayProgress, onDismissed: () => setState(() => _isTrayOpen = false), child: _buildTraySheet()),
              PhysicsToastDeck(controller: _toastController),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    final profiles = [('Snappy', SpringProfile.snappy), ('Bouncy', SpringProfile.bouncy), ('Fluid', SpringProfile.fluid)];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 130),
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('zero_motion', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  Text('120Hz Physics & Morphing UI Engine', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8))),
                ],
              ),
            ),
            FilledButton.tonalIcon(onPressed: () => setState(() => _isTrayOpen = true), icon: const Icon(Icons.layers, size: 15), label: const Text('Sheet', style: TextStyle(fontSize: 11.5))),
            const SizedBox(width: 6),
            FilledButton.icon(onPressed: _paletteController.open, icon: const Icon(Icons.terminal, size: 15), label: const Text('⌘K', style: TextStyle(fontSize: 11.5))),
          ],
        ),
        const SizedBox(height: 14),
        Center(
          child: DynamicIslandCapsule(
            mode: _islandMode,
            profile: _activeProfile,
            expandedSize: const Size(362, 146),
            onModeChanged: (m) => setState(() => _islandMode = m),
            compactBuilder: (_) => const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt, color: Color(0xFF00E676), size: 16),
                SizedBox(width: 6),
                Flexible(child: Text('120Hz Spring Island', overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
              ],
            ),
            expandedBuilder: (_) => _buildIslandBody(),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFF111726), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1E293B))),
          child: Row(
            children: profiles.map((p) {
              final sel = _activeProfile == p.$2;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(color: sel ? const Color(0x2838BDF8) : const Color(0xFF0B0F1A), borderRadius: BorderRadius.circular(10), border: Border.all(color: sel ? const Color(0xFF38BDF8) : const Color(0xFF1E293B))),
                  child: Center(child: Text(p.$1, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: sel ? const Color(0xFF38BDF8) : Colors.white))),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _featureCard(Icons.open_in_full_rounded, const Color(0xFF38BDF8), 'MorphSurface', 'In-place Rect & Radius morphing', '2D Solver')),
            const SizedBox(width: 12),
            Expanded(child: _featureCard(Icons.speed_rounded, const Color(0xFFA855F7), 'Mid-Flight Retarget', 'Reverse target C1 momentum', 'C1 Continuous')),
          ],
        ),
      ],
    );
  }

  Widget _buildIslandBody() => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_graph, color: Color(0xFF00E676), size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DynamicIslandCapsule (2D Spring)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      Text('Drag to rubber-band stretch or tap to collapse', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5)),
                    ],
                  ),
                ),
              ],
            ),
            ZeroSpringBuilder(
              value: _springTarget,
              profile: _activeProfile,
              builder: (context, val, vel, _) => Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Displacement: ${val.toStringAsFixed(1)} px', style: const TextStyle(fontSize: 11.5)), Text('Velocity: ${vel.toStringAsFixed(0)} px/s', style: const TextStyle(fontSize: 11.5, color: Color(0xFF00E676)))]),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(value: (val / 100.0).clamp(0.0, 1.0), minHeight: 7, backgroundColor: const Color(0xFF1E293B), color: const Color(0xFF38BDF8)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _featureCard(IconData icon, Color accent, String title, String sub, String badge) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: const Color(0xFF111726), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1E293B))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Icon(icon, color: accent, size: 20), Text(badge, style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w800))]),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
            Text(sub, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          ],
        ),
      );

  Widget _buildTraySheet() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('FluidTray — Dynamic Step $_trayStep', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            if (_trayStep == 2) ...[
              const SizedBox(height: 10),
              const Text('Spring-interpolated height morphing @ 120Hz with 3D ScrimScaleHost depth.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            ],
            const SizedBox(height: 12),
            FilledButton(onPressed: () => setState(() => _trayStep = _trayStep == 1 ? 2 : 1), child: const Text('Morph Sheet Height')),
          ],
        ),
      );
}
