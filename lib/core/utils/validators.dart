import 'package:radar_vila/core/utils/formatters.dart';

/// Validações reutilizáveis dos formulários.
class Validators {
  Validators._();

  static final RegExp _email = RegExp(r'[\w.+-]+@[\w-]+\.[\w.]+');
  static final RegExp _cpf = RegExp(r'\d{3}\.?\d{3}\.?\d{3}-?\d{2}');
  static final RegExp _phone = RegExp(r'(\(?\d{2}\)?\s?)?9?\d{4}[-\s]?\d{4}');

  static const int descriptionMin = 15;
  static const int descriptionMax = 300;

  /// Descrição da ocorrência: tamanho mínimo/máximo e bloqueio de dados pessoais.
  static String? description(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Descreva a ocorrência.';
    if (text.length < descriptionMin) {
      return 'Descreva com pelo menos $descriptionMin caracteres '
          '(faltam ${descriptionMin - text.length}).';
    }
    if (text.length > descriptionMax) {
      return 'Use no máximo $descriptionMax caracteres.';
    }
    if (containsPersonalData(text)) {
      return 'Parece haver dado pessoal (e-mail, telefone ou CPF). '
          'Remova para proteger sua privacidade.';
    }
    return null;
  }

  static bool containsPersonalData(String text) =>
      _email.hasMatch(text) || _cpf.hasMatch(text) || _phone.hasMatch(text);

  /// CEP opcional; se informado, precisa ter 8 dígitos e ser da capital paulista.
  static String? optionalCep(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    if (digits.length != 8) return 'O CEP deve ter 8 dígitos.';
    final prefix = int.parse(digits.substring(0, 5));
    final inCity = (prefix >= 1000 && prefix <= 5999) ||
        (prefix >= 8000 && prefix <= 8499);
    if (!inCity) return 'CEP fora da cidade de São Paulo.';
    return null;
  }

  /// Data da ocorrência: obrigatória, não futura, até 30 dias atrás.
  static String? occurrenceDate(DateTime? value, {DateTime? now}) {
    if (value == null) return 'Informe a data.';
    final ref = now ?? DateTime.now();
    final today = DateTime.utc(ref.year, ref.month, ref.day);
    final day = DateTime.utc(value.year, value.month, value.day);
    if (day.isAfter(today)) return 'A data não pode ser no futuro.';
    if (today.difference(day).inDays > 30) {
      return 'Registre ocorrências de no máximo 30 dias atrás.';
    }
    return null;
  }

  /// Número dentro de um intervalo (aceita vírgula ou ponto).
  static String? numberInRange(
    String? value, {
    required double min,
    required double max,
    String unit = '',
  }) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return 'Informe um valor.';
    final number = parseNumber(raw);
    if (number == null) return 'Use apenas números (ex.: 32,5).';
    if (number < min || number > max) {
      final suffix = unit.isEmpty ? '' : ' $unit';
      return 'O valor deve estar entre ${Fmt.number(min, decimals: 0)} '
          'e ${Fmt.number(max, decimals: 0)}$suffix.';
    }
    return null;
  }

  static double? parseNumber(String? value) =>
      double.tryParse((value ?? '').trim().replaceAll(',', '.'));
}
