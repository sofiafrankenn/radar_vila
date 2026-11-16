import 'package:material_ui/material_ui.dart';

import 'package:radar_vila/core/theme/theme_context.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 36, this.showName = true});

  final double size;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: 'RadarVila',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(size * 0.3),
            ),
            child:
                Icon(Icons.radar, color: colors.onPrimary, size: size * 0.62),
          ),
          if (showName) ...[
            SizedBox(width: size * 0.3),
            Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: size * 0.56,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: colors.onSurface,
                ),
                children: [
                  const TextSpan(text: 'Radar'),
                  TextSpan(
                      text: 'Vila', style: TextStyle(color: colors.primary)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
