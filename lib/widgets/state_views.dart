import 'package:material_ui/material_ui.dart';

import 'package:radar_vila/core/theme/app_spacing.dart';
import 'package:radar_vila/core/theme/theme_context.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message = 'Carregando…'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(semanticsLabel: message),
            const SizedBox(height: AppSpacing.lg),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Semantics(
          liveRegion: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_outlined,
                  size: 52, color: context.colors.error),
              const SizedBox(height: AppSpacing.md),
              Text('Algo deu errado', style: context.textStyles.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(message, textAlign: TextAlign.center),
              if (onRetry != null) ...[
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: compact ? AppSpacing.lg : AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 36 : 56, color: palette.muted),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.textStyles.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style:
                  context.textStyles.bodyMedium?.copyWith(color: palette.muted),
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
