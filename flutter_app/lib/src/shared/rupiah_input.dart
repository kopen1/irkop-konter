import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class RupiahInputFormatter extends TextInputFormatter {
  RupiahInputFormatter({this.allowEmpty = true});

  final bool allowEmpty;
  static final NumberFormat _number = NumberFormat.decimalPattern('id_ID');

  static int parse(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  static String format(num value) => _number.format(value);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      final text = allowEmpty ? '' : '0';
      return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }

    final formatted = _number.format(int.parse(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

int parseRupiah(String value) => RupiahInputFormatter.parse(value);
String formatRupiahInput(num value) => RupiahInputFormatter.format(value);
