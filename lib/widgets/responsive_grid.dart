import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'package:radar_vila/core/theme/app_spacing.dart';

/// 1 coluna no celular, 2 em telas médias e 3 em tablets/landscape.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 280,
    this.spacing = AppSpacing.md,
    this.maxColumns = 3,
  });

  final List<Widget> children;
  final double minItemWidth;
  final double spacing;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = math.max(
          1,
          math.min(
            maxColumns,
            ((constraints.maxWidth + spacing) / (minItemWidth + spacing))
                .floor(),
          ),
        );
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}
