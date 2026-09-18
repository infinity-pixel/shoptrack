import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoptrack/core/data/session_merge.dart';
import 'package:shoptrack/core/data/shopping_repository.dart';
import 'package:shoptrack/core/data/sync_store.dart';
import 'package:shoptrack/core/theme/theme_presets.dart';
import 'package:shoptrack/core/utils/shopping_session_actions.dart';
import 'package:shoptrack/features/home/presentation/pages/home_page.dart';
import 'package:shoptrack/features/home/presentation/widgets/shopping_item_tile.dart';
import 'package:shoptrack/models/shopping_item.dart';
import 'package:shoptrack/models/shopping_list_group.dart';
import 'package:shoptrack/models/shopping_session.dart';
import 'package:shoptrack/services/shopping_sync_service.dart';
import 'shopping_sync_test.dart' show MemoryRemote;

class FailingStore extends SyncStore {
  FailingStore(super.preferences, super.scope);
  bool fail = true;
  @override
  Future<void> save(String day, Json? base, Json? value) async {
    if (fail) throw StateError('Simulated local write failure');
    await super.save(day, base, value);
  }
}

final date = DateTime(2026, 9, 16);
const source = ShoppingListGroup.defaultId;
const family = ShoppingListGroup(
  id: 'family',
  name: 'Grandmother',
  position: 1,
);
const work = ShoppingListGroup(id: 'work', name: 'Work', position: 2);
const milk = ShoppingItem(
  id: 'milk',
  name: 'Milk',
  position: 2,
  quantity: '1.50',
  quantityValue: 1.5,
  priceValue: 125,
  shoppingUnit: ShoppingUnit.l,
  priceBasis: ShoppingUnit.l,
  pricingMode: PricingMode.unit,
  notes: 'Keep cold',
);
const rice = ShoppingItem(
  id: 'rice',
  name: 'Rice',
  position: 5,
  quantityValue: 3,
  priceValue: 300,
  isPurchased: true,
);
const soap = ShoppingItem(
  id: 'soap',
  name: 'Soap',
  listId: 'family',
  position: 9,
);
ShoppingSession seed() => ShoppingSession(
  id: 'today',
  date: date,
  lists: [ShoppingListGroup.defaultList, family, work],
  items: [milk, rice, soap],
);
ShoppingSession move(
  ShoppingSession session, {
  Set<String> ids = const {'milk', 'rice'},
  String from = source,
  String to = 'family',
}) => ShoppingSessionActions.move(
  session,
  sourceListId: from,
  destinationListId: to,
  ids: ids,
);

Future<SyncStore> createStore({String uid = 'alice'}) async {
  final store = SyncStore(await SharedPreferences.getInstance(), uid);
  await store.load(seed: [seed()]);
  return store;
}

