class VietnameseNumberToWords {
  static const List<String> _units = [
    'không', 'một', 'hai', 'ba', 'bốn', 'năm', 'sáu', 'bảy', 'tám', 'chín'
  ];

  static const List<String> _scales = [
    '', 'nghìn', 'triệu', 'tỷ', 'nghìn tỷ', 'triệu tỷ'
  ];

  /// Chuyển đổi số tiền thành chữ tiếng Việt chuẩn xác
  /// Ví dụ: 500000 -> "năm trăm nghìn đồng"
  /// Ví dụ: 1250000 -> "một triệu hai trăm năm mươi nghìn đồng"
  static String convert(num number, {bool appendCurrency = true}) {
    int n = number.toInt();
    if (n == 0) {
      return appendCurrency ? 'không đồng' : 'không';
    }

    if (n < 0) {
      return 'âm ${convert(-n, appendCurrency: appendCurrency)}';
    }

    List<int> groups = [];
    int temp = n;
    while (temp > 0) {
      groups.add(temp % 1000);
      temp ~/= 1000;
    }

    List<String> groupWords = [];
    for (int i = groups.length - 1; i >= 0; i--) {
      int group = groups[i];
      if (group > 0) {
        bool isHighestGroup = (i == groups.length - 1);
        String s = _readThreeDigits(group, readZeroHundreds: !isHighestGroup);
        if (_scales[i].isNotEmpty) {
          s = '$s ${_scales[i]}';
        }
        groupWords.add(s);
      }
    }

    String result = groupWords.join(' ').trim();
    // Chuẩn hóa khoảng trắng kép
    result = result.replaceAll(RegExp(r'\s+'), ' ');

    if (appendCurrency) {
      return '$result đồng';
    }
    return result;
  }

  static String _readThreeDigits(int number, {bool readZeroHundreds = false}) {
    int hundreds = number ~/ 100;
    int remainder = number % 100;
    int tens = remainder ~/ 10;
    int ones = remainder % 10;

    List<String> parts = [];

    // Hàng trăm
    if (hundreds > 0 || readZeroHundreds) {
      parts.add('${_units[hundreds]} trăm');
    }

    // Hàng chục & đơn vị
    if (tens == 0) {
      if (ones > 0) {
        if (hundreds > 0 || readZeroHundreds) {
          parts.add('lẻ ${_units[ones]}');
        } else {
          parts.add(_units[ones]);
        }
      }
    } else if (tens == 1) {
      parts.add('mười');
      if (ones == 1) {
        parts.add('một');
      } else if (ones == 5) {
        parts.add('lăm');
      } else if (ones > 0) {
        parts.add(_units[ones]);
      }
    } else {
      // tens >= 2
      parts.add('${_units[tens]} mươi');
      if (ones == 1) {
        parts.add('mốt');
      } else if (ones == 4) {
        parts.add('tư');
      } else if (ones == 5) {
        parts.add('lăm');
      } else if (ones > 0) {
        parts.add(_units[ones]);
      }
    }

    return parts.join(' ');
  }
}
