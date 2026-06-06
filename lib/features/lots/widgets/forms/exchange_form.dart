import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/exchange.dart';
import '../../../../core/models/holding.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/form_dialog.dart';

class ExchangeFormDialog extends ConsumerStatefulWidget {
  const ExchangeFormDialog({
    super.key,
    required this.lotId,
    required this.holdings,
  });

  final String lotId;
  final List<Holding> holdings;

  @override
  ConsumerState<ExchangeFormDialog> createState() => _ExchangeFormDialogState();
}

class _ExchangeFormDialogState extends ConsumerState<ExchangeFormDialog> {
  Holding? _source;
  final _inputWeight = TextEditingController();
  final _outputWeight = TextEditingController();
  final _outputPurity = TextEditingController(text: '9160');
  final _expense = TextEditingController();
  final _counterparty = TextEditingController();
  final _notes = TextEditingController();
  bool _saving = false;

  List<Holding> get _active =>
      widget.holdings.where((h) => h.isInHand).toList();

  @override
  void initState() {
    super.initState();
    final active = _active;
    if (active.isNotEmpty) {
      _source = active.first;
      _inputWeight.text = active.first.weightG.toString();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _onSourceChanged(Holding? h) {
    if (h == null) return;
    setState(() {
      _source = h;
      _inputWeight.text = h.weightG.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final active = _active;
    if (active.isEmpty) {
      return FormDialog(
        title: 'Exchange Gold',
        children: [
          const Text('No holdings available. Add a purchase first.'),
        ],
        onSave: null,
      );
    }
    return FormDialog(
      title: 'Exchange Gold',
      saving: _saving,
      onSave: _save,
      children: [
        DropdownButtonFormField<Holding>(
          value: _source,
          decoration: const InputDecoration(labelText: 'Source Holding'),
          items: active
              .map(
                (h) => DropdownMenuItem(
                  value: h,
                  child: Text(
                    '${formatWeight(h.weightG)} @ ${formatPurityLabel(h.purity)}',
                  ),
                ),
              )
              .toList(),
          onChanged: _onSourceChanged,
        ),
        TextField(
          controller: _inputWeight,
          decoration: InputDecoration(
            labelText: 'Input Weight (g)',
            helperText: _source != null
                ? 'Max ${formatWeight(_source!.weightG)}'
                : null,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        TextField(
          controller: _outputWeight,
          decoration: const InputDecoration(labelText: 'Output Weight (g)'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        TextField(
          controller: _outputPurity,
          decoration: const InputDecoration(
            labelText: 'Output Purity',
            hintText: 'e.g. 9160 = 91.60%',
          ),
          keyboardType: TextInputType.number,
        ),
        TextField(
          controller: _expense,
          decoration: const InputDecoration(labelText: 'Exchange Expense (MYR)'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        TextField(
          controller: _counterparty,
          decoration: const InputDecoration(labelText: 'Counterparty'),
        ),
        TextField(
          controller: _notes,
          decoration: const InputDecoration(labelText: 'Notes'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final source = _source;
    if (source == null) {
      _showError('Select a source holding');
      return;
    }
    final inputWeight = double.tryParse(_inputWeight.text) ?? 0;
    final outputWeight = double.tryParse(_outputWeight.text) ?? 0;
    final outputPurity = double.tryParse(_outputPurity.text) ?? 0;
    final expense = double.tryParse(_expense.text) ?? 0;
    if (inputWeight <= 0) {
      _showError('Enter input weight');
      return;
    }
    if (inputWeight > source.weightG + 0.0001) {
      _showError('Input weight exceeds holding balance');
      return;
    }
    if (outputWeight <= 0) {
      _showError('Enter output weight');
      return;
    }
    if (outputPurity <= 0) {
      _showError('Enter output purity');
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(lotRepositoryProvider);
      await repo.addExchange(Exchange(
        id: '',
        lotId: widget.lotId,
        sourceHoldingId: source.id,
        inputWeightG: inputWeight,
        outputWeightG: outputWeight,
        outputPurity: outputPurity,
        expenseMyr: expense,
        counterparty:
            _counterparty.text.isEmpty ? null : _counterparty.text.trim(),
        exchangeDate: DateTime.now(),
        notes: _notes.text.isEmpty ? null : _notes.text,
        createdAt: DateTime.now(),
      ));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _showError(e.toString());
      setState(() => _saving = false);
    }
  }
}
