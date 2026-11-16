import 'dart:math';

/// Anonimização por design: o app nunca guarda nome, telefone ou endereço.
class Anonymizer {
  Anonymizer._();

  static const _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// "04101-000" -> "04101-***" (mantém só a região aproximada).
  static String cepPrefix(String cep) {
    final digits = cep.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 5) return '*****-***';
    return '${digits.substring(0, 5)}-***';
  }

  /// Apelido aleatório, sem relação com a identidade da pessoa.
  static String randomAlias([Random? random]) {
    final rng = random ?? Random.secure();
    final code =
        List.generate(4, (_) => _chars[rng.nextInt(_chars.length)]).join();
    return 'Cidadão #$code';
  }
}
