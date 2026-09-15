import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoptrack/core/data/session_merge.dart';
import 'package:shoptrack/core/data/shopping_repository.dart';
import 'package:shoptrack/core/data/sync_store.dart';
import 'package:shoptrack/core/theme/theme_presets.dart';
import 'package:shoptrack/features/account/presentation/pages/cloud_sync_page.dart';
import 'package:shoptrack/features/home/presentation/pages/home_page.dart';
import 'package:shoptrack/models/shopping_item.dart';
import 'package:shoptrack/models/shopping_list_group.dart';
import 'package:shoptrack/models/shopping_session.dart';
import 'package:shoptrack/services/firestore_sync_remote.dart';
import 'package:shoptrack/services/shopping_sync_service.dart';

final date = DateTime(2026, 9, 15);
const milk = ShoppingItem(
  id: 'milk',
  name: 'Milk',
  quantityValue: 2,
  priceValue: 100,
);
ShoppingSession session([List<ShoppingItem> items = const [milk]]) =>
    ShoppingSession(id: 'session', date: date, items: items);

class MemoryRemote implements SyncRemote {
  final streams = <String, StreamController<RemoteSessions>>{};
  final accounts = <String, Map<String, Json?>>{};
  final receipts = <String, SyncReply>{};
  bool offline = false;
  Completer<void>? hold;
  int writes = 0;

  @override
  Stream<RemoteSessions> watch(String uid) {
    final stream = streams.putIfAbsent(uid, () => StreamController.broadcast());
    return stream.stream;
  }

  void emit(String uid, {bool cached = false}) => streams[uid]!.add(
    RemoteSessions(Map.from(accounts[uid] ?? {}), fromCache: cached),
  );

  @override
  Future<SyncReply> apply(String uid, Json op) async {
    await hold?.future;
    if (offline) throw StateError('offline');
    final key = '$uid/${op['id']}';
    final all = accounts.putIfAbsent(uid, () => {});
    if (receipts.containsKey(key)) return receipts[key]!;
    final merge = SessionMerge(
      op['base'] as Json?,
      op['value'] as Json?,
      all[op['day']],
    );
    if (merge.conflicts.isEmpty) {
      all[op['day'] as String] = merge.value;
      writes++;
    }
    return receipts[key] = SyncReply(all[op['day']], merge.conflicts);
  }

  Future<void> close() async {
    for (final stream in streams.values) {
      await stream.close();
    }
  }

