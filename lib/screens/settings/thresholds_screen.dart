import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:radar_vila/core/theme/app_inputs.dart';
import 'package:radar_vila/core/theme/app_spacing.dart';
import 'package:radar_vila/core/theme/theme_context.dart';
import 'package:radar_vila/core/utils/validators.dart';
import 'package:radar_vila/models/thresholds.dart';
import 'package:radar_vila/providers/settings_provider.dart';
import 'package:radar_vila/widgets/banners.dart';

/// Formulário de configuração dos limiares de alerta (com validação).
class ThresholdsScreen extends StatefulWidget {
  const ThresholdsScreen({super.key});

  @override
  State<ThresholdsScreen> createState() => _ThresholdsScreenState();
}

class _FieldSpec {
  const _FieldSpec({
    required this.label,
    required this.unit,
    required this.min,
    required this.max,
    required this.helper,
    required this.icon,
  });

  final String label;
  final String unit;
  final double min;
  final double max;
  final String helper;
  final IconData icon;
}

class _ThresholdsScreenState extends State<ThresholdsScreen> {
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;

  static const _specs = <String, _FieldSpec>{
    'aguaConsumo': _FieldSpec(
      label: 'Consumo de água',
      unit: 'L/hab/dia',
      min: 100,
      max: 400,
      helper: 'Padrão 180. Meta de consumo consciente: 150.',
      icon: Icons.water_drop_outlined,
    ),
    'aguaPerdas': _FieldSpec(
      label: 'Perdas na distribuição',
      unit: '%',
      min: 10,
      max: 60,
      helper: 'Padrão 30%.',
      icon: Icons.plumbing,
    ),
    'energiaPico': _FieldSpec(
      label: 'Pico de demanda na subestação',
      unit: 'MW',
      min: 20,
      max: 48,
      helper: 'Padrão 44 MW. Capacidade simulada: 48 MW.',
      icon: Icons.bolt_outlined,
    ),
    'calor': _FieldSpec(
      label: 'Onda de calor (2+ dias)',
      unit: '°C',
      min: 28,
      max: 42,
      helper: 'Padrão 32 °C por dois dias seguidos ou mais.',
      icon: Icons.thermostat_outlined,
    ),
    'chuva': _FieldSpec(
      label: 'Chuva intensa',
      unit: 'mm/dia',
      min: 10,
      max: 150,
      helper: 'Padrão 40 mm em um dia.',
      icon: Icons.umbrella_outlined,
    ),
  };

  late final Map<String, TextEditingController> _controllers = {
    for (final key in _specs.keys) key: TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    _fill(context.read<SettingsProvider>().thresholds);
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _format(double v) => v == v.roundToDouble()
      ? v.toStringAsFixed(0)
      : v.toStringAsFixed(1).replaceAll('.', ',');

  void _fill(Thresholds t) {
    final json = t.toJson();
    for (final entry in _controllers.entries) {
      entry.value.text = _format((json[entry.key] as num).toDouble());
    }
  }

  double _value(String key) => Validators.parseNumber(_controllers[key]!.text)!;

  Future<void> _save() async {
    setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
    final messenger = ScaffoldMessenger.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) {
      messenger.showSnackBar(
        const SnackBar(
            content: Text('Há valores fora do intervalo permitido.')),
      );
      return;
    }
    final settings = context.read<SettingsProvider>();
    final navigator = Navigator.of(context);
    await settings.saveThresholds(Thresholds(
      aguaConsumo: _value('aguaConsumo'),
      aguaPerdas: _value('aguaPerdas'),
      energiaPico: _value('energiaPico'),
      calor: _value('calor'),
      chuva: _value('chuva'),
    ));
    messenger.showSnackBar(
      const SnackBar(
          content: Text('Limiares salvos. Os alertas foram recalculados.')),
    );
    navigator.pop();
  }

  Future<void> _reset() async {
    await context.read<SettingsProvider>().resetThresholds();
    _fill(Thresholds.defaults);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Limiares restaurados para o padrão.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Limiares de alerta')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: _autovalidate,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                'Os limiares definem quando um alerta é gerado. Eles são '
                'escolhidos por pessoas — o app nunca altera esses valores sozinho.',
                style: context.textStyles.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              for (final entry in _specs.entries) ...[
                TextFormField(
                  controller: _controllers[entry.key],
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
                  ],
                  decoration: AppInputs.decoration(
                    context,
                    label: entry.value.label,
                    suffix: entry.value.unit,
                    helper: '${entry.value.helper} Permitido: '
                        '${entry.value.min.toStringAsFixed(0)}–${entry.value.max.toStringAsFixed(0)}.',
                    icon: entry.value.icon,
                  ),
                  validator: (v) => Validators.numberInRange(
                    v,
                    min: entry.value.min,
                    max: entry.value.max,
                    unit: entry.value.unit,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              const HumanDecisionBanner(compact: true),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Salvar e recalcular alertas'),
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Restaurar padrão'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
