import 'package:flutter/material.dart';
import 'package:zero_motion/zero_motion.dart';

void main() => runApp(const ZeroMotionShowcaseApp());

/// Studio-grade 120Hz interactive showcase for `zero_motion`.
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
  double _springTarget = 85.0;

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
    });
  }

  List<ZeroCommandAction> _buildCommands() => [
        ZeroCommandAction(
          id: 'island_toggle',
          title: 'Toggle Dynamic Island Capsule',
          subtitle: 'Switch between minimal, compact, and expanded 2D springs',
          shortcutLabel: '⌘I',
          onSelected: () => setState(() {
            _islandMode = _islandMode == DynamicIslandMode.expanded
                ? DynamicIslandMode.compact
                : DynamicIslandMode.expanded;
          }),
        ),
        ZeroCommandAction(
          id: 'tray_open',
          title: 'Open FluidTray Dynamic Bottom Sheet',
          subtitle: 'Spring-driven height morphing with 3D background scale',
          shortcutLabel: '⌘B',
          onSelected: () => setState(() => _isTrayOpen = true),
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
      title: 'zero_motion 120Hz Showcase',
      theme: ThemeData.dark(useMaterial3: true),
      home: CommandPaletteHost(
        controller: _paletteController,
        actions: _buildCommands(),
        child: Scaffold(
          backgroundColor: const Color(0xFF070911),
          body: Stack(
            children: [
              ScrimScaleHost(
                progressListenable: _trayProgress,
                child: SafeArea(child: _buildDashboard()),
              ),
              FluidTray(
                isOpen: _isTrayOpen,
                progressNotifier: _trayProgress,
                onDismissed: () => setState(() => _isTrayOpen = false),
                child: _buildTraySheet(),
              ),
              PhysicsToastDeck(controller: _toastController),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 130),
      children: [
        _buildTopHeader(),
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
                Flexible(
                  child: Text('120Hz Spring Island', overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ],
            ),
            expandedBuilder: (_) => Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0x2600E676), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.auto_graph, color: Color(0xFF00E676), size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('DynamicIslandCapsule (2D Spring)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                            Text('Drag to rubber-band stretch or tap to collapse', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(8)),
                        child: const Text('120 FPS', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  ZeroSpringBuilder(
                    value: _springTarget,
                    profile: _activeProfile,
                    builder: (context, val, vel, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Displacement: ${val.toStringAsFixed(1)} px', style: const TextStyle(fontSize: 11.5, color: Color(0xFFE2E8F0))),
                            Text('Velocity: ${vel.toStringAsFixed(0)} px/s', style: const TextStyle(fontSize: 11.5, color: Color(0xFF00E676))),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (val / 100.0).clamp(0.0, 1.0),
                            minHeight: 7,
                            backgroundColor: const Color(0xFF1E293B),
                            color: const Color(0xFF38BDF8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _buildProfileSelectorCard(),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: MorphSurface(
                closedBorderRadius: BorderRadius.circular(16),
                closedBuilder: (ctx, open) => _featureCard(
                  icon: Icons.open_in_full_rounded,
                  accent: const Color(0xFF38BDF8),
                  title: 'MorphSurface',
                  subtitle: 'Hero-less in-place Rect & Radius morphing',
                  badge: '2D Rect Solver',
                  onTap: open,
                ),
                expandedBuilder: (ctx, close) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('In-Place Rect & Radius Morph', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: close, child: const Text('Morph Back')),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _featureCard(
                icon: Icons.speed_rounded,
                accent: const Color(0xFFA855F7),
                title: 'Mid-Flight Retarget',
                subtitle: 'Reverse target without losing momentum',
                badge: 'C1 Continuous',
                onTap: () => setState(() => _springTarget = _springTarget > 50 ? 22.0 : 88.0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _featureCard(
                icon: Icons.view_agenda_rounded,
                accent: const Color(0xFF00E676),
                title: 'FluidTray Sheet',
                subtitle: 'Auto-morphing bottom sheet + 3D scrim scale',
                badge: 'Rubber-Band',
                onTap: () => setState(() => _isTrayOpen = true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _featureCard(
                icon: Icons.manage_search_rounded,
                accent: const Color(0xFFF59E0B),
                title: 'Command Palette',
                subtitle: 'O(N) fuzzy search launcher with nested actions',
                badge: 'Cmd+K / Ctrl+K',
                onTap: _paletteController.open,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileSelectorCard() {
    final profiles = [
      ('Snappy', SpringProfile.snappy, 'ζ = 1.0 • 0.18s'),
      ('Bouncy', SpringProfile.bouncy, 'ζ = 0.62 • 0.38s'),
      ('Fluid', SpringProfile.fluid, 'ζ = 0.82 • 0.42s'),
    ];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111726),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Harmonic Spring Profiles',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
              Text(
                'x\'\' + 2ζω₀x\' + ω₀²x = 0',
                style: TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFF38BDF8),
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: profiles.map((p) {
              final selected = _activeProfile == p.$2;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _activeProfile = p.$2),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0x2838BDF8) : const Color(0xFF0B0F1A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: selected ? const Color(0xFF38BDF8) : const Color(0xFF1E293B)),
                    ),
                    child: Column(
                      children: [
                        Text(p.$1, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: selected ? const Color(0xFF38BDF8) : Colors.white)),
                        const SizedBox(height: 2),
                        Text(p.$3, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('zero_motion', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              Text('120Hz Physics & Morphing UI Engine', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8))),
            ],
          ),
        ),
        FilledButton.tonalIcon(
          onPressed: () => setState(() => _isTrayOpen = true),
          icon: const Icon(Icons.layers, size: 15),
          label: const Text('Sheet', style: TextStyle(fontSize: 11.5)),
        ),
        const SizedBox(width: 6),
        FilledButton.icon(
          onPressed: _paletteController.open,
          icon: const Icon(Icons.terminal, size: 15),
          label: const Text('⌘K', style: TextStyle(fontSize: 11.5)),
        ),
      ],
    );
  }

  Widget _featureCard({
    required IconData icon,
    required Color accent,
    required String title,
    required String subtitle,
    required String badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0xFF111726),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: accent, size: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: accent.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(6)),
                  child: Text(badge, style: TextStyle(color: accent, fontSize: 9.5, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
            const SizedBox(height: 3),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          ],
        ),
      ),
    );
  }

  Widget _buildTraySheet() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('FluidTray — Step $_trayStep', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => setState(() => _trayStep = _trayStep == 1 ? 2 : 1),
            child: const Text('Morph Sheet Height'),
          ),
        ],
      ),
    );
  }
}
