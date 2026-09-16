import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/core/widgets/shoptrack_navigation_bar.dart';

void main() {
  for (final reduced in [false, true]) {
    testWidgets(
      'Shared navigation swaps matched icons; reduced motion=$reduced',
      (tester) async {
        var index = 1;
        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(disableAnimations: reduced),
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
          find.byKey(const ValueKey('navigation-icon-0-outline')),
          findsOne,
        );
        expect(
          find.byKey(const ValueKey('navigation-icon-1-filled')),
          findsOne,
        );
        await tester.tap(find.text('Lists'));
        await tester.pumpAndSettle();
        expect(index, 0);
        expect(
          find.byKey(const ValueKey('navigation-icon-0-filled')),
          findsOne,
        );
        expect(
          find.byKey(const ValueKey('navigation-icon-1-outline')),
          findsOne,
        );
        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();
        expect(index, 2);
        expect(
          find.byKey(const ValueKey('navigation-icon-0-outline')),
          findsOne,
        );
        expect(
          find.byKey(const ValueKey('navigation-icon-2-filled')),
          findsOne,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
