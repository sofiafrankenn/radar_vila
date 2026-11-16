import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:radar_vila/core/constants.dart';
import 'package:radar_vila/core/theme/app_inputs.dart';
import 'package:radar_vila/core/theme/app_spacing.dart';
import 'package:radar_vila/core/theme/theme_context.dart';
import 'package:radar_vila/core/utils/anonymizer.dart';
import 'package:radar_vila/core/utils/formatters.dart';
import 'package:radar_vila/core/utils/validators.dart';
import 'package:radar_vila/models/occurrence.dart';
import 'package:radar_vila/providers/occurrence_provider.dart';
import 'package:radar_vila/widgets/app_card.dart';

/// Formulário de registro de ocorrência pelo cidadão (com validação).
class OccurrenceFormScreen extends StatefulWidget {
  const OccurrenceFormScreen({super.key});

  @override
  State<OccurrenceFormScreen> createState() => _OccurrenceFormScreenState();
}

class _OccurrenceFormScreenState extends State<OccurrenceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionCtrl = TextEditingController();
  final _cepCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();

  OccurrenceCategory? _category;
  String? _region;
  DateTime? _date = DateTime.now();
  bool _submitting = false;
  AutovalidateMode _autovalidate = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    _dateCtrl.text = Fmt.date(_date!);
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    _cepCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year, now.month, now.day - 30),
      lastDate: now,
      helpText: 'Data da ocorrência',
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        _dateCtrl.text = Fmt.date(picked);
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _autovalidate = AutovalidateMode.onUserInteraction);
    final messenger = ScaffoldMessenger.of(context);

    if (!(_formKey.currentState?.validate() ?? false)) {
      messenger.showSnackBar(
        const SnackBar(
            content: Text('Corrija os campos destacados em vermelho.')),
      );
      return;
    }

    setState(() => _submitting = true);
    final provider = context.read<OccurrenceProvider>();
    final navigator = Navigator.of(context);
    final cep = _cepCtrl.text.trim();

    final occurrence = Occurrence(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      category: _category!,
      region: _region!,
      description: _descriptionCtrl.text.trim(),
      date: _date!,
      cepPrefix: cep.isEmpty ? null : Anonymizer.cepPrefix(cep),
      reporterAlias: Anonymizer.randomAlias(),
      createdAt: DateTime.now(),
    );

    try {
      await provider.add(occurrence);
      messenger.showSnackBar(
        SnackBar(
            content: Text(
                'Ocorrência registrada como ${occurrence.reporterAlias}.')),
      );
      navigator.pop();
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
            content: Text('Não foi possível salvar. Tente novamente.')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: AppSpacing.lg);

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar ocorrência')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: _autovalidate,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.privacy_tip_outlined,
                        color: context.colors.primary),
                    const SizedBox(width: AppSpacing.md),
                    const Expanded(
                      child: Text(
                        'Registro anônimo: não pedimos nome nem contato. Você '
                        'receberá um apelido aleatório e o CEP é guardado só '
                        'com os 5 primeiros dígitos.',
                      ),
                    ),
                  ],
                ),
              ),
              gap,
              DropdownButtonFormField<OccurrenceCategory>(
                initialValue: _category,
                isExpanded: true,
                decoration: AppInputs.decoration(
                  context,
                  label: 'Categoria *',
                  icon: Icons.category_outlined,
                ),
                items: [
                  for (final c in OccurrenceCategory.values)
                    DropdownMenuItem(value: c, child: Text(c.label)),
                ],
                onChanged: (v) => setState(() => _category = v),
                validator: (v) => v == null ? 'Selecione uma categoria.' : null,
              ),
              gap,
              DropdownButtonFormField<String>(
                initialValue: _region,
                isExpanded: true,
                decoration: AppInputs.decoration(
                  context,
                  label: 'Região do bairro *',
                  icon: Icons.map_outlined,
                  helper: 'Usamos só a região, nunca o endereço exato.',
                ),
                items: [
                  for (final r in TerritoryInfo.regions)
                    DropdownMenuItem(value: r, child: Text(r)),
                ],
                onChanged: (v) => setState(() => _region = v),
                validator: (v) => v == null ? 'Selecione a região.' : null,
              ),
              gap,
              TextFormField(
                controller: _dateCtrl,
                readOnly: true,
                onTap: _pickDate,
                decoration: AppInputs.decoration(
                  context,
                  label: 'Data *',
                  icon: Icons.event_outlined,
                  helper: 'Toque para escolher. Até 30 dias atrás.',
                ),
                validator: (_) => Validators.occurrenceDate(_date),
              ),
              gap,
              TextFormField(
                controller: _descriptionCtrl,
                maxLines: 4,
                maxLength: Validators.descriptionMax,
                textCapitalization: TextCapitalization.sentences,
                decoration: AppInputs.decoration(
                  context,
                  label: 'Descrição *',
                  hint:
                      'Ex.: vazamento na calçada perto da escola, água correndo há 2 dias.',
                  helper: 'Não inclua nome, telefone, e-mail ou documentos.',
                ),
                validator: Validators.description,
              ),
              gap,
              TextFormField(
                controller: _cepCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                decoration: AppInputs.decoration(
                  context,
                  label: 'CEP (opcional)',
                  icon: Icons.pin_drop_outlined,
                  hint: 'Somente números',
                  helper:
                      'Guardamos apenas os 5 primeiros dígitos (ex.: 04101-***).',
                ),
                validator: Validators.optionalCep,
              ),
              gap,
              FormField<bool>(
                initialValue: false,
                validator: (v) => v == true
                    ? null
                    : 'Confirme que a descrição não contém dados pessoais.',
                builder: (field) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CheckboxListTile(
                      value: field.value ?? false,
                      onChanged: (v) => field.didChange(v ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                          'Confirmo que a descrição não contém dados pessoais *'),
                    ),
                    if (field.hasError)
                      Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.md),
                        child: Text(
                          field.errorText!,
                          style: context.textStyles.bodySmall
                              ?.copyWith(color: context.colors.error),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(_submitting ? 'Salvando…' : 'Registrar ocorrência'),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('* campos obrigatórios', style: context.mutedSmall),
            ],
          ),
        ),
      ),
    );
  }
}
