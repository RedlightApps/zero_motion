import 'package:flutter_test/flutter_test.dart';
import 'package:zero_motion_example/main.dart';

void main() {
  testWidgets('ZeroMotionShowcaseApp 5 sütunu sorunsuz başlatır', (tester) async {
    await tester.pumpWidget(const ZeroMotionShowcaseApp());
    expect(find.text('Zero Motion'), findsOneWidget);
    expect(find.text('In-Place MorphSurface Aç'), findsOneWidget);
    expect(find.text('3D Bildirim Ekle'), findsOneWidget);
  });
}
