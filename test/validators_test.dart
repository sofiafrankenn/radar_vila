import 'package:flutter_test/flutter_test.dart';

import 'package:radar_vila/core/utils/anonymizer.dart';
import 'package:radar_vila/core/utils/formatters.dart';
import 'package:radar_vila/core/utils/validators.dart';

void main() {
  group('Descrição da ocorrência', () {
    test('vazia ou curta é rejeitada', () {
      expect(Validators.description(''), isNotNull);
      expect(Validators.description('vazou'), contains('pelo menos'));
    });

    test('dados pessoais são bloqueados', () {
      expect(Validators.description('Vazamento grande, me liga 11 98765-4321'),
          contains('dado pessoal'));
      expect(Validators.description('Falta de água, fale com joao@email.com'),
          contains('dado pessoal'));
      expect(
          Validators.description('Alagamento na rua, meu CPF 123.456.789-00'),
          contains('dado pessoal'));
    });

    test('descrição válida passa', () {
      expect(
          Validators.description(
              'Vazamento na calçada perto da escola há 2 dias.'),
          isNull);
    });
  });

  group('CEP', () {
    test('opcional', () => expect(Validators.optionalCep(''), isNull));
    test('precisa de 8 dígitos',
        () => expect(Validators.optionalCep('0410'), isNotNull));
    test('fora de São Paulo é rejeitado',
        () => expect(Validators.optionalCep('20040000'), isNotNull));
    test('CEP da Vila Mariana é aceito',
        () => expect(Validators.optionalCep('04101000'), isNull));
    test('anonimização mantém só 5 dígitos',
        () => expect(Anonymizer.cepPrefix('04101-000'), '04101-***'));
  });

  group('Data da ocorrência', () {
    final now = DateTime(2026, 11, 10);
    test('futuro é rejeitado', () {
      expect(Validators.occurrenceDate(DateTime(2026, 11, 11), now: now),
          isNotNull);
    });
    test('mais de 30 dias é rejeitado', () {
      expect(
          Validators.occurrenceDate(DateTime(2026, 9, 1), now: now), isNotNull);
    });
    test('hoje é aceito', () {
      expect(Validators.occurrenceDate(now, now: now), isNull);
    });
  });

  group('Limiares numéricos', () {
    test('aceita vírgula decimal', () {
      expect(Validators.numberInRange('32,5', min: 28, max: 42), isNull);
    });
    test('rejeita texto', () {
      expect(Validators.numberInRange('abc', min: 28, max: 42), isNotNull);
    });
    test('rejeita fora do intervalo', () {
      expect(Validators.numberInRange('50', min: 28, max: 42, unit: '°C'),
          contains('entre 28 e 42'));
    });
  });

  group('Formatação pt-BR', () {
    test('milhar e decimal',
        () => expect(Fmt.number(1234.56, decimals: 1), '1.234,6'));
    test('compacto', () => expect(Fmt.compact(3400000), '3,4 mi'));
    test('sinal', () => expect(Fmt.signed(0.9), '+0,9'));
  });
}
