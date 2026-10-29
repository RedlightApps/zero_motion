import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_motion/zero_motion.dart';

void main() {
  group('Sütun 3: FluidTray & ScrimScaleHost Testleri', () {
    testWidgets('FluidTray içerik yüksekliği değiştiğinde overflow olmadan yayla büyür', (tester) async {
      var step = 1;
      final progressNotifier = ValueNotifier<double>(0.0);

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Stack(
                  children: [
                    ScrimScaleHost(
                      progressListenable: progressNotifier,
                      child: const Center(child: Text('Arka Plan Ekranı')),
                    ),
                    FluidTray(
                      progressNotifier: progressNotifier,
                      child: step == 1
                          ? SizedBox(
                              height: 140,
                              child: Center(
                                child: ElevatedButton(
                                  onPressed: () => setState(() => step = 2),
                                  child: const Text('Adım 2ye Geç'),
                                ),
                              ),
                            )
                          : const SizedBox(
                              height: 320,
                              child: Center(child: Text('Genişletilmiş Adım 2')),
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Adım 2ye Geç'), findsOneWidget);
      expect(progressNotifier.value, closeTo(1.0, 0.05));

      // Adım 2'ye geçildiğinde yükseklik 140 -> 320px olur, overflow olmamalı!
      await tester.tap(find.text('Adım 2ye Geç'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(tester.takeException(), isNull);

      await tester.pumpAndSettle();
      expect(find.text('Genişletilmiş Adım 2'), findsOneWidget);
    });
  });
}
