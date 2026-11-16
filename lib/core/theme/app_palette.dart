import 'package:material_ui/material_ui.dart';

/// Cores semânticas do RadarVila, entregues via ThemeExtension.
/// Cada tema (claro, escuro, alto contraste) tem sua própria paleta.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.agua,
    required this.energia,
    required this.clima,
    required this.info,
    required this.atencao,
    required this.critico,
    required this.sucesso,
    required this.card,
    required this.border,
    required this.forecast,
    required this.muted,
    required this.banner,
    required this.onBanner,
  });

  final Color agua;
  final Color energia;
  final Color clima;
  final Color info;
  final Color atencao;
  final Color critico;
  final Color sucesso;
  final Color card;
  final Color border;
  final Color forecast;
  final Color muted;
  final Color banner;
  final Color onBanner;

  static const light = AppPalette(
    agua: Color(0xFF1565C0),
    energia: Color(0xFFA15C00),
    clima: Color(0xFF0F766E),
    info: Color(0xFF1D4ED8),
    atencao: Color(0xFFB45309),
    critico: Color(0xFFB91C1C),
    sucesso: Color(0xFF15803D),
    card: Color(0xFFFFFFFF),
    border: Color(0xFFD5DEDC),
    forecast: Color(0xFF6B7C7A),
    muted: Color(0xFF4A5957),
    banner: Color(0xFFE3F1EF),
    onBanner: Color(0xFF0B3B38),
  );

  static const dark = AppPalette(
    agua: Color(0xFF7FB3FF),
    energia: Color(0xFFFFB866),
    clima: Color(0xFF5FD4CB),
    info: Color(0xFF93B4FF),
    atencao: Color(0xFFFFB454),
    critico: Color(0xFFFF8A80),
    sucesso: Color(0xFF6EE7A0),
    card: Color(0xFF17211F),
    border: Color(0xFF2E3D3B),
    forecast: Color(0xFFA3B5B2),
    muted: Color(0xFFB8C7C4),
    banner: Color(0xFF12302D),
    onBanner: Color(0xFFD3EFEB),
  );

  static const highContrastLight = AppPalette(
    agua: Color(0xFF002F6C),
    energia: Color(0xFF5A2E00),
    clima: Color(0xFF003B36),
    info: Color(0xFF00205B),
    atencao: Color(0xFF5A2E00),
    critico: Color(0xFF7A0000),
    sucesso: Color(0xFF004D1A),
    card: Color(0xFFFFFFFF),
    border: Color(0xFF000000),
    forecast: Color(0xFF333333),
    muted: Color(0xFF111111),
    banner: Color(0xFFFFFFFF),
    onBanner: Color(0xFF000000),
  );

  static const highContrastDark = AppPalette(
    agua: Color(0xFF9CCBFF),
    energia: Color(0xFFFFD27F),
    clima: Color(0xFF7FFFF0),
    info: Color(0xFFBFD4FF),
    atencao: Color(0xFFFFE066),
    critico: Color(0xFFFF9C9C),
    sucesso: Color(0xFF9CFFB8),
    card: Color(0xFF000000),
    border: Color(0xFFFFFFFF),
    forecast: Color(0xFFE0E0E0),
    muted: Color(0xFFFFFFFF),
    banner: Color(0xFF000000),
    onBanner: Color(0xFFFFFFFF),
  );

  @override
  AppPalette copyWith({
    Color? agua,
    Color? energia,
    Color? clima,
    Color? info,
    Color? atencao,
    Color? critico,
    Color? sucesso,
    Color? card,
    Color? border,
    Color? forecast,
    Color? muted,
    Color? banner,
    Color? onBanner,
  }) {
    return AppPalette(
      agua: agua ?? this.agua,
      energia: energia ?? this.energia,
      clima: clima ?? this.clima,
      info: info ?? this.info,
      atencao: atencao ?? this.atencao,
      critico: critico ?? this.critico,
      sucesso: sucesso ?? this.sucesso,
      card: card ?? this.card,
      border: border ?? this.border,
      forecast: forecast ?? this.forecast,
      muted: muted ?? this.muted,
      banner: banner ?? this.banner,
      onBanner: onBanner ?? this.onBanner,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      agua: mix(agua, other.agua),
      energia: mix(energia, other.energia),
      clima: mix(clima, other.clima),
      info: mix(info, other.info),
      atencao: mix(atencao, other.atencao),
      critico: mix(critico, other.critico),
      sucesso: mix(sucesso, other.sucesso),
      card: mix(card, other.card),
      border: mix(border, other.border),
      forecast: mix(forecast, other.forecast),
      muted: mix(muted, other.muted),
      banner: mix(banner, other.banner),
      onBanner: mix(onBanner, other.onBanner),
    );
  }
}
