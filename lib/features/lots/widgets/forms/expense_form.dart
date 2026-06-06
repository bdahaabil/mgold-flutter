import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/enums.dart';
import '../../../../core/models/expense.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/widgets/form_dialog.dart';

class ExpenseFormDialog extends ConsumerStatefulWidget {
  const ExpenseFormDialog({super.key, required this.lotId});
  final String lotId;

  @override
  ConsumerState<ExpenseFormDialog> createState() => _ExpenseFormDialogState();
}

class _ExpenseFormDialogState extends ConsumerState<ExpenseFormDialog> {
  ExpenseType _type = ExpenseType.assay;
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: 'Add Expense',
      saving: _saving,
      onSave: _save,
      children: [
        DropdownButtonFormField<ExpenseType>(
          value: _type,
          decoration: const InputDecoration(labelText: 'Type'),
          items: ExpenseType.values
              .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
              .toList(),
          onChanged: (v) => setState(() => _type = v ?? ExpenseType.other),
        ),
        TextField(
          controller: _amount,
          decoration: const InputDecoration(labelText: 'Amount (MYR)'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        TextField(
          controller: _notes,
          decoration: const InputDecoration(labelText: 'Notes'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amount.text) ?? 0;
    if (amount <= 0) return;
    setState(() => _saving = true);
    final repo = ref.read(lotRepositoryProvider);
    await repo.addExpense(Expense(
      id: '',
      lotId: widget.lotId,
      expenseType: _type,
      amountMyr: amount,
      expenseDate: DateTime.now(),
      notes: _notes.text.isEmpty ? null : _notes.text,
      createdAt: DateTime.now(),
    ));
    if (mounted) Navigator.pop(context, true);
  }
}
