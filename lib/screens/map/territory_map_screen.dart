import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:radar_vila/core/constants.dart';
import 'package:radar_vila/core/theme/app_spacing.dart';
import 'package:radar_vila/core/theme/theme_context.dart';
import 'package:radar_vila/core/utils/formatters.dart';
import 'package:radar_vila/models/occurrence.dart';
import 'package:radar_vila/providers/load_status.dart';
import 'package:radar_vila/providers/occurrence_provider.dart';
import 'package:radar_vila/providers/territory_provider.dart';
import 'package:radar_vila/widgets/app_card.dart';
import 'package:radar_vila/widgets/pills.dart';
import 'package:radar_vila/widgets/section_header.dart';
import 'package:radar_vila/widgets/state_views.dart';

/// Mapa das sub-regiões com a contagem de ocorrências cidadãs.
/// Localização sempre aproximada (centro da sub-região), nunca o endereço.
class TerritoryMapScreen extends StatefulWidget {
  const TerritoryMapScreen({super.key});

  @override
  State<TerritoryMapScreen> createState() => _TerritoryMapScreenState();
}

class _TerritoryMapScreenState extends State<TerritoryMapScreen> {
  final _mapController = MapController();
  String? _selected; // estado LOCAL: sub-região em destaque

  static const _center =
      LatLng(TerritoryInfo.latitude, TerritoryInfo.longitude);

  void _select(String region) {
    setState(() => _selected = _selected == region ? null : region);
    final c = TerritoryInfo.regionCenters[region];
    if (c != null && _selected != null) {
      _mapController.move(LatLng(c.$1, c.$2), 15);
    }
  }

  @override
  Widget build(BuildContext context) {
    final occurrences = context.watch<OccurrenceProvider>();
    final alerts =
        context.select<TerritoryProvider, int>((t) => t.pendingAlertsCount);

    final Widget body;
    if (occurrences.status == LoadStatus.error) {
      body = ErrorView(
        message: occurrences.errorMessage ?? 'Erro ao carregar ocorrências.',
        onRetry: occurrences.load,
      );
    } else if (occurrences.isLoading ||
        occurrences.status == LoadStatus.initial) {
      body = const LoadingView(message: 'Carregando ocorrências…');
    } else {
      final byRegion = occurrences.byRegion;
      final map = _RegionMap(
        controller: _mapController,
        center: _center,
        byRegion: byRegion,
        selected: _selected,
        onSelect: _select,
      );
      final list = _RegionList(
        byRegion: byRegion,
        selected: _selected,
        onSelect: _select,
        pendingAlerts: alerts,
      );

      body = LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth >= 760) {
          return Row(
            children: [
              Expanded(child: map),
              SizedBox(width: 380, child: list),
            ],
          );
        }
        return Column(
          children: [
            SizedBox(height: constraints.maxHeight * 0.45, child: map),
            Expanded(child: list),
          ],
        );
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mapa do território')),
      body: body,
    );
  }
}

String _pendingText(int n) => n == 1
    ? '1 alerta aguardando decisão vale'
    : '$n alertas aguardando decisão valem';

/// Cor do marcador conforme a quantidade de registros na região.
Color _levelColor(BuildContext context, int count) {
  final p = context.palette;
  if (count == 0) return p.muted;
  if (count < 3) return p.atencao;
  return p.critico;
}

class _RegionMap extends StatelessWidget {
  const _RegionMap({
    required this.controller,
    required this.center,
    required this.byRegion,
    required this.selected,
    required this.onSelect,
  });

  final MapController controller;
  final LatLng center;
  final Map<String, List<Occurrence>> byRegion;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final total = byRegion.values.fold<int>(0, (s, l) => s + l.length);
    return Semantics(
      label: 'Mapa da Vila Mariana com ${TerritoryInfo.regions.length} '
          'sub-regiões e ${Fmt.count(total, 'ocorrência', 'ocorrências')}. A lista abaixo traz os mesmos '
          'dados em texto.',
      child: FlutterMap(
        mapController: controller,
        options: MapOptions(
          initialCenter: center,
          initialZoom: 14,
          // Enquadra todas as sub-regiões, em qualquer tamanho de tela.
          initialCameraFit: CameraFit.bounds(
            bounds: LatLngBounds.fromPoints([
              for (final c in TerritoryInfo.regionCenters.values)
                LatLng(c.$1, c.$2),
            ]),
            padding: const EdgeInsets.all(48),
          ),
          minZoom: 12,
          maxZoom: 17,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'br.com.fiap.radar_vila',
          ),
          MarkerLayer(
            markers: [
              for (final region in TerritoryInfo.regions)
                if (TerritoryInfo.regionCenters[region] case final c?)
                  Marker(
                    point: LatLng(c.$1, c.$2),
                    width: 64,
                    height: 64,
                    child: _RegionMarker(
                      region: region,
                      count: byRegion[region]?.length ?? 0,
                      selected: region == selected,
                      onTap: () => onSelect(region),
                    ),
                  ),
            ],
          ),
          const RichAttributionWidget(
            attributions: [TextSourceAttribution('OpenStreetMap contributors')],
          ),
        ],
      ),
    );
  }
}

