import 'package:flutter_test/flutter_test.dart';
import 'package:zero_motion_example/main.dart';

void main() {
  testWidgets('ZeroMotionShowcaseApp renders expanded Dynamic Island and Bento cards', (tester) async {
    await tester.pumpWidget(const ZeroMotionShowcaseApp());
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('zero_motion'), findsOneWidget);
    expect(find.text('MorphSurface'), findsOneWidget);
  });
}
