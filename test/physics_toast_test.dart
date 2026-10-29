import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_motion/zero_motion.dart';

void main() {
  group('Sütun 4: PhysicsToastDeck (Sonner 3D Bildirim Destesi) Testleri', () {
    testWidgets('Bildirimler 3D yığınlanır, dokununca yelpaze gibi açılır ve temizlenir', (tester) async {
      final controller = PhysicsToastController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                PhysicsToastDeck(controller: controller),
              ],
            ),
          ),
        ),
      );

      controller
        ..show(
          title: 'İlk Bildirim',
          subtitle: 'Kuyruğa alındı',
          duration: Duration.zero,
        )
        ..show(
          title: 'İkinci Bildirim',
          subtitle: 'İşlem tamamlandı',
          type: PhysicsToastType.success,
          duration: Duration.zero,
        );

      await tester.pumpAndSettle();
      expect(controller.items.length, equals(2));
      expect(find.text('İkinci Bildirim'), findsOneWidget);
      expect(controller.isExpanded, isFalse);

      // Karta dokunarak desteyi yelpaze gibi aç
      await tester.tap(find.text('İkinci Bildirim'));
      await tester.pumpAndSettle();
      expect(controller.isExpanded, isTrue);
      expect(find.text(ZeroMotionDict.toastClearAll), findsOneWidget);

      // Tümünü temizle
      await tester.tap(find.text(ZeroMotionDict.toastClearAll));
      await tester.pumpAndSettle();
      expect(controller.items, isEmpty);
    });
  });
}
