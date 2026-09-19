// Deliberate SDK test doubles only; production uses Firebase's implementations.
// ignore_for_file: subtype_of_sealed_class
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/core/data/session_merge.dart';
import 'package:shoptrack/models/shopping_item.dart';
import 'package:shoptrack/models/shopping_session.dart';
import 'package:shoptrack/services/firestore_sync_remote.dart';

// Contract fake: exercises the production adapter, rejects reads after writes,
// and commits staged writes only when the entire transaction succeeds.
class TestFirestore extends Fake implements FirebaseFirestore {
  final documents = <String, Json>{};
  @override
  CollectionReference<Json> collection(String path) => TestCollection(path);
  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> handler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async {
    final transaction = TestTransaction(documents);
    final result = await handler(transaction);
    documents.addAll(transaction.writes);
    return result;
  }
}

class TestCollection extends Fake implements CollectionReference<Json> {
  TestCollection(this.path);
  @override
  final String path;
  @override
  DocumentReference<Json> doc([String? path]) =>
      TestDocument('${this.path}/$path');
}

class TestDocument extends Fake implements DocumentReference<Json> {
  TestDocument(this.path);
  @override
  final String path;
  @override
  CollectionReference<Json> collection(String collectionPath) =>
      TestCollection('$path/$collectionPath');
}

class TestSnapshot<T extends Object?> extends Fake
    implements DocumentSnapshot<T> {
  TestSnapshot(this.value);
  final T? value;
  @override
  bool get exists => value != null;
  @override
  T? data() => value;
}

class TestTransaction extends Fake implements Transaction {
  TestTransaction(this.documents);
  final Map<String, Json> documents;
  final writes = <String, Json>{};
  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(
    DocumentReference<T> ref,
  ) async {
    if (writes.isNotEmpty) throw StateError('Read after write');
    return TestSnapshot<T>(documents[ref.path] as T?);
  }

  @override
  Transaction set<T>(DocumentReference<T> ref, T data, [SetOptions? options]) {
    writes[ref.path] = Map<String, dynamic>.from(data as Map);
    return this;
  }
}

Json record(String name, {int day = 15}) => ShoppingSession(
  id: 's$day',
  date: DateTime(2026, 9, day),
  items: [ShoppingItem(id: 'milk', name: name)],
).toJson();
Json operation(
  String id,
  Json? base,
  Json? value, {
  String day = '2026-09-15',
}) => {'id': id, 'day': day, 'base': base, 'value': value};
Json envelope(Json? value, int revision) => {
  'schema': 1,
  'deleted': value == null,
  'session': value,
  'revision': revision,
};

void main() {
  test(
    'Lost acknowledgement retry returns newer cloud record without replaying old write',
    () async {
      final db = TestFirestore();
      final remote = FirestoreSyncRemote(db);
      final first = operation('first', null, record('Milk'));
      expect((await remote.apply('alice', first)).revision, 1);
      expect(db.documents['users/alice/sessions/2026-09-15']!['schema'], 2);
      await remote.apply(
        'alice',
        operation('second', record('Milk'), record('Fresh Milk')),
      );
      final retry = await remote.apply('alice', first);
      expect(retry.revision, 2);
      expect(retry.value!['items'][0]['name'], 'Fresh Milk');
      expect(db.documents, hasLength(3));
    },
  );

  test(
    'Transfer conflict does not commit either date and preserves both proposals',
    () async {
      final db = TestFirestore();
      final remote = FirestoreSyncRemote(db);
      db.documents['users/alice/sessions/2026-09-16'] = envelope(
        record('Remote Milk', day: 16),
        4,
      );
      final replies = await remote.applyBatch('alice', [
        operation('destination', null, record('Milk')),
        operation('source', record('Milk', day: 16), null, day: '2026-09-16'),
      ]);
      expect(replies.every((r) => r.conflicts.isNotEmpty), isTrue);
      expect(
        db.documents.containsKey('users/alice/sessions/2026-09-15'),
        isFalse,
      );
      expect(db.documents['users/alice/sessions/2026-09-16']!['revision'], 4);
      expect(
        db.documents['users/alice/syncOperations/destination']!['proposed'],
        record('Milk'),
      );
    },
  );

  test(
    'Successful transfer commits both dates, uses tombstone, and is retry-safe',
    () async {
      final db = TestFirestore();
      final remote = FirestoreSyncRemote(db);
      db.documents['users/alice/sessions/2026-09-16'] = envelope(
        record('Milk', day: 16),
        1,
      );
      final ops = [
        operation('dest', null, record('Milk')),
        operation('source', record('Milk', day: 16), null, day: '2026-09-16'),
      ];
      final replies = await remote.applyBatch('alice', ops);
      expect(replies.every((r) => r.conflicts.isEmpty), isTrue);
      expect(
        db.documents['users/alice/sessions/2026-09-16']!['deleted'],
        isTrue,
      );
      expect(db.documents['users/alice/sessions/2026-09-15']!['revision'], 1);
      await remote.applyBatch('alice', ops);
      expect(db.documents['users/alice/sessions/2026-09-16']!['revision'], 2);
    },
  );

  test(
    'Unknown schema and oversized transfer fail without partial writes',
    () async {
      final db = TestFirestore();
      final remote = FirestoreSyncRemote(db);
      db.documents['users/alice/sessions/2026-09-15'] = {'schema': 99};
      await expectLater(
        remote.apply('alice', operation('x', null, record('Milk'))),
        throwsFormatException,
      );
      expect(db.documents, hasLength(1));
      db.documents.clear();
      await expectLater(
        remote.applyBatch('alice', [
          operation('small', null, record('Milk')),
          operation(
            'large',
            null,
            record('x' * (710 * 1024), day: 16),
            day: '2026-09-16',
          ),
        ]),
        throwsFormatException,
      );
      expect(db.documents, isEmpty);
    },
  );

  test('Receipts and session paths are scoped by Firebase uid', () async {
    final db = TestFirestore();
    final remote = FirestoreSyncRemote(db);
    await remote.apply(
      'alice',
      operation('same-id', null, record('Alice Milk')),
    );
    await remote.apply('bob', operation('same-id', null, record('Bob Milk')));
    expect(db.documents, hasLength(4));
    expect(
      db.documents['users/alice/sessions/2026-09-15']!['session']['items'][0]['name'],
      'Alice Milk',
    );
    expect(
      db.documents['users/bob/sessions/2026-09-15']!['session']['items'][0]['name'],
      'Bob Milk',
    );
  });

  test('Schema 2 round-trip preserves item currency', () async {
    final db = TestFirestore();
    final remote = FirestoreSyncRemote(db);
    final value = ShoppingSession(
      id: 'currency',
      date: DateTime(2026, 9, 15),
      items: const [
        ShoppingItem(
          id: 'coffee',
          name: 'Coffee',
          priceValue: 5,
          currencyCode: 'USD',
        ),
      ],
    ).toJson();

    final reply = await remote.apply(
      'alice',
      operation('currency', null, value),
    );
    expect(reply.value!['items'][0]['currencyCode'], 'USD');
    expect(db.documents['users/alice/sessions/2026-09-15']!['schema'], 2);
  });
}
