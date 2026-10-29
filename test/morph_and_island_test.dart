import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_motion/zero_motion.dart';

void main() {
  group('Sütun 2: MorphSurface & DynamicIslandCapsule Testleri', () {
    testWidgets('MorphSurface kapalı durumdan açık duruma yayla dönüşür ve geri kapanır', (tester) async {
      final controller = MorphSurfaceController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: MorphSurface(
                controller: controller,
                closedBuilder: (context, open) => GestureDetector(
                  onTap: open,
                  child: const SizedBox(
                    width: 140,
                    height: 48,
                    child: Center(child: Text('Hızlı İşlem')),
                  ),
                ),
                expandedBuilder: (context, close) => Column(
                  children: [
                    const Text('Detaylı Morph Paneli'),
                    ElevatedButton(onPressed: close, child: const Text('Kapat')),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Hızlı İşlem'), findsOneWidget);
      expect(controller.isExpanded, isFalse);

      await tester.tap(find.text('Hızlı İşlem'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(controller.isExpanded, isTrue);
      expect(find.text('Detaylı Morph Paneli'), findsOneWidget);

      await tester.pumpAndSettle();
      await tester.tap(find.text('Kapat'));
      await tester.pumpAndSettle();
      expect(controller.isExpanded, isFalse);
    });

    testWidgets('DynamicIslandCapsule compact ve expanded kipleri arasında yaylanır', (tester) async {
      var activeMode = DynamicIslandMode.compact;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Center(
                  child: DynamicIslandCapsule(
                    mode: activeMode,
                    onModeChanged: (next) => setState(() => activeMode = next),
                    compactBuilder: (_) => const Text('Canlı Yayın • 02:14'),
                    expandedBuilder: (_) => const Text('Tam Kontroller Açık'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Canlı Yayın • 02:14'), findsOneWidget);
      expect(activeMode, equals(DynamicIslandMode.compact));

      await tester.tap(find.byType(DynamicIslandCapsule));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(activeMode, equals(DynamicIslandMode.expanded));

      await tester.pumpAndSettle();
      expect(find.text('Tam Kontroller Açık'), findsOneWidget);
    });
  });
}
