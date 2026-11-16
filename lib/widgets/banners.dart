import 'package:material_ui/material_ui.dart';

import 'package:radar_vila/core/theme/app_spacing.dart';
import 'package:radar_vila/core/theme/theme_context.dart';
import 'package:radar_vila/core/utils/formatters.dart';
import 'package:radar_vila/models/territory_snapshot.dart';

/// Aviso fixo: alertas apoiam, mas não substituem, a decisão humana.
class HumanDecisionBanner extends StatelessWidget {
  const HumanDecisionBanner({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.banner,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, color: palette.onBanner),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A decisão final é sempre humana',
                  style: context.textStyles.titleSmall
                      ?.copyWith(color: palette.onBanner),
                ),
                const SizedBox(height: 2),
                Text(
                  compact
                      ? 'Os alertas apoiam, mas não substituem, a avaliação de um '
                          'gestor responsável.'
                      : 'Os alertas do RadarVila são estimativas para apoiar a '
                          'decisão. Nenhuma medida (rodízio, corte, interdição, '
                          'envio de equipes) é executada pelo app: toda ação '
                          'precisa ser avaliada e registrada por uma pessoa.',
                  style: context.textStyles.bodySmall
                      ?.copyWith(color: palette.onBanner),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Avisa quando os dados estão em cache ou foram atualizados parcialmente.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.snapshot, this.onRetry});

  final TerritorySnapshot snapshot;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final title = snapshot.fromCache
        ? 'Você está vendo dados salvos'
        : 'Atualização parcial';
    final message = snapshot.warning ??
        'Dados salvos em ${Fmt.dateTime(snapshot.fetchedAt)}. Podem estar desatualizados.';

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: palette.atencao.withAlpha(30),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: palette.atencao, width: 1.4),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.wifi_off_rounded, color: palette.atencao),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.textStyles.titleSmall),
                  const SizedBox(height: 2),
                  Text(message, style: context.textStyles.bodySmall),
                  if (onRetry != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: onRetry,
                        child: const Text('Tentar atualizar'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
