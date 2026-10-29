import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zero_motion/zero_motion.dart';

void main() {
  group('Sütun 5: FuzzyCommandScorer & CommandPaletteHost Testleri', () {
    test('FuzzyCommandScorer kelime başı ve ardışık harf eşleşmelerini en üste sıralar', () {
      const actions = <ZeroCommandAction>[
        ZeroCommandAction(id: '1', title: 'Profil Ayarlarını Kaydet'),
        ZeroCommandAction(id: '2', title: 'Paket Yayınla'),
        ZeroCommandAction(id: '3', title: 'Karanlık Tema Değiştir'),
      ];

      final matches = FuzzyCommandScorer.filterAndSort(actions, 'py');
      expect(matches, isNotEmpty);
      // 'Paket Yayınla' -> 'P' (0. indeks) ve 'Y' (kelime başı, 6. indeks) en yüksek puanı alır!
      expect(matches.first.action.id, equals('2'));
      expect(matches.first.matchedTitleIndices, containsAll(<int>[0, 6]));
    });

    testWidgets('CommandPaletteHost açılır, bulanık arama yapar ve alt menüye girer', (tester) async {
      final controller = CommandPaletteController();
      var executedLeaf = false;

      await tester.pumpWidget(
        MaterialApp(
          home: CommandPaletteHost(
            controller: controller,
            actions: [
              ZeroCommandAction(
                id: 'theme',
                title: 'Tema Ayarları',
                children: [
                  ZeroCommandAction(
                    id: 'dark',
                    title: 'Gece Kipini Etkinleştir',
                    onSelected: () => executedLeaf = true,
                  ),
                ],
              ),
              const ZeroCommandAction(id: 'help', title: 'Yardım Merkezi'),
            ],
            child: const Scaffold(body: Center(child: Text('Ana Sayfa'))),
          ),
        ),
      );

      controller.open();
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);

      // 'Tema Ayarları' satırında Enter'a bas -> alt menüye (breadcrumb) geçmeli
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Tema Ayarları'), findsOneWidget); // Breadcrumb rozeti

      // Alt menüdeki 'Gece Kipini Etkinleştir' öğesini Enter ile çalıştır
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(executedLeaf, isTrue);
      expect(controller.isOpen, isFalse);
    });
  });
}
