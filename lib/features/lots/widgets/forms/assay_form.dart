import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/assay_result.dart';
import '../../../../core/models/purchase.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/widgets/form_dialog.dart';

class AssayFormDialog extends ConsumerStatefulWidget {
  const AssayFormDialog({
    super.key,
    required this.lotId,
    required this.purchases,
  });
  final String lotId;
  final List<Purchase> purchases;

  @override
  ConsumerState<AssayFormDialog> createState() => _AssayFormDialogState();
}

class _AssayFormDialogState extends ConsumerState<AssayFormDialog> {
  String? _purchaseId;
  final _purity = TextEditingController(text: '9990');
  final _weight = TextEditingController();
  final _lab = TextEditingController();
  final _notes = TextEditingController();
  bool _saving = false;

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: 'Record Assay',
      saving: _saving,
      onSave: _save,
      children: [
        if (widget.purchases.isNotEmpty)
          DropdownButtonFormField<String>(
            value: _purchaseId ?? widget.purchases.first.id,
            decoration: const InputDecoration(labelText: 'Linked Purchase'),
            items: widget.purchases
                .map((p) => DropdownMenuItem(
                      value: p.id,
                      child: Text('${p.weightG}g @ ${p.claimedPurity}'),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _purchaseId = v),
          ),
        TextField(
          controller: _purity,
          decoration: const InputDecoration(
            labelText: 'Actual Purity',
            hintText: 'e.g. 9999 = 100%, 9990 = 99.90%',
            helperText: 'Applies to whole lot purity',
          ),
          keyboardType: TextInputType.number,
        ),
        TextField(
          controller: _weight,
          decoration: const InputDecoration(
            labelText: 'Sample Weight (g)',
            helperText: 'Weight of sample sent for testing',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        TextField(
          controller: _lab,
          decoration: const InputDecoration(labelText: 'Assay Lab'),
        ),
        TextField(
          controller: _notes,
          decoration: const InputDecoration(labelText: 'Notes'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final purity = double.tryParse(_purity.text) ?? 0;
    final weight = double.tryParse(_weight.text) ?? 0;
    if (purity <= 0 || weight <= 0) {
      _showError('Enter valid purity and sample weight');
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(lotRepositoryProvider);
    await repo.addAssay(AssayResult(
      id: '',
      lotId: widget.lotId,
      purchaseId: _purchaseId ?? (widget.purchases.isNotEmpty ? widget.purchases.first.id : null),
      actualPurity: purity,
      actualWeightG: weight,
      assayLab: _lab.text.isEmpty ? null : _lab.text,
      adjustmentMyr: 0,
      assayDate: DateTime.now(),
      notes: _notes.text.isEmpty ? null : _notes.text,
      createdAt: DateTime.now(),
    ));
    if (mounted) Navigator.pop(context, true);
  }
}
