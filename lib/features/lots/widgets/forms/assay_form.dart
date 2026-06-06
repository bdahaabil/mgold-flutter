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
    this.initial,
  });

  final String lotId;
  final List<Purchase> purchases;
  final AssayResult? initial;

  bool get isEditing => initial != null;

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

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _purchaseId = initial.purchaseId;
      _purity.text = initial.actualPurity.toString();
      _weight.text = initial.actualWeightG.toString();
      _lab.text = initial.assayLab ?? '';
      _notes.text = initial.notes ?? '';
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: widget.isEditing ? 'Edit Assay' : 'Record Assay',
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
    try {
      final repo = ref.read(lotRepositoryProvider);
      final assay = AssayResult(
        id: widget.initial?.id ?? '',
        lotId: widget.lotId,
        purchaseId: _purchaseId ??
            (widget.purchases.isNotEmpty ? widget.purchases.first.id : null),
        actualPurity: purity,
        actualWeightG: weight,
        assayLab: _lab.text.isEmpty ? null : _lab.text,
        adjustmentMyr: widget.initial?.adjustmentMyr ?? 0,
        assayDate: widget.initial?.assayDate ?? DateTime.now(),
        notes: _notes.text.isEmpty ? null : _notes.text,
        createdAt: widget.initial?.createdAt ?? DateTime.now(),
      );
      if (widget.isEditing) {
        await repo.updateAssay(assay);
      } else {
        await repo.addAssay(assay);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _showError('Failed to save assay: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
