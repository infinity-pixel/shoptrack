import 'package:flutter/material.dart';
import 'package:shoptrack/core/localization/shoptrack_text.dart';
import 'package:shoptrack/core/widgets/shoptrack_motion.dart';

/// Owns the list-name field for the full lifetime of the dialog route.
///
/// Keeping the controller inside the dialog prevents it from being disposed
/// while Flutter is still animating the route away and cleaning up focus.
class ShoppingListNameDialog extends StatefulWidget {
  const ShoppingListNameDialog({
    super.key,
    required this.title,
    required this.actionLabel,
    this.initialName,
    this.hintText,
  });

  final String title;
  final String actionLabel;
  final String? initialName;
  final String? hintText;

  @override
  State<ShoppingListNameDialog> createState() => _ShoppingListNameDialogState();
}

class _ShoppingListNameDialogState extends State<ShoppingListNameDialog> {
  late final TextEditingController _controller;
  final FocusNode _nameFocusNode = FocusNode();
  final ShopTrackEntranceFocus _entranceFocus = ShopTrackEntranceFocus();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entranceFocus.attach(context, _nameFocusNode);
    });
  }

  @override
  void dispose() {
    _entranceFocus.dispose();
    _nameFocusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: ShopText(widget.title),
      content: TextField(
        controller: _controller,
        focusNode: _nameFocusNode,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          labelText: shopTr(context, 'List name'),
          hintText: widget.hintText == null
              ? null
              : shopTr(context, widget.hintText!),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const ShopText('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: ShopText(widget.actionLabel)),
      ],
    );
  }
}
