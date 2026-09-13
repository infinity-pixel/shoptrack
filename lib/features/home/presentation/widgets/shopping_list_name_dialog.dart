import 'package:flutter/material.dart';

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
  State<ShoppingListNameDialog> createState() =>
      _ShoppingListNameDialogState();
}

class _ShoppingListNameDialogState extends State<ShoppingListNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          labelText: 'List name',
          hintText: widget.hintText,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.actionLabel),
        ),
      ],
    );
  }
}
