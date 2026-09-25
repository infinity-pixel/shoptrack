import 'dart:math' as math;
import 'package:shoptrack/core/localization/shoptrack_text.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/shoptrack_modal.dart';
import '../../../../core/theme/theme_presets.dart';
import '../../../../models/auth_state.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/profile_service.dart';
import '../widgets/profile_avatar.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({
    super.key,
    required this.account,
    required this.profiles,
    required this.auth,
  });
  final AuthAccount account;
  final ProfileService profiles;
  final AuthService auth;
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final String _initialName;
  Uint8List? _photo;
  Uint8List? _initialPhoto;
  bool _hideGoogle = false;
  bool _initialHide = false;
  bool _busy = false;
  bool _allowPop = false;
  String? _error;
  bool get _dirty =>
      _name.text.trim() != _initialName ||
      !identical(_photo, _initialPhoto) ||
      _hideGoogle != _initialHide;

  @override
  void initState() {
    super.initState();
    final saved = widget.profiles.forAccount(widget.account.id);
    _initialName = saved?.name ?? widget.account.displayName ?? '';
    _name = TextEditingController(text: _initialName);
    _photo = _initialPhoto = saved?.photo;
    _hideGoogle = _initialHide = saved?.hideGooglePhoto ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _exit([bool saved = false]) async {
    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.pop(context, saved);
  }

  Future<void> _cancel() async {
    if (_busy) return;
    if (_dirty) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const ShopText('Discard Changes?'),
          content: const ShopText('Your profile has not been saved.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const ShopText('Keep Editing'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const ShopText('Discard'),
            ),
          ],
        ),
      );
      if (discard != true || !mounted) return;
    }
    await _exit();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    final state = widget.auth.state;
    if (state is! AuthAuthenticated || state.account.id != widget.account.id) {
      setState(
        () => _error =
            'Your account changed. Please return to Profile and try again.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.profiles.save(
        widget.account.id,
        LocalProfile(
          name: _name.text.trim(),
          photo: _photo,
          hideGooglePhoto: _hideGoogle,
        ),
      );
      if (mounted) await _exit(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not save your profile. Please try again.';
        });
      }
    }
  }

  Future<void> _photoOptions() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShopTrackSheetHeader(
              title: 'Profile Photo',
              subtitle: 'Choose how your profile appears in ShopTrack.',
              onClose: () => Navigator.pop(context),
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading: const Icon(Icons.photo_library_outlined),
              title: const ShopText('Choose From Gallery'),
              onTap: () => Navigator.pop(context, 'choose'),
            ),
            if (_photo != null ||
                (!_hideGoogle && widget.account.photoUrl != null))
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: const ShopText('Remove Photo'),
                onTap: () => Navigator.pop(context, 'remove'),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'remove') {
      setState(() {
        _photo = null;
        _hideGoogle = true;
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await FilePicker.pickFiles(type: FileType.image);
      if (result.isEmpty) return;
      if (await result.single.length() > 10 * 1024 * 1024) {
        throw const FormatException();
      }
      final bytes = await result.single.readAsBytes();
      if (bytes.length > 10 * 1024 * 1024) {
        throw const FormatException();
      }
      final thumbnail = await profileThumbnail(bytes);
      if (mounted) {
        setState(() {
          _photo = thumbnail;
          _hideGoogle = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not open that photo. Try a JPG or PNG under 10 MB.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = ShopTrackThemeTokens.of(context).palette;
    return PopScope(
      canPop: _allowPop || (!_dirty && !_busy),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        appBar: AppBar(
          title: ShopText(
            'Edit Profile',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          centerTitle: false,
          leading: IconButton(
            onPressed: _busy ? null : _cancel,
            icon: const Icon(Icons.arrow_back),
            tooltip: shopTr(context, 'Back'),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 12,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: _busy ? null : _cancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: p.onBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const ShopText('Cancel'),
                ),
                FilledButton(
                  onPressed: _busy ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: HSLColor.fromColor(p.primary)
                        .withLightness(
                          Theme.of(context).brightness == Brightness.light
                              ? .36
                              : .7,
                        )
                        .toColor(),
                    foregroundColor:
                        Theme.of(context).brightness == Brightness.light
                        ? Colors.white
                        : Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const ShopText('Save Changes'),
                ),
              ],
            ),
          ),
        ),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: ProfileAvatar(
                          name: _name.text,
                          photo: _photo,
                          googlePhoto: _hideGoogle
                              ? null
                              : widget.account.photoUrl,
                          radius: 44,
                        ),
                      ),
                      Center(
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: p.onBackground,
                          ),
                          onPressed: _busy ? null : _photoOptions,
                          icon: const Icon(
                            Icons.photo_camera_outlined,
                            size: 20,
                          ),
                          label: const ShopText('Change Photo'),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: p.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: p.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _name,
                              enabled: !_busy,
                              maxLength: 60,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.done,
                              decoration: InputDecoration(
                                labelText: shopTr(context, 'Display Name'),
                                helperText: shopTr(
                                  context,
                                  'Only used in ShopTrack',
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Please enter a name.'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            Divider(color: p.border),
                            const SizedBox(height: 16),
                            ShopText(
                              'Google Account',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: SelectableText(widget.account.email),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.lock_outline,
                                  size: 18,
                                  color: p.textSecondary,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ShopText(
                              'Email cannot be edited here.',
                              style: TextStyle(
                                color: p.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      ShopText(
                        'Saved on this device. Your Google account name and photo stay unchanged.',
                        style: TextStyle(color: p.textSecondary, fontSize: 13),
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            _error!,
                            style: TextStyle(color: p.error),
                          ),
                        ),
                      if (_busy)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Decode a bounded image and persist a small PNG rather than a temporary picker path.
Future<Uint8List> profileThumbnail(Uint8List bytes) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  ui.ImageDescriptor? descriptor;
  ui.Codec? codec;
  ui.Image? image;
  try {
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    final scale = math.min(
      1.0,
      384 / math.max(descriptor.width, descriptor.height),
    );
    codec = await descriptor.instantiateCodec(
      targetWidth: math.max(1, (descriptor.width * scale).round()),
      targetHeight: math.max(1, (descriptor.height * scale).round()),
    );
    image = (await codec.getNextFrame()).image;
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) throw const FormatException();
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  } finally {
    image?.dispose();
    codec?.dispose();
    descriptor?.dispose();
    buffer.dispose();
  }
}
