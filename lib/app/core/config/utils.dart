import 'package:flutter/services.dart';

String removeSpecialCharacters(String str) {
  Map<String, String> mapaAcentos = {
    "á": "a", "à": "a", "ã": "a", "â": "a",
    "é": "e", "è": "e", "ê": "e",
    "í": "i", "ì": "i", "î": "i",
    "ó": "o", "ò": "o", "õ": "o", "ô": "o",
    "ú": "u", "ù": "u", "û": "u",
    "ç": "c"
    // Adicione outros caracteres conforme necessário
  };

  // Substituir caracteres acentuados pelo seu equivalente não acentuado
  mapaAcentos.forEach((key, value) {
    str = str.replaceAll(key, value);
    str = str.replaceAll(key.toUpperCase(), value.toUpperCase());
  });

  return str;
}

String? validateEmail(String? value) {
  const pattern = r"(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'"
      r'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-'
      r'\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*'
      r'[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:(2(5[0-5]|[0-4]'
      r'[0-9])|1[0-9][0-9]|[1-9]?[0-9]))\.){3}(?:(2(5[0-5]|[0-4][0-9])|1[0-9]'
      r'[0-9]|[1-9]?[0-9])|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\'
      r'x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])';
  final regex = RegExp(pattern);

  return value!.isNotEmpty && !regex.hasMatch(value)
      ? 'Enter a valid email'
      : null;
}

String? validatePassword(String? value) {
  RegExp regex =
      RegExp(r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$');
  if (value!.isEmpty) {
    return "Please enter password";
  } else {
    if (!regex.hasMatch(value)) {
      return "Enter valid password";
    } else {
      return null;
    }
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(), // Convertendo para caixa alta
      selection: newValue.selection,
    );
  }
}

class NumericTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Remove caracteres não numéricos, exceto o ponto e a vírgula
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9,.]'), '');

    // Substituir vírgula por ponto para padronização numérica
    newText = newText.replaceAll(',', '.');

    // Se houver mais de um ponto decimal, remova os extras
    int countPeriods = newText.split('.').length - 1;
    if (countPeriods > 1) {
      List<String> parts = newText.split('.');
      newText = parts[0] + '.' + parts.sublist(1).join('');
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
