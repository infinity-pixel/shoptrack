import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../core/data/shopping_repository.dart';
import '../core/data/sync_store.dart';
import '../models/shopping_item.dart';
import '../models/shopping_session.dart';
import 'firestore_sync_remote.dart';

enum ShoppingSyncState { deviceOnly, saving, saved, attention }

/// Owns the one active local account and one authenticated Firestore listener.
/// Repository instances keep their original store, including after sign-out or
/// an account change, so a delayed editor cannot write into another account.
class ShoppingSyncService extends ChangeNotifier with WidgetsBindingObserver {
  ShoppingSyncService({required FirebaseAuth auth, required this.remote})
    : currentUid = (() => auth.currentUser?.uid),
      identities = auth.authStateChanges().map((u) => u?.uid);

  @visibleForTesting
  ShoppingSyncService.testing({
    required this.currentUid,
    required this.identities,
    required this.remote,
  });
  final String? Function() currentUid;
  final Stream<String?> identities;
  final SyncRemote remote;
  SyncStore? store;
  final Map<String, SyncStore> _stores = {};
  bool ready = false;
  bool switching = false;
  bool _disposed = false;
  bool _serverSeen = false;
  bool _busy = false;
  String? _uid;
  String? error;
  DateTime? lastSaved;
  StreamSubscription<String?>? _authListener;
  StreamSubscription<RemoteSessions>? _remoteListener;
  Timer? _retry;
  Future<void> _switchTail = Future.value();
  int _generation = 0;
  int _failures = 0;

  ShoppingSyncState get status {
    if (error != null ||
        store?.storageError != null ||
        (store?.conflicts.isNotEmpty ?? false)) {
      return ShoppingSyncState.attention;
    }
    if (_uid == null || !_serverSeen) return ShoppingSyncState.deviceOnly;
    if (_busy || (store?.pending.isNotEmpty ?? false)) {
      return ShoppingSyncState.saving;
    }
    return ShoppingSyncState.saved;
  }

  String get statusLabel => switch (status) {
    ShoppingSyncState.deviceOnly => 'Saved on This Device',
    ShoppingSyncState.saving => 'Saving Changes',
    ShoppingSyncState.saved => 'All Changes Saved',
    ShoppingSyncState.attention => 'Sync Needs Attention',
  };