  @override
  Future<List<SyncReply>> applyBatch(String uid, List<Json> operations) async =>
      [for (final op in operations) await apply(uid, op)];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LocalShoppingRepository.activeStore = null;
  });
  tearDown(() => LocalShoppingRepository.activeStore = null);

  Future<SyncStore> store(
    String uid, {
    List<ShoppingSession> seed = const [],
  }) async {
    final result = SyncStore(await SharedPreferences.getInstance(), uid);
    await result.load(seed: seed);
    return result;
  }

  testWidgets(
    'Open item editor keeps its original baseline when a remote edit arrives',
    (tester) async {
      final local = await store('alice', seed: [session()]);
      LocalShoppingRepository.activeStore = local;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemePresets.lightPresets.values.first.toThemeData(),
          home: HomePage(sessionDate: date),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Milk').first);
      await tester.pumpAndSettle();
      final name = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Item Name',
      );
      expect(name, findsOneWidget);
      await tester.enterText(name, 'My Milk');
      await local.receive({
        sessionDay(date): session([milk.copyWith(name: 'Their Milk')]).toJson(),
      });
      await tester.pump();
      expect(find.text('My Milk'), findsOneWidget);
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(local.conflicts, hasLength(1));
      expect(local.sessions.single.items.single.name, 'Their Milk');
      expect(local.conflicts.single['value']['items'][0]['name'], 'My Milk');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  test(
    'Independent item additions merge during first upload of existing history',
    () {
      final local = session([milk]).toJson();
      final remote = session([
        const ShoppingItem(id: 'eggs', name: 'Eggs'),
      ]).toJson();
      final merged = SessionMerge(null, local, remote);
      expect(merged.conflicts, isEmpty);
      expect((merged.value!['items'] as List).length, 2);
    },
  );

  test('Independent fields merge; price/quantity form an atomic group', () {
    final base = session().toJson();
    final local = session([milk.copyWith(isPurchased: true)]).toJson();
    final remote = session([milk.copyWith(name: 'Fresh Milk')]).toJson();
    final merged = SessionMerge(base, local, remote);
    expect(merged.conflicts, isEmpty);
    final item = ShoppingSession.fromJson(merged.value!).items.single;
    expect(item.name, 'Fresh Milk');
    expect(item.isPurchased, isTrue);
    final priceConflict = SessionMerge(
      base,
      session([milk.copyWith(priceValue: 200)]).toJson(),
      session([milk.copyWith(quantityValue: 4)]).toJson(),
    );
    expect(priceConflict.conflicts, contains('Milk: quantity / price'));
  });

  test(
    'Deletion versus edit is surfaced; stale edit cannot silently resurrect a date',
    () {
      final base = session().toJson();
      final edited = session([milk.copyWith(name: 'Updated')]).toJson();
      expect(SessionMerge(base, edited, null).conflicts, isNotEmpty);
      expect(SessionMerge(base, null, edited).conflicts, isNotEmpty);
      expect(SessionMerge(base, base, null).value, isNull);
    },
  );

  test(
    'Concurrent list deletion cannot hide an item added on another device',
    () {
      const list = ShoppingListGroup(id: 'family', name: 'Family', position: 1);
      final base = session(
        [],
      ).copyWith(lists: [ShoppingListGroup.defaultList, list]);
      final local = base.copyWith(items: [milk.copyWith(listId: list.id)]);
      final remote = base.copyWith(lists: [ShoppingListGroup.defaultList]);
      final merged = SessionMerge(
        base.toJson(),
        local.toJson(),
        remote.toJson(),
      );
      expect(merged.conflicts, isNotEmpty);
      final preview = ShoppingSession.fromJson(merged.value!);
      expect(preview.lists.any((l) => l.id == list.id), isTrue);
      expect(preview.itemsForList(list.id), hasLength(1));
    },
  );

  test(
    'A transfer conflict is acknowledged and resolved for both dates together',
    () async {
      final local = await store('alice', seed: [session()]);
      await local.enableCloud();
      await local.acknowledge(local.pending.single, session().toJson(), []);
      final future = date.add(const Duration(days: 1));
      final repo = LocalShoppingRepository(store: local);
      final source = await repo.getSessionByDate(date);
      final target = await repo.getSessionByDate(future);
      await repo.saveSessions([
        target.copyWith(items: [milk]),
        source.copyWith(items: []),
      ]);
      final ops = local.pending;
      expect(ops[0]['batchId'], ops[1]['batchId']);
      await local.acknowledgeBatch([
        {
          'operation': ops[0],
          'remote': null,
          'fields': ['Related date changed'],
          'revision': 1,
        },
        {
          'operation': ops[1],
          'remote': session().toJson(),
          'fields': ['Milk changed'],
          'revision': 1,
        },
      ]);
      expect(local.pending, isEmpty);
      expect(local.conflicts, hasLength(2));
      await local.resolve(ops[0]['id'] as String, useLocal: true);
      expect(local.conflicts, isEmpty);
      expect(local.pending, hasLength(2));
      expect(local.pending[0]['batchId'], local.pending[1]['batchId']);
      expect(local.sessions.expand((s) => s.items), hasLength(1));
    },
  );

  test(
    'Offline edits and pending queue survive restart in one envelope',
    () async {
      final first = await store('alice', seed: [session()]);
      await first.enableCloud();
      final repo = LocalShoppingRepository(store: first);
      final read = await repo.getSessionByDate(date);
      await repo.saveSession(
        read.copyWith(items: [milk.copyWith(isPurchased: true)]),
      );
      final restarted = await store('alice');
      expect(restarted.sessions.single.items.single.isPurchased, isTrue);
      expect(restarted.pending, hasLength(2));
      expect((await store('bob')).sessions, isEmpty);
    },
  );

  test(
    'Parallel saves from separate repository instances preserve both dates',
    () async {
      final local = await store('alice');
      final one = LocalShoppingRepository(store: local);
      final two = LocalShoppingRepository(store: local);
      await Future.wait([
        one.saveSession(session()),
        two.saveSession(
          session().copyWith(
            id: 'tomorrow',
            date: date.add(const Duration(days: 1)),
          ),
        ),
      ]);
      expect(local.sessions, hasLength(2));
      expect((await store('alice')).sessions, hasLength(2));
    },
  );

  test('Stale page save keeps unrelated remote item additions', () async {
    final local = await store('alice', seed: [session()]);
    final repo = LocalShoppingRepository(store: local);
    final old = await repo.getSessionByDate(date);
    await local.receive({
      sessionDay(date): session([
        milk,
        const ShoppingItem(id: 'e', name: 'Eggs'),
      ]).toJson(),
    });
    await repo.saveSession(
      old.copyWith(items: [milk.copyWith(isPurchased: true)]),
    );
    expect(local.sessions.single.items, hasLength(2));
    expect(
      local.sessions.single.items.firstWhere((i) => i.id == 'milk').isPurchased,
      isTrue,
    );
  });

  test(
    'Snapshot and delayed acknowledgement cannot discard an in-flight edit',
    () async {
      final local = await store('alice', seed: [session()]);
      await local.enableCloud();
      final original = local.pending.first;
      final repo = LocalShoppingRepository(store: local);
      final old = await repo.getSessionByDate(date);
      await repo.saveSession(
        old.copyWith(items: [milk.copyWith(isPurchased: true)]),
      );
      final newer = session([milk.copyWith(name: 'Remote Name')]).toJson();
      await local.receive(
        {sessionDay(date): newer},
        revisions: {sessionDay(date): 2},
      );
      await local.acknowledge(original, session().toJson(), [], revision: 1);
      final item = local.sessions.single.items.single;
      expect(item.isPurchased, isTrue);
      expect(item.name, 'Remote Name');
      expect(local.pending, hasLength(1));
    },
  );

  test(
    'Conflict retains both values across restart and explicit choice queues a new edit',
    () async {
      final local = await store('alice', seed: [session()]);
      await local.enableCloud();
      final op = local.pending.single;
      final other = session([milk.copyWith(name: 'Cloud Milk')]).toJson();
      await local.acknowledge(op, other, ['Milk: name']);
      final restarted = await store('alice');
      expect(restarted.conflicts, hasLength(1));
      expect(restarted.sessions.single.items.single.name, 'Cloud Milk');
      await restarted.resolve(op['id'] as String, useLocal: true);
      expect(restarted.pending, hasLength(1));
      expect(restarted.conflicts, isEmpty);
      expect(restarted.sessions.single.items.single.name, 'Milk');
    },
  );

  test(
    'Moving an item writes both local dates atomically and queues destination first',
    () async {
      final future = date.add(const Duration(days: 1));
      final local = await store(
        'alice',
        seed: [session().copyWith(date: future)],
      );
      await local.enableCloud();
      await local.acknowledge(
        local.pending.single,
        local.sessions.single.toJson(),
        [],
      );
      final repo = LocalShoppingRepository(store: local);
      final source = await repo.getSessionByDate(future);
      final target = await repo.getSessionByDate(date);
      await repo.saveSessions([
        target.copyWith(items: [milk.copyWith(isPurchased: true)]),
        source.copyWith(items: []),
      ]);
      final restarted = await store('alice');
      expect(restarted.sessions.expand((s) => s.items), hasLength(1));
      expect(restarted.pending.first['day'], sessionDay(date));
    },
  );

  test('Closed account rejects delayed editor writes', () async {
    final alice = await store('alice', seed: [session()]);
    final repo = LocalShoppingRepository(store: alice);
    final old = await repo.getSessionByDate(date);
    await alice.closeForEdits();
    final bob = await store('bob');
    LocalShoppingRepository.activeStore = bob;
    await expectLater(repo.saveSession(old), throwsStateError);
    expect(bob.sessions, isEmpty);
    expect(alice.sessions, hasLength(1));
  });

  test(
    'Malformed existing storage is not replaced with an empty history',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('shoptrack_sync_v1_alice', '{broken');
      await expectLater(store('alice'), throwsFormatException);
      expect(prefs.getString('shoptrack_sync_v1_alice'), '{broken');
    },
  );

  testWidgets(
    'First login migrates once, syncs, signs out offline, and isolates another account',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'shopping_sessions': jsonEncode([session().toJson()]),
      });
      String? uid = 'alice';
      final identities = StreamController<String?>.broadcast();
      final remote = MemoryRemote();
      final sync = ShoppingSyncService.testing(
        currentUid: () => uid,
        identities: identities.stream,
        remote: remote,
      );
      await sync.start();
      expect(sync.store!.sessions, hasLength(1));
      remote.emit('alice');
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(sync.status, ShoppingSyncState.saved);
      expect(remote.accounts['alice']!.length, 1);
      uid = null;
      identities.add(null);
      await tester.pump();
      await tester.pump();
      expect(sync.store!.sessions, hasLength(1));
      final signedOutRepo = LocalShoppingRepository();
      final old = await signedOutRepo.getSessionByDate(date);
      await signedOutRepo.saveSession(
        old.copyWith(items: [milk.copyWith(isPurchased: true)]),
      );
      expect(sync.status, ShoppingSyncState.deviceOnly);
      uid = 'bob';
      identities.add(uid);
      await tester.pump();
      await tester.pump();
      expect(sync.store!.scope, 'bob');
      expect(sync.store!.sessions, isEmpty);
      uid = 'alice';
      identities.add(uid);
      await tester.pump();
      await tester.pump();
      expect(sync.store!.sessions.single.items.single.isPurchased, isTrue);
      expect(sync.store!.pending, hasLength(1));
      expect(
        (await SharedPreferences.getInstance()).getString('shopping_sessions'),
        isNotNull,
      );
      sync.dispose();
      await identities.close();
      await remote.close();
    },
  );

  testWidgets(
    'Cached snapshot cannot mark a new account synced or overwrite local edits',
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
      await repo.saveSession(session());
      remote.emit('alice', cached: true);
      await tester.pump(const Duration(seconds: 1));
      expect(sync.status, ShoppingSyncState.deviceOnly);
      expect(remote.writes, 0);
      expect(sync.store!.sessions, hasLength(1));
      remote.emit('alice');
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(sync.status, ShoppingSyncState.saved);
      sync.dispose();
      await identities.close();
      await remote.close();
    },
  );

  testWidgets(
    'Reconnect keeps editors mounted; delayed upload stays in its original account',
    (tester) async {
      String? uid = 'alice';
      final identities = StreamController<String?>.broadcast();
      final remote = MemoryRemote();
      final sync = ShoppingSyncService.testing(
        currentUid: () => uid,
        identities: identities.stream,
        remote: remote,
      );
      await sync.start();
      var switchedDuringRetry = false;
      sync.addListener(() {
        if (sync.switching) switchedDuringRetry = true;
      });
      await sync.retry();
      expect(switchedDuringRetry, isFalse);
      final originalStore = sync.store!;
      await LocalShoppingRepository().saveSession(session());
      remote.hold = Completer<void>();
      remote.emit('alice');
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      uid = 'bob';
      identities.add(uid);
      await tester.pump();
      await tester.pump();
      expect(sync.store!.scope, 'bob');
      remote.hold!.complete();
      await tester.pump();
      await tester.pump();
      expect(sync.store!.sessions, isEmpty);
      expect(originalStore.pending, isEmpty);
      uid = 'alice';
      identities.add(uid);
      await tester.pump();
      await tester.pump();
      expect(identical(sync.store, originalStore), isTrue);
      expect(sync.store!.sessions, hasLength(1));
      sync.dispose();
      await identities.close();
      await remote.close();
    },
  );

  testWidgets('Sync review page fits a narrow screen and large text', (
    tester,
  ) async {
    tester.view.resetPhysicalSize();
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final identities = StreamController<String?>.broadcast();
    final remote = MemoryRemote();
    final sync = ShoppingSyncService.testing(
      currentUid: () => null,
      identities: identities.stream,
      remote: remote,
    );
    await sync.start();
    await sync.store!.enableCloud();
    await LocalShoppingRepository().saveSession(session());
    final op = sync.store!.pending.single;
    await sync.store!.acknowledge(
      op,
      session([milk.copyWith(name: 'Cloud Milk')]).toJson(),
      ['Milk: name'],
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemePresets.lightPresets.values.first.toThemeData(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.4)),
          child: child!,
        ),
        home: CloudSyncPage(service: sync),
      ),
    );
    await tester.pump();
    expect(find.text('Sync Needs Attention'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Use My Changes'), 220);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    sync.dispose();
    await identities.close();
    await remote.close();
  });
}
