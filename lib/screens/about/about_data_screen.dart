import 'package:material_ui/material_ui.dart';

import 'package:radar_vila/core/constants.dart';
import 'package:radar_vila/core/theme/app_spacing.dart';
import 'package:radar_vila/core/theme/theme_context.dart';
import 'package:radar_vila/widgets/app_card.dart';
import 'package:radar_vila/widgets/banners.dart';
import 'package:radar_vila/widgets/section_header.dart';

/// Transparência: fontes, métricas, limitações, vieses e privacidade.
class AboutDataScreen extends StatelessWidget {
  const AboutDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sobre os dados')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: const [
          HumanDecisionBanner(),
          SectionHeader(title: 'Território'),
          _Bullets([
            '${TerritoryInfo.name}, ${TerritoryInfo.city}. ${TerritoryInfo.populationNote}',
            'Coordenada de referência: -23,589 / -46,635 (centro do distrito).',
          ]),
          SectionHeader(title: 'Fontes de dados'),
          _Bullets([
            'Clima (REAL): API pública Open-Meteo — temperatura máxima e chuva '
                'diária, 30 dias de histórico e 7 dias de previsão.',
            'Água e energia (SINTÉTICOS): série simulada pelo app com tendência, '
                'efeito de fim de semana e ruído, com ordem de grandeza inspirada '
                'em dados públicos (SNIS/ANEEL). Representa um cenário de '
                'estresse hídrico para demonstração.',
            'Ocorrências: registradas pelos cidadãos no próprio app, anonimizadas '
                'e salvas apenas no aparelho.',
          ]),
          SectionHeader(title: 'Como os alertas são gerados'),
          _Bullets([
            'Regressão linear (água e pico de energia): ajusta uma reta aos '
                'últimos 14 dias e projeta 3 dias. Alerta se a projeção ou o '
                'último valor passar do limiar.',
            'Regra de limiar (perdas): média dos últimos 7 dias acima do limiar.',
            'Previsão meteorológica: 2+ dias seguidos acima do limiar de calor, '
                'ou um dia acima do limiar de chuva.',
            'Anomalia (todos, exceto chuva): último valor com |z-score| ≥ 2,5 '
                'em relação aos 14 dias anteriores.',
          ]),
          SectionHeader(title: 'Como calculamos a confiança'),
          _Bullets([
            'Tendência: 15% + 55% × R² + 30% × (dias de histórico ÷ 21).',
            'Perdas: 92% − 3 × coeficiente de variação da semana.',
            'Calor: 92% − 7 pontos por dia de antecedência. '
                'Chuva: 80% − 8 pontos por dia.',
            'Anomalia: no máximo 35% (um ponto isolado não é tendência).',
            'Dados em cache: confiança multiplicada por 0,75. '
                'Faixas: Alta ≥ 70%, Média ≥ 40%, Baixa < 40%.',
          ]),
          SectionHeader(title: 'Métricas exibidas'),
          _Bullets([
            'Média móvel de 7 dias, variação semanal (%), mínimo, máximo, '
                'desvio padrão, inclinação da tendência e R².',
          ]),
          SectionHeader(title: 'Limitações e possíveis vieses'),
          _Bullets([
            'Dados sintéticos não substituem medições da concessionária.',
            'Um único ponto meteorológico não captura microclimas (ilhas de '
                'calor, fundos de vale).',
            'Subnotificação: moradores com menos acesso digital registram menos '
                'ocorrências, o que pode desviar a atenção para áreas mais '
                'conectadas.',
            'A regressão linear não modela sazonalidade longa, feriados ou '
                'eventos extremos.',
          ]),
          SectionHeader(title: 'Quando as previsões NÃO são confiáveis'),
          _Bullets([
            'R² abaixo de 0,4 (série muito oscilante).',
            'Menos de 7 dias de histórico.',
            'Dados em cache ou desatualizados há mais de 24 h.',
            'Horizonte maior que 3 dias (tendência) ou 5 dias (clima).',
            'Durante eventos atípicos: obras, feriados, falhas de medição.',
          ]),
          SectionHeader(title: 'Benefício social'),
          _Bullets([
            'Economia potencial = (consumo médio − 150 L/hab/dia) × população × 7.',
            'Equivalência em pessoas abastecidas usa 110 L/pessoa/dia (ONU).',
            'Também contamos alertas avaliados por pessoas e ocorrências '
                'cidadãs, que medem a participação no cuidado do bairro.',
          ]),
          SectionHeader(title: 'Privacidade e inclusão'),
          _Bullets([
            'Consentimento explícito na primeira abertura, revogável em Ajustes.',
            'Sem nome, telefone ou endereço; CEP truncado; apelido aleatório; '
                'bloqueio de e-mail/telefone/CPF na descrição.',
            'Tudo é salvo localmente; nada é enviado a servidores.',
            'Modo escuro, alto contraste, ajuste de fonte, rótulos para leitores '
                'de tela e severidade indicada por ícone + texto, não só por cor.',
          ]),
          SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _Bullets extends StatelessWidget {
  const _Bullets(this.items);

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: context.colors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
