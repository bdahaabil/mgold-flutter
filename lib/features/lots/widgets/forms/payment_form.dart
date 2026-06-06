import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/enums.dart';
import '../../../../core/models/payment.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/providers/supplier_providers.dart';
import '../../../../core/widgets/form_dialog.dart';

class PaymentFormDialog extends ConsumerStatefulWidget {
  const PaymentFormDialog({super.key, required this.lotId});
  final String lotId;

  @override
  ConsumerState<PaymentFormDialog> createState() => _PaymentFormDialogState();
}

class _PaymentFormDialogState extends ConsumerState<PaymentFormDialog> {
  PaymentDirection _direction = PaymentDirection.out;
  String? _supplierId;
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final suppliers = ref.watch(suppliersProvider);
    return FormDialog(
      title: 'Add Payment',
      saving: _saving,
      onSave: _save,
      children: [
        DropdownButtonFormField<PaymentDirection>(
          value: _direction,
          decoration: const InputDecoration(labelText: 'Direction'),
          items: PaymentDirection.values
              .map((d) => DropdownMenuItem(value: d, child: Text(d.label)))
              .toList(),
          onChanged: (v) => setState(() => _direction = v ?? PaymentDirection.out),
        ),
        if (_direction == PaymentDirection.out)
          suppliers.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('$e'),
            data: (list) => DropdownButtonFormField<String>(
              value: _supplierId ?? (list.isNotEmpty ? list.first.id : null),
              decoration: const InputDecoration(labelText: 'Supplier'),
              items: list
                  .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                  .toList(),
              onChanged: (v) => setState(() => _supplierId = v),
            ),
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
    if (_direction == PaymentDirection.out && _supplierId == null) return;
    setState(() => _saving = true);
    final repo = ref.read(lotRepositoryProvider);
    await repo.addPayment(Payment(
      id: '',
      lotId: widget.lotId,
      direction: _direction,
      supplierId: _direction == PaymentDirection.out ? _supplierId : null,
      amountMyr: amount,
      paymentDate: DateTime.now(),
      notes: _notes.text.isEmpty ? null : _notes.text,
      createdAt: DateTime.now(),
    ));
    if (mounted) Navigator.pop(context, true);
  }
}