  String get explanation {
    if (store?.storageError != null) {
      return 'A local save failed. Keep the app open and try again.';
    }
    if (error != null) return error!;
    if (store?.conflicts.isNotEmpty ?? false) {
      return 'Some edits need your review. Both versions have been kept.';
    }
    if (_uid == null) {
      return 'Sign in to sync. These lists stay with their original account.';
    }
    if (!_serverSeen) {
      return 'Waiting for the cloud. Changes will upload automatically when a connection is available.';
    }
    return 'Your shopping lists and history sync automatically while ShopTrack is open.';
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> start() async {
    WidgetsBinding.instance.addObserver(this);
    try {
      final prefs = await SharedPreferences.getInstance();
      final scope = prefs.getString('shoptrack_last_scope') ?? 'guest';
      final initial = SyncStore(prefs, scope);
      if (scope != 'guest' && !prefs.containsKey(initial.storageKey)) {
        throw const FormatException('Account storage is missing');
      }
      final seed = prefs.containsKey(initial.storageKey)
          ? <ShoppingSession>[]
          : _legacy(prefs);
      await initial.load(seed: seed);
      if (_disposed) return;
      store = initial;
      _stores[scope] = initial;
      LocalShoppingRepository.activeStore = initial;
      initial.addListener(_localChanged);
      await _switch(currentUid());
      if (_disposed) return;
      ready = true;
      _authListener = identities.listen(
        (uid) {
          _switchTail = _switchTail.then((_) => _switch(uid)).catchError((
            Object e,
          ) {
            error =
                'Could not open this account’s data. Please restart ShopTrack.';
            switching = false;
            ready = false;
            _notify();
          });
        },
        onError: (Object e) {
          error = 'Please sign in again to reconnect your cloud data.';
          _notify();
        },
      );
      _notify();
    } catch (e) {
      error =
          'Saved shopping data could not be opened. Your existing data has been kept. Please restart ShopTrack.';
      _notify();
    }
  }

  List<ShoppingSession> _legacy(SharedPreferences prefs) {
    final raw = prefs.getString('shopping_sessions');
    final sessions = raw == null
        ? <ShoppingSession>[]
        : (jsonDecode(raw) as List)
              .map(
                (s) => ShoppingSession.fromJson(
                  Map<String, dynamic>.from(s as Map),
                ),
              )
              .toList();
    final items = prefs.getString('shopping_items');
    if (items != null) {
      final now = DateTime.now();
      sessions.add(
        ShoppingSession(
          id: const Uuid().v4(),
          date: DateTime(now.year, now.month, now.day),
          items: (jsonDecode(items) as List)
              .map(
                (i) =>
                    ShoppingItem.fromJson(Map<String, dynamic>.from(i as Map)),
              )
              .toList(),
        ),
      );
    }
    // Original preference keys are intentionally preserved as migration backup.
    return sessions;
  }

  Future<void> _switch(String? uid) async {
    if (_disposed ||
        (_uid == uid && (uid == null || _remoteListener != null))) {
      return;
    }
    // Reconnecting on resume must not unmount an open editor or keyboard.
    switching = uid != null && store!.scope != uid;
    final generation = ++_generation;
    _retry?.cancel();
    // Generation checks invalidate callbacks immediately. Native listener
    // cleanup must not delay sign-out or keep the old account active.
    unawaited(_remoteListener?.cancel());
    _remoteListener = null;
    _uid = uid;
    _serverSeen = false;
    _busy = false;
    error = null;
    _notify();
    if (uid != null) {
      final prefs = await SharedPreferences.getInstance();
      final owner = prefs.getString('shoptrack_migration_owner');
      if (owner == null &&
          !await prefs.setString('shoptrack_migration_owner', uid)) {
        throw StateError('Could not save data ownership');
      }
      if (store!.scope != uid) {
        await store!.closeForEdits();
        final next = _stores[uid] ?? SyncStore(prefs, uid);
        if (!_stores.containsKey(uid)) {
          await next.load(
            seed: owner == null || owner == uid
                ? (store!.scope == 'guest'
                      ? store!.sessions
                      : <ShoppingSession>[])
                : <ShoppingSession>[],
          );
        }
        _stores[uid] = next;
        if (!await prefs.setString('shoptrack_last_scope', uid)) {
          throw StateError('Could not save active account');
        }
        store!.removeListener(_localChanged);
        store = next;
        next.reopenForEdits();
        LocalShoppingRepository.activeStore = next;
        next.addListener(_localChanged);
      }
      await store!.enableCloud();
      final active = store!;
      _remoteListener = remote
          .watch(uid)
          .listen(
            (event) async {
              if (_disposed || generation != _generation) return;
              try {
                // Cache is not proof that the cloud is current. Local persisted state
                // already covers offline startup, so only ingest confirmed snapshots.
                if (event.fromCache) {
                  _serverSeen = false;
                  _notify();
                  return;
                }
                _serverSeen = true;
                await active.receive(event.changes, revisions: event.revisions);
                if (generation != _generation || _disposed) return;
                error = null;
                _schedule();
                _notify();
              } catch (e) {
                error =
                    'Cloud data could not be read. Local changes have been kept.';
                _notify();
              }
            },
            onError: (Object e) {
              if (generation != _generation || _disposed) return;
              _serverSeen = false;
              error =
                  'Could not access cloud data. Check your connection and sign-in, then retry.';
              _retry?.cancel();
              _retry = Timer(const Duration(seconds: 30), retry);
              _notify();
            },
          );
    }
    switching = false;
    _schedule();
    _notify();
  }

  void _localChanged() {
    _schedule();
    _notify();
  }

  void _schedule() {
    if (_disposed ||
        _busy ||
        _uid == null ||
        !_serverSeen ||
        (store?.pending.isEmpty ?? true) ||
        (_retry?.isActive ?? false)) {
      return;
    }
    _retry = Timer(const Duration(milliseconds: 600), _flush);
  }

  Future<void> _flush() async {
    if (_disposed || _busy || _uid == null || !_serverSeen) return;
    final uid = _uid!;
    final active = store!;
    final generation = _generation;
    _busy = true;
    _notify();
    try {
      while (!_disposed &&
          generation == _generation &&
          active.pending.isNotEmpty) {
        // Never use remembered email or Google provider id for ownership.
        if (currentUid() != uid) break;
        final op = active.pending.first;
        final batch = op['batchId'] == null
            ? [op]
            : active.pending
                  .takeWhile((entry) => entry['batchId'] == op['batchId'])
                  .toList();
        final replies = batch.length == 1
            ? [await remote.apply(uid, op)]
            : await remote.applyBatch(uid, batch);
        if (_disposed) return;
        // A completed old request belongs to its original local store only.
        await active.acknowledgeBatch([
          for (var i = 0; i < batch.length; i++)
            {
              'operation': batch[i],
              'remote': replies[i].value,
              'fields': replies[i].conflicts,
              'revision': replies[i].revision,
            },
        ]);
        if (generation != _generation) return;
        lastSaved = DateTime.now();
        error = null;
        _failures = 0;
      }
    } catch (e) {
      if (generation != _generation || _disposed) return;
      final code = e is FirebaseException ? e.code : '';
      if (code == 'unavailable' || code == 'deadline-exceeded') {
        _serverSeen = false;
      } else {
        error = e is FormatException
            ? e.message
            : 'Cloud saving is paused. Your changes remain on this device. Try again shortly.';
      }
      _failures++;
      final seconds = (5 * (1 << _failures.clamp(0, 5))).clamp(10, 120);
      _retry = Timer(Duration(seconds: seconds), retry);
    } finally {
      if (generation == _generation) {
        _busy = false;
        _schedule();
        _notify();
      }
    }
  }

  Future<void> retry() async {
    if (_disposed || _busy) return;
    _retry?.cancel();
    _switchTail = _switchTail
        .then((_) async {
          if (_disposed) return;
          unawaited(_remoteListener?.cancel());
          _remoteListener = null;
          await _switch(currentUid());
        })
        .catchError((Object e) {
          switching = false;
          error = 'Could not reconnect. Your local data has been kept.';
          _notify();
        });
    await _switchTail;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposed = true;
    _generation++;
    _retry?.cancel();
    _authListener?.cancel();
    _remoteListener?.cancel();
    store?.removeListener(_localChanged);
    for (final local in _stores.values) {
      local.dispose();
    }
    if (identical(LocalShoppingRepository.activeStore, store)) {
      LocalShoppingRepository.activeStore = null;
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // Temporary overlays can resume the app without losing its connection.
    // Firestore maintains its healthy listener; do not reset server evidence.
    if (currentUid() != _uid ||
        (_uid != null &&
            (_remoteListener == null || !_serverSeen || error != null))) {
      retry();
    } else {
      _schedule();
    }
  }
}
