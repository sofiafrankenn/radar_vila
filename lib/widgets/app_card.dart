import 'package:material_ui/material_ui.dart';

import 'package:radar_vila/core/theme/app_spacing.dart';
import 'package:radar_vila/core/theme/theme_context.dart';

/// Cartão padrão do app, com faixa lateral de destaque opcional.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.accent,
    this.semanticLabel,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? accent;

  /// Quando informado, substitui a leitura do conteúdo por leitores de tela.
  final String? semanticLabel;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    Widget body = Padding(
      padding: accent == null
          ? padding
          : padding.add(const EdgeInsets.only(left: AppSpacing.xs)),
      child: child,
    );

    if (accent != null) {
      body = Stack(
        fit: StackFit.passthrough,
        children: [
          body,
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 5,
            child: ColoredBox(color: accent!),
          ),
        ],
      );
    }

    if (semanticLabel != null) body = ExcludeSemantics(child: body);

    return Semantics(
      container: true,
      button: onTap != null,
      label: semanticLabel,
      child: Material(
        color: palette.card,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: palette.border),
        ),
        child: onTap == null ? body : InkWell(onTap: onTap, child: body),
      ),
    );
  }
}
