import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/core/widgets/lists_navigation_icon.dart';
import 'package:shoptrack/core/widgets/shoptrack_navigation_bar.dart';

void main() {
  for (final reduced in [false, true]) {
    testWidgets('Shared navigation fills selection; reduced motion=$reduced', (
      tester,
    ) async {
      var index = 1;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
              child: Scaffold(
                bottomNavigationBar: ShopTrackNavigationBar(
                  currentIndex: index,
                  onTap: (value) => setState(() => index = value),
                ),
              ),
            ),
          ),
        ),
      );
      expect(
        tester
            .widget<ListsNavigationIcon>(find.byType(ListsNavigationIcon))
            .fill,
        0,
      );
      await tester.tap(find.text('Lists'));
      await tester.pumpAndSettle();
      expect(index, 0);
      expect(
        tester
            .widget<ListsNavigationIcon>(find.byType(ListsNavigationIcon))
            .fill,
        1,
      );
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(index, 2);
      expect(
        tester
            .widget<ListsNavigationIcon>(find.byType(ListsNavigationIcon))
            .fill,
        0,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
