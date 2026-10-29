import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_motion/zero_motion.dart';

void main() {
  group('Sütun 1: 120Hz Harmonik Yay Çözücü (SpringSolver & ZeroSpringBuilder)', () {
    test('Az sönümlü, kritik sönümlü ve aşırı sönümlü yaylar hedefe yakınsar', () {
      final underDamped = SpringSolver1D(
        initialValue: 0.0,
        profile: SpringProfile.bouncy,
      )..setTarget(100.0);

      final criticalDamped = SpringSolver1D(
        initialValue: 0.0,
        profile: SpringProfile.fromResponse(response: 0.35, dampingRatio: 1.0),
      )..setTarget(100.0);

      final overDamped = SpringSolver1D(
        initialValue: 0.0,
        profile: SpringProfile.fromResponse(response: 0.35, dampingRatio: 1.6),
      )..setTarget(100.0);

      // 120Hz (dt = 1/120 sn) adımlarla 3 saniye simüle et
      for (var i = 0; i < 360; i++) {
        underDamped.step(1.0 / 120.0);
        criticalDamped.step(1.0 / 120.0);
        overDamped.step(1.0 / 120.0);
      }

      expect(underDamped.isSettled, isTrue);
      expect(underDamped.position, closeTo(100.0, 0.05));
      expect(criticalDamped.isSettled, isTrue);
      expect(criticalDamped.position, closeTo(100.0, 0.05));
      expect(overDamped.isSettled, isTrue);
      expect(overDamped.position, closeTo(100.0, 0.05));
    });

    test('Hareket ortasında hedef değiştiğinde (Mid-Flight Retargeting) hız korunur', () {
      final solver = SpringSolver1D(
        initialValue: 0.0,
        profile: SpringProfile.fluid,
      )..setTarget(200.0);

      // 15 kare (125ms) ilerlet: yay hızlanmış olmalı
      for (var i = 0; i < 15; i++) {
        solver.step(1.0 / 120.0);
      }
      final midPos = solver.position;
      final midVel = solver.velocity;
      expect(midPos, greaterThan(10.0));
      expect(midVel, greaterThan(100.0));

      // Hedefi aniden ters yöne (-50.0) çevir: konum ve anlık hız sıfırlanmamalı!
      solver.setTarget(-50.0);
      expect(solver.position, equals(midPos));
      expect(solver.velocity, equals(midVel));

      // Bir sonraki 120Hz karede atalet nedeniyle pozitif hız azalarak devam eder
      solver.step(1.0 / 120.0);
      expect(solver.position, isNot(equals(-50.0)));
    });

    test('SpringSolver2D ve SpringRectSolver çok boyutlu geometriyi çözer', () {
      final rectSolver = SpringRectSolver(
        initialRect: const Rect.fromLTWH(10, 20, 100, 40),
        profile: SpringProfile.snappy,
      )..setTarget(const Rect.fromLTWH(40, 80, 320, 480));

      for (var i = 0; i < 240; i++) {
        rectSolver.step(1.0 / 120.0);
      }

      expect(rectSolver.isSettled, isTrue);
      expect(rectSolver.rect.left, closeTo(40.0, 0.1));
      expect(rectSolver.rect.top, closeTo(80.0, 0.1));
      expect(rectSolver.rect.width, closeTo(320.0, 0.1));
      expect(rectSolver.rect.height, closeTo(480.0, 0.1));
    });

    test('Rubber-band direnci sınır dışındaki değerleri logaritmik sönümler', () {
      final above = GestureSpringController.applyRubberBand(
        150.0,
        minBound: 0.0,
        maxBound: 100.0,
      );
      final below = GestureSpringController.applyRubberBand(
        -50.0,
        minBound: 0.0,
        maxBound: 100.0,
      );
      expect(above, greaterThan(100.0));
      expect(above, lessThan(150.0));
      expect(below, lessThan(0.0));
      expect(below, greaterThan(-50.0));
    });

    testWidgets('ZeroSpringBuilder hedef değiştiğinde widget ağacını yayla günceller', (tester) async {
      var target = 0.0;
      late StateSetter outerSetState;
      final recordedValues = <double>[];

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (context, setState) {
              outerSetState = setState;
              return ZeroSpringBuilder(
                value: target,
                profile: SpringProfile.snappy,
                builder: (context, val, vel, _) {
                  recordedValues.add(val);
                  return Text(val.toStringAsFixed(1));
                },
              );
            },
          ),
        ),
      );

      expect(find.text('0.0'), findsOneWidget);
      outerSetState(() => target = 100.0);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(recordedValues.last, greaterThan(0.0));
      expect(recordedValues.last, lessThan(100.0));

      await tester.pumpAndSettle();
      expect(find.text('100.0'), findsOneWidget);
    });
  });
}
