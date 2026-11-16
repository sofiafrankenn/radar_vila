/// Formatação de números e datas no padrão brasileiro (sem dependências).
class Fmt {
  Fmt._();

  /// 1234.5 -> "1.234,5"
  static String number(double value, {int decimals = 1}) {
    final fixed = value.abs().toStringAsFixed(decimals);
    final negative = value < 0 && double.parse(fixed) != 0;
    final parts = fixed.split('.');
    final intPart = parts[0];
    final buffer = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write('.');
      buffer.write(intPart[i]);
    }
    var out = buffer.toString();
    if (decimals > 0) out = '$out,${parts[1]}';
    return negative ? '-$out' : out;
  }

  /// Número com sinal explícito: "+1,2" / "-0,8".
  static String signed(double value, {int decimals = 1}) {
    final text = number(value, decimals: decimals);
    return text.startsWith('-') ? text : '+$text';
  }

  /// 3250000 -> "3,3 mi"; 29500 -> "29,5 mil".
  static String compact(double value) {
    if (value.abs() >= 1e6) return '${number(value / 1e6, decimals: 1)} mi';
    if (value.abs() >= 1e3) return '${number(value / 1e3, decimals: 1)} mil';
    return number(value, decimals: 0);
  }

  /// 0.58 -> "58%".
  static String percent(double ratio, {int decimals = 0}) =>
      '${number(ratio * 100, decimals: decimals)}%';

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String dayMonth(DateTime d) => '${_two(d.day)}/${_two(d.month)}';

  static String date(DateTime d) => '${dayMonth(d)}/${d.year}';

  static String dateTime(DateTime d) =>
      '${dayMonth(d)} às ${_two(d.hour)}:${_two(d.minute)}';

  static const _weekdays = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];

  static String weekday(DateTime d) => _weekdays[d.weekday - 1];

  /// Chave estável para IDs: 20261110.
  static String dateKey(DateTime d) =>
      '${d.year}${_two(d.month)}${_two(d.day)}';
}