class _RegionMarker extends StatelessWidget {
  const _RegionMarker({
    required this.region,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String region;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _levelColor(context, count);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    // O marcador cresce ao ser selecionado para mostrar qual região está em
    // foco na lista; sem animação se o sistema pedir menos movimento.
    final size = selected ? 56.0 : 42.0;
    return Semantics(
      button: true,
      selected: selected,
      label: '$region: ${Fmt.count(count, 'ocorrência', 'ocorrências')}',
      child: GestureDetector(
        onTap: onTap,
        child: Center(
          child: AnimatedContainer(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: selected ? 4 : 2,
              ),
              boxShadow: const [
                BoxShadow(blurRadius: 6, color: Color(0x55000000)),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RegionList extends StatelessWidget {
  const _RegionList({
    required this.byRegion,
    required this.selected,
    required this.onSelect,
    required this.pendingAlerts,
  });

  final Map<String, List<Occurrence>> byRegion;
  final String? selected;
  final ValueChanged<String> onSelect;
  final int pendingAlerts;

  @override
  Widget build(BuildContext context) {
    final regions = [...TerritoryInfo.regions]..sort((a, b) =>
        (byRegion[b]?.length ?? 0).compareTo(byRegion[a]?.length ?? 0));
    final empty = byRegion.isEmpty;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const InfoPill(
          icon: Icons.place_outlined,
          text: 'Posição aproximada por sub-região, nunca o endereço',
        ),
        const SizedBox(height: AppSpacing.sm),
        const _Legend(),
        if (pendingAlerts > 0) ...[
          const SizedBox(height: AppSpacing.md),
          AppCard(
            semanticLabel: '${_pendingText(pendingAlerts)} para todo o '
                'distrito.',
            child: Row(
              children: [
                Icon(Icons.notifications_active_outlined,
                    color: context.palette.critico),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    '${_pendingText(pendingAlerts)} para todo o distrito '
                    '(água, energia e clima não têm medição por sub-região).',
                  ),
                ),
              ],
            ),
          ),
        ],
        const SectionHeader(title: 'Ocorrências por sub-região'),
        if (empty)
          const EmptyView(
            compact: true,
            icon: Icons.map_outlined,
            title: 'Nenhuma ocorrência no mapa',
            message: 'Os registros feitos na aba Ocorrências aparecem aqui, '
                'agrupados por sub-região.',
          ),
        for (final region in regions)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _RegionTile(
              region: region,
              items: byRegion[region] ?? const [],
              selected: region == selected,
              onTap: () => onSelect(region),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'O mapa base (OpenStreetMap) precisa de conexão. As contagens são '
          'locais e continuam disponíveis sem internet.',
          style: context.mutedSmall,
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget item(int count, String text) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: _levelColor(context, count),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(text, style: context.mutedSmall),
          ],
        );
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.xs,
      children: [
        item(0, 'Sem registros'),
        item(1, '1 a 2 registros'),
        item(3, '3 ou mais'),
      ],
    );
  }
}

class _RegionTile extends StatelessWidget {
  const _RegionTile({
    required this.region,
    required this.items,
    required this.selected,
    required this.onTap,
  });

  final String region;
  final List<Occurrence> items;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final counts = <OccurrenceCategory, int>{};
    for (final o in items) {
      counts[o.category] = (counts[o.category] ?? 0) + 1;
    }
    final color = _levelColor(context, items.length);
    final summary =
        counts.entries.map((e) => '${e.key.label}: ${e.value}').join(' · ');

    return AppCard(
      accent: selected ? context.colors.primary : color,
      onTap: onTap,
      semanticLabel: '$region, '
          '${Fmt.count(items.length, 'ocorrência', 'ocorrências')}. '
          '${summary.isEmpty ? '' : '$summary. '}'
          '${selected ? 'Selecionada no mapa.' : 'Toque para ver no mapa.'}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(region, style: context.textStyles.titleSmall),
              ),
              Text(
                '${items.length}',
                style: context.textStyles.titleMedium?.copyWith(color: color),
              ),
            ],
          ),
          if (summary.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(summary, style: context.mutedSmall),
          ],
        ],
      ),
    );
  }
}
