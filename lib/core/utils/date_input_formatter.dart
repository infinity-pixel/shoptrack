import 'package:flutter/services.dart';

class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;

    if (newValue.selection.baseOffset < text.length) {
      return newValue;
    }

    // Only allow digits and / - .
    if (!RegExp(r'^[\d\/\-\.]*$').hasMatch(text)) {
      return oldValue;
    }

    // If deleting, don't auto-format
    if (text.length < oldValue.text.length) {
      return newValue;
    }

    String newText = text;
    
    // Auto-insert / for common patterns if no separator is typed
    if (text.length == 2 && !text.contains('/') && !text.contains('-') && !text.contains('.')) {
      newText = '$text/';
    } else if (text.length == 5 && (text.indexOf('/') == 2 || text.indexOf('-') == 2 || text.indexOf('.') == 2)) {
      // Check if second separator is missing
      final lastChar = text.substring(4);
      if (lastChar != '/' && lastChar != '-' && lastChar != '.') {
         newText = '$text/';
      }
    }

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