void main() {
  Future<void> confirm(WidgetTester tester, String action) async {
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(TextButton, action),
      ),
    );
    await tester.pumpAndSettle();
  }

  test(
    'Move undo preserves later pricing but refuses changed placement or missing items',
    () {
      final moved = move(seed());
      final edited = moved.copyWith(
        items: [
          for (final item in moved.items)
            item.id == 'milk' ? item.copyWith(priceValue: 200) : item,
        ],
      );
      final restored = ShoppingSessionActions.undoMove(
        edited,
        originals: [milk, rice],
        moved: moved,
      );
      expect(restored.itemsForList(source), hasLength(2));
      expect(restored.items.firstWhere((i) => i.id == 'milk').priceValue, 200);
      expect(
        restored.items.firstWhere((i) => i.id == 'milk').position,
        milk.position,
      );
      for (final changed in [
        move(moved, from: family.id, to: work.id),
        moved.copyWith(items: [rice, soap]),
        moved.copyWith(lists: [family, work]),
      ]) {
        expect(
          () => ShoppingSessionActions.undoMove(
            changed,
            originals: [milk, rice],
            moved: moved,
          ),
          throwsStateError,
        );
      }
    },
  );
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LocalShoppingRepository.activeStore = null;
  });
  tearDown(() => LocalShoppingRepository.activeStore = null);

  test(
    'Move both ways preserves identity, pricing, purchase status, and date totals',
    () {
      final original = seed();
      final moved = move(original);
      expect(original.itemsForList(source), hasLength(2));
      expect(moved.itemsForList(source), isEmpty);
      expect(moved.itemsForList(family.id), hasLength(3));
      expect(moved.items.map((i) => i.id).toSet(), {'milk', 'rice', 'soap'});
      expect(moved.totalPurchasedAmount, original.totalPurchasedAmount);
      expect(moved.totalAmount, original.totalAmount);
      expect(moved.date, original.date);
      for (final item in [milk, rice]) {
        final result = moved.items.firstWhere((i) => i.id == item.id);
        final expected = item.toJson()
          ..remove('listId')
          ..remove('position');
        final actual = result.toJson()
          ..remove('listId')
          ..remove('position');
        expect(actual, expected);
      }
      expect(moved.items.firstWhere((i) => i.id == 'milk').position, 10);
      expect(moved.items.firstWhere((i) => i.id == 'rice').position, 11);
      expect(moved.items.firstWhere((i) => i.id == 'soap'), same(soap));
      final returned = move(moved, from: family.id, to: source);
      expect(returned.itemsForList(source).map((i) => i.id), ['milk', 'rice']);
      expect(returned.itemsForList(family.id).single.id, 'soap');
    },
  );

  test('Invalid destinations/selections fail without modifying records', () {
    for (final target in [source, 'missing']) {
      expect(() => move(seed(), to: target), throwsStateError);
    }
    for (final ids in [
      <String>{},
      {'soap'},
      {'milk', 'missing'},
    ]) {
      expect(() => move(seed(), ids: ids), throwsStateError);
    }
    final deleted = ShoppingSessionActions.delete(
      seed(),
      sourceListId: source,
      ids: {'rice'},
    );
    expect(deleted.items.map((i) => i.id), ['milk', 'soap']);
    expect(deleted.lists, hasLength(3));
  });

  test(
    'Moves merge independent remote edits but not conflicting placement changes',
    () {
      final base = seed();
      final local = move(base, ids: {'milk'});
      final renamed = base.copyWith(
        items: [
          milk.copyWith(name: 'Fresh Milk', isPurchased: true),
          rice,
          soap,
        ],
      );
      final merge = SessionMerge(
        base.toJson(),
        local.toJson(),
        renamed.toJson(),
      );
      expect(merge.conflicts, isEmpty);
      final result = ShoppingSession.fromJson(
        merge.value!,
      ).items.firstWhere((i) => i.id == 'milk');
      expect(result.name, 'Fresh Milk');
      expect(result.isPurchased, isTrue);
      expect(result.listId, family.id);
      expect(result.position, 10);
      for (final remote in [
        move(base, ids: {'milk'}, to: 'work'),
        base.copyWith(items: [milk.copyWith(position: 20), rice, soap]),
      ]) {
        expect(
          SessionMerge(
            base.toJson(),
            local.toJson(),
            remote.toJson(),
          ).conflicts,
          contains('Milk: list / position'),
        );
      }
      final removedList = base.copyWith(
        lists: [ShoppingListGroup.defaultList, work],
        items: [milk, rice],
      );
      expect(
        SessionMerge(
          base.toJson(),
          local.toJson(),
          removedList.toJson(),
        ).conflicts,
        isNotEmpty,
      );
      final removedItem = base.copyWith(items: [rice, soap]);
      expect(
        SessionMerge(
          base.toJson(),
          local.toJson(),
          removedItem.toJson(),
        ).conflicts,
        isNotEmpty,
      );
    },
  );

  test(
    'Offline move and delete survive restart with a single queued edit each',
    () async {
      final store = await createStore();
      await store.enableCloud();
      await store.acknowledge(store.pending.single, seed().toJson(), []);
      final repo = LocalShoppingRepository(store: store);
      await repo.saveSession(move(await repo.getSessionByDate(date)));
      expect(store.pending, hasLength(1));
      var restarted = await createStore();
      expect(restarted.sessions.single.itemsForList(source), isEmpty);
      expect(restarted.pending, hasLength(1));
      final repo2 = LocalShoppingRepository(store: restarted);
      await repo2.saveSession(
        ShoppingSessionActions.delete(
          await repo2.getSessionByDate(date),
          sourceListId: family.id,
          ids: {'milk', 'rice'},
        ),
      );
      restarted = await createStore();
      expect(restarted.sessions.single.items.single.id, 'soap');
      expect(restarted.pending, hasLength(2));
      final staleRepo = LocalShoppingRepository(store: restarted);
      await staleRepo.getSessionByDate(date);
      await restarted.closeForEdits();
      await expectLater(staleRepo.saveSession(seed()), throwsStateError);
    },
  );

  testWidgets(
    'Offline move uploads once on reconnect and reaches a second device',
    (tester) async {
      final identities = StreamController<String?>.broadcast();
      final remote = MemoryRemote();
      final sync = ShoppingSyncService.testing(
        currentUid: () => 'alice',
        identities: identities.stream,
        remote: remote,
      );
      await sync.start();
      final repo = LocalShoppingRepository();
      await repo.saveSession(seed());
      remote.emit('alice');
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(sync.store!.pending, isEmpty);
      remote.offline = true;
      await repo.saveSession(move(await repo.getSessionByDate(date)));
      await tester.pump(const Duration(seconds: 1));
      expect(sync.store!.pending, hasLength(1));
      expect(sync.store!.sessions.single.itemsForList(source), isEmpty);
      remote.offline = false;
      // The existing service backs off after a failed upload, then reconnects.
      await tester.pump(const Duration(seconds: 11));
      remote.emit('alice');
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(sync.store!.pending, isEmpty);
      final second = SyncStore(
        await SharedPreferences.getInstance(),
        'second-device',
      );
      await second.load();
      await second.receive(remote.accounts['alice']!);
      expect(second.sessions.single.itemsForList(family.id), hasLength(3));
      final writes = remote.writes;
      remote.emit('alice');
      await tester.pump(const Duration(seconds: 1));
      expect(remote.writes, writes);
      sync.dispose();
      second.dispose();
      await identities.close();
      await remote.close();
    },
  );

  Future<SyncStore> mount(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double scale = 1,
    SyncStore? initialStore,
    GlobalKey? previewKey,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = initialStore ?? await createStore();
    LocalShoppingRepository.activeStore = store;
    await tester.pumpWidget(
      RepaintBoundary(
        key: previewKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemePresets.darkPresets.values.first.toThemeData(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: HomePage(sessionDate: date),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return store;
  }

  for (final scale in [1.0, 1.3]) {
    testWidgets('Purchase flight fits compact tiles at text scale $scale', (
      tester,
    ) async {
      await mount(tester, size: const Size(320, 640), scale: scale);
      for (var toggle = 0; toggle < 2; toggle++) {
        final tile = tester
            .widgetList<ShoppingItemTile>(find.byType(ShoppingItemTile))
            .firstWhere((tile) => tile.item.id == milk.id);
        tile.onToggle();
        // Inspect intermediate frames; settling alone can miss overlay overflow.
        for (var frame = 0; frame < 30; frame++) {
          await tester.pump(const Duration(milliseconds: 50));
          expect(tester.takeException(), isNull);
        }
        await tester.pumpAndSettle();
      }
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('Long press, multi-select, move, delete, and undo', (
    tester,
  ) async {
    final store = await mount(tester);
    await tester.longPress(find.text('Milk'));
    await tester.pumpAndSettle();
    expect(find.text('1 Selected'), findsOneWidget);
    await tester.tap(find.byTooltip('Select All'));
    await tester.pumpAndSettle();
    expect(find.text('2 Selected'), findsOneWidget);
    expect(store.sessions.single.purchasedCount, 1);
    await tester.tap(find.text('Move'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Grandmother'));
    await tester.pumpAndSettle();
    expect(store.sessions.single.itemsForList(source), hasLength(2));
    await confirm(tester, 'Move');
    expect(store.sessions.single.itemsForList(source), isEmpty);
    final familyChip = find.widgetWithText(ChoiceChip, 'Grandmother');
    await tester.ensureVisible(familyChip);
    await tester.pumpAndSettle();
    await tester.tap(familyChip);
    await tester.pumpAndSettle();
    await tester.longPress(find.text('Milk'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(ListTile, ShoppingListGroup.defaultList.name),
    );
    await tester.pumpAndSettle();
    await confirm(tester, 'Move');
    expect(store.sessions.single.itemsForList(source).single.id, 'milk');
    await tester.drag(find.byType(ChoiceChip).first, const Offset(500, 0));
    await tester.pumpAndSettle();
    final sourceChip = find.widgetWithText(
      ChoiceChip,
      ShoppingListGroup.defaultList.name,
    );
    await tester.ensureVisible(sourceChip);
    await tester.pumpAndSettle();
    await tester.tap(sourceChip);
    await tester.pumpAndSettle();
    await tester.longPress(find.text('Milk'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await confirm(tester, 'Delete');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(store.sessions.single.items.map((i) => i.id), ['rice', 'soap']);
    expect(find.text('Undo'), findsOneWidget);
    tester.widget<SnackBarAction>(find.byType(SnackBarAction)).onPressed();
    await tester.pumpAndSettle();
    expect(store.sessions.single.items, hasLength(3));
    await tester.longPress(find.text('Milk'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await confirm(tester, 'Delete');
    expect(store.sessions.single.items.map((i) => i.id), ['rice', 'soap']);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'Remote destination deletion while selecting is preserved for review',
    (tester) async {
      final store = await mount(tester);
      await tester.longPress(find.text('Milk'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Move'));
      await tester.pumpAndSettle();
      await store.receive({
        sessionDay(date): seed()
            .copyWith(
              lists: [ShoppingListGroup.defaultList, work],
              items: [milk, rice],
            )
            .toJson(),
      });
      await tester.pump();
      await tester.tap(find.widgetWithText(ListTile, 'Grandmother'));
      await tester.pumpAndSettle();
      await confirm(tester, 'Move');
      expect(store.conflicts, hasLength(1));
      expect(store.sessions.single.itemsForList(source), hasLength(2));
      expect(find.textContaining('Both versions are kept'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final size in [const Size(320, 640), const Size(640, 360)]) {
    testWidgets('Selection and destination picker fit $size with larger text', (
      tester,
    ) async {
      await mount(tester, size: size, scale: 1.3);
      await tester.ensureVisible(find.text('Milk'));
      await tester.longPress(find.text('Milk'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester
            .widget<ShoppingItemTile>(find.byType(ShoppingItemTile).first)
            .selectionMode,
        isTrue,
      );
      await tester.tap(find.byTooltip('Move'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('1 Selected'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets(
    'Selecting a purchased item does not change purchase status or allow swipe deletion',
    (tester) async {
      final store = await mount(tester);
      await tester.longPress(find.text('Milk'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Rice'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rice'));
      await tester.pumpAndSettle();
      expect(find.text('2 Selected'), findsOneWidget);
      expect(store.sessions.single.purchasedCount, 1);
      final riceTile = find.widgetWithText(ShoppingItemTile, 'Rice');
      final dismissible = tester.widget<Dismissible>(
        find.descendant(of: riceTile, matching: find.byType(Dismissible)),
      );
      expect(dismissible.direction, DismissDirection.none);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('2 Selected'), findsNothing);
      expect(store.sessions.single.items, hasLength(3));
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Failed save keeps selection and originals, then retry succeeds',
    (tester) async {
      final store = FailingStore(
        await SharedPreferences.getInstance(),
        'alice',
      );
      await store.load(seed: [seed()]);
      await mount(tester, initialStore: store);
      await tester.longPress(find.text('Milk'));
      await tester.pumpAndSettle();
      Future<void> attempt() async {
        await tester.tap(find.text('Move'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ListTile, 'Grandmother'));
        await tester.pumpAndSettle();
        await confirm(tester, 'Move');
      }

      await attempt();
      expect(find.text('1 Selected'), findsOneWidget);
      expect(find.textContaining('Could not save this change'), findsOneWidget);
      expect(store.sessions.single.itemsForList(source), hasLength(2));
      store.fail = false;
      await attempt();
      expect(find.text('1 Selected'), findsNothing);
      expect(store.sessions.single.itemsForList(source).single.id, 'rice');
      expect(store.sessions.single.itemsForList(family.id), hasLength(2));
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('Cancel retains selection; confirmed move can be undone', (
    tester,
  ) async {
    final store = await mount(tester);
    await tester.longPress(find.text('Milk'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Select All'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await confirm(tester, 'Cancel');
    expect(find.text('2 Selected'), findsOneWidget);
    expect(store.sessions.single.items, hasLength(3));
    Future<void> chooseMove() async {
      await tester.tap(find.text('Move'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Grandmother'));
      await tester.pumpAndSettle();
    }

    await chooseMove();
    await confirm(tester, 'Cancel');
    expect(store.sessions.single.itemsForList(source), hasLength(2));
    await chooseMove();
    await confirm(tester, 'Move');
    expect(store.sessions.single.itemsForList(source), isEmpty);
    tester.widget<SnackBarAction>(find.byType(SnackBarAction)).onPressed();
    await tester.pumpAndSettle();
    expect(store.sessions.single.itemsForList(source), hasLength(2));
    expect(store.sessions.single.itemsForList(family.id).single.id, 'soap');
    expect(find.text('Move undone.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Explicit drag handle still reorders without entering selection', (
    tester,
  ) async {
    final store = SyncStore(await SharedPreferences.getInstance(), 'alice');
    await store.load(
      seed: [
        seed().copyWith(items: [milk, rice.copyWith(isPurchased: false), soap]),
      ],
    );
    await mount(tester, initialStore: store);
    final handle = find.descendant(
      of: find.widgetWithText(ShoppingItemTile, 'Milk'),
      matching: find.byType(ReorderableDragStartListener),
    );
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump();
    final target = tester.getRect(
      find.widgetWithText(ShoppingItemTile, 'Rice'),
    );
    // Move the whole dragged tile past the second tile, including its grab offset.
    await gesture.moveTo(
      Offset(tester.getCenter(handle).dx, target.bottom + 80),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.up();
    await tester.pumpAndSettle();
    final items = store.sessions.single.itemsForList(source)
      ..sort((a, b) => a.position.compareTo(b.position));
    expect(items.map((i) => i.id), ['rice', 'milk']);
    expect(find.text('1 Selected'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  const font = String.fromEnvironment('SHOPTRACK_PREVIEW_FONT');
  testWidgets('Render selection and destination picker', (tester) async {
    for (final name in ['Roboto', 'Ahem']) {
      await (FontLoader(name)..addFont(
            Future.value(ByteData.sublistView(File(font).readAsBytesSync())),
          ))
          .load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader('LibreBaskerville')
          ..addFont(rootBundle.load('assets/fonts/LibreBaskerville[wght].ttf')))
        .load();
    final key = GlobalKey();
    await mount(tester, previewKey: key);
    Future<void> capture(String name) async {
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          'build/sprint_18_2_$name.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      expect(tester.takeException(), isNull);
    }

    await tester.longPress(find.text('Milk'));
    await tester.pumpAndSettle();
    await capture('selection');
    await tester.tap(find.text('Move'));
    await tester.pumpAndSettle();
    await capture('destination');
    await tester.pumpWidget(const SizedBox());
  }, skip: font.isEmpty);
}
