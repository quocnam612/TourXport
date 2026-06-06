import 'package:flutter/services.dart';

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');
    String newText = '';
    for (int i = 0; i < text.length; i++) {
      newText += text[i];
      if ((i == 3 || i == 6) && i != text.length - 1) {
        newText += ' ';
      }
    }
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
