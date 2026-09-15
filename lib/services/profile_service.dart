import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-only overrides, kept separately from Google's identity and shopping data.
class LocalProfile {
  const LocalProfile({
    required this.name,
    this.photo,
    this.hideGooglePhoto = false,
  });
  final String name;
  final Uint8List? photo;
  final bool hideGooglePhoto;
}

class ProfileService extends ChangeNotifier {
  ProfileService() {
    ready = _load();
  }
  static const _key = 'shoptrack_profile_overrides_v1';
  late final Future<void> ready;
  Map<String, dynamic> _profiles = {};
  bool loaded = false;
  bool _disposed = false;
  Object? loadError;

  Future<void> _load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw != null) _profiles = jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      loadError = e;
    }
    loaded = true;
    if (!_disposed) notifyListeners();
  }

  LocalProfile? forAccount(String id) {
    final value = _profiles[id];
    if (value == null) return null;
    try {
      final data = value as Map<String, dynamic>;
      return LocalProfile(
        name: data['name'] as String,
        photo: data['photo'] == null
            ? null
            : base64Decode(data['photo'] as String),
        hideGooglePhoto: data['hideGooglePhoto'] == true,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save(String id, LocalProfile profile) async {
    await ready;
    if (loadError != null) {
      throw StateError('Saved profiles could not be loaded.');
    }
    if (id.isEmpty || profile.name.trim().isEmpty) {
      throw ArgumentError('Name is required.');
    }
    if ((profile.photo?.length ?? 0) > 1024 * 1024) {
      throw ArgumentError('Photo is too large.');
    }
    final updated = {
      ..._profiles,
      id: {
        'name': profile.name.trim(),
        'photo': profile.photo == null ? null : base64Encode(profile.photo!),
        'hideGooglePhoto': profile.hideGooglePhoto,
      },
    };
    final ok = await (await SharedPreferences.getInstance()).setString(
      _key,
      jsonEncode(updated),
    );
    if (!ok) throw StateError('Profile could not be saved.');
    _profiles = updated;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
