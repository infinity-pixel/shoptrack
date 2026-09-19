import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/data/session_merge.dart';
import '../models/shopping_session.dart';

class SyncReply {
  const SyncReply(this.value, this.conflicts, {this.revision = 0});
  final Json? value;
  final List<String> conflicts;
  final int revision;
}

class RemoteSessions {
  const RemoteSessions(
    this.changes, {
    required this.fromCache,
    this.revisions = const {},
  });
  final Map<String, Json?> changes;
  final bool fromCache;
  final Map<String, int> revisions;
}

abstract class SyncRemote {
  Stream<RemoteSessions> watch(String uid);
  Future<SyncReply> apply(String uid, Json operation);
  Future<List<SyncReply>> applyBatch(String uid, List<Json> operations);
}

class FirestoreSyncRemote implements SyncRemote {
  FirestoreSyncRemote(this.firestore);
  static const int _currentSessionSchema = 2;

  final FirebaseFirestore firestore;

  CollectionReference<Json> _sessions(String uid) =>
      firestore.collection('users').doc(uid).collection('sessions');

  Json? _read(Json? document) {
    if (document == null) return null;
    final schema = document['schema'];
    if (schema != 1 && schema != _currentSessionSchema) {
      throw const FormatException(
        'This cloud data requires a newer ShopTrack version',
      );
    }
    if (document['deleted'] == true) return null;
    final value = Map<String, dynamic>.from(document['session'] as Map);
    ShoppingSession.fromJson(value);
    return value;
  }

  @override
  Stream<RemoteSessions> watch(String uid) => _sessions(uid)
      .snapshots(includeMetadataChanges: true)
      .map(
        (snapshot) => RemoteSessions(
          {for (final doc in snapshot.docs) doc.id: _read(doc.data())},
          fromCache:
              snapshot.metadata.isFromCache ||
              snapshot.metadata.hasPendingWrites,
          revisions: {
            for (final doc in snapshot.docs)
              doc.id: doc.data()['revision'] as int? ?? 0,
          },
        ),
      );

  @override
  Future<SyncReply> apply(String uid, Json operation) async =>
      (await applyBatch(uid, [operation])).single;

  @override
  Future<List<SyncReply>> applyBatch(String uid, List<Json> operations) async {
    if (operations.isEmpty || operations.length > 10) {
      throw const FormatException('Unsupported sync batch size');
    }
    final docs = [
      for (final op in operations) _sessions(uid).doc(op['day'] as String),
    ];
    final receipts = [
      for (final op in operations)
        firestore
            .collection('users')
            .doc(uid)
            .collection('syncOperations')
            .doc(op['id'] as String),
    ];
    return firestore.runTransaction((transaction) async {
      // The receipt makes a retry after process death safe: an old request can
      // never overwrite a newer edit just because its acknowledgement was lost.
      final recorded = [for (final ref in receipts) await transaction.get(ref)];
      final snapshots = [for (final ref in docs) await transaction.get(ref)];
      final current = [
        for (final snapshot in snapshots) _read(snapshot.data()),
      ];
      final revisions = [
        for (final snapshot in snapshots)
          snapshot.data()?['revision'] as int? ?? 0,
      ];
      if (recorded.every((r) => r.exists)) {
        return [
          for (var i = 0; i < operations.length; i++)
            SyncReply(
              current[i],
              List<String>.from(
                recorded[i].data()!['conflicts'] as List? ?? [],
              ),
              revision: revisions[i],
            ),
        ];
      }
      if (recorded.any((r) => r.exists)) {
        throw const FormatException(
          'A partially recorded transfer needs review',
        );
      }
      final merges = [
        for (var i = 0; i < operations.length; i++)
          SessionMerge(
            operations[i]['base'] as Json?,
            operations[i]['value'] as Json?,
            current[i],
          ),
      ];
      final hasConflict = merges.any((merge) => merge.conflicts.isNotEmpty);
      final replies = <SyncReply>[];
      for (var i = 0; i < operations.length; i++) {
        final operation = operations[i];
        final merge = merges[i];
        final fields = hasConflict && merge.conflicts.isEmpty
            ? <String>['A related date changed during this transfer']
            : merge.conflicts;
        final result = hasConflict ? current[i] : merge.value;
        final changed = !hasConflict && !sameJson(result, current[i]);
        // Fail visibly before Firestore's document-size limit. Local data and the
        // queued operation remain intact and can still be exported.
        if (utf8.encode(jsonEncode(result)).length > 700 * 1024 ||
            utf8.encode(jsonEncode(operation)).length > 700 * 1024) {
          throw const FormatException(
            'This date is too large to sync. Export a backup and split it into smaller dates.',
          );
        }
        if (changed) {
          transaction.set(docs[i], {
            'schema': _currentSessionSchema,
            'deleted': result == null,
            'session': result,
            'revision': revisions[i] + 1,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        transaction.set(receipts[i], {
          'schema': 1,
          'day': operation['day'],
          'conflicts': fields,
          'completedAt': FieldValue.serverTimestamp(),
          if (hasConflict) 'proposed': operation['value'],
        });
        replies.add(
          SyncReply(
            result,
            fields,
            revision: changed ? revisions[i] + 1 : revisions[i],
          ),
        );
      }
      return replies;
    });
  }
}
