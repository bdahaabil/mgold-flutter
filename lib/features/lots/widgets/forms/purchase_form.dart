import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/purchase.dart';
import '../../../../core/models/supplier.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/providers/supplier_providers.dart';
import '../../../../core/widgets/form_dialog.dart';

class PurchaseFormDialog extends ConsumerStatefulWidget {
  const PurchaseFormDialog({super.key, required this.lotId});
  final String lotId;

  @override
  ConsumerState<PurchaseFormDialog> createState() => _PurchaseFormDialogState();
}

class _PurchaseFormDialogState extends ConsumerState<PurchaseFormDialog> {
  String? _supplierId;
  final _purity = TextEditingController(text: '9990');
  final _weight = TextEditingController();
  final _price = TextEditingController();
  final _notes = TextEditingController();
  bool _saving = false;

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _seedDefaultSupplier(List<Supplier> list) {
    if (list.isEmpty || _supplierId != null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _supplierId == null) {
        setState(() => _supplierId = list.first.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = ref.watch(suppliersProvider);
    return FormDialog(
      title: 'Add Purchase',
      saving: _saving,
      onSave: _save,
      children: [
        suppliers.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('$e'),
          data: (list) {
            final items = list.cast<Supplier>();
            _seedDefaultSupplier(items);
            return DropdownButtonFormField<String>(
              value: _supplierId ?? (items.isNotEmpty ? items.first.id : null),
              decoration: const InputDecoration(labelText: 'Supplier'),
              items: items
                  .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                  .toList(),
              onChanged: (v) => setState(() => _supplierId = v),
            );
          },
        ),
        TextField(
          controller: _purity,
          decoration: const InputDecoration(
            labelText: 'Claimed Purity',
            hintText: 'e.g. 9999 = 100%, 9990 = 99.90%',
          ),
          keyboardType: TextInputType.number,
        ),
        TextField(
          controller: _weight,
          decoration: const InputDecoration(labelText: 'Weight (g)'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        TextField(
          controller: _price,
          decoration: const InputDecoration(labelText: 'Price per g (MYR)'),
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
    final suppliers = ref.read(suppliersProvider).valueOrNull?.cast<Supplier>() ?? [];
    final supplierId = _supplierId ?? (suppliers.isNotEmpty ? suppliers.first.id : null);
    if (supplierId == null) {
      _showError('Please add a supplier first');
      return;
    }
    final weight = double.tryParse(_weight.text.trim()) ?? 0;
    final price = double.tryParse(_price.text.trim()) ?? 0;
    final purity = double.tryParse(_purity.text.trim()) ?? 0;
    if (weight <= 0) {
      _showError('Enter a valid weight (g)');
      return;
    }
    if (price <= 0) {
      _showError('Enter a valid price per g (MYR)');
      return;
    }
    if (purity <= 0) {
      _showError('Enter a valid claimed purity');
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(lotRepositoryProvider);
      await repo.addPurchase(Purchase(
        id: '',
        lotId: widget.lotId,
        supplierId: supplierId,
        claimedPurity: purity,
        weightG: weight,
        pricePerG: price,
        totalMyr: weight * price,
        purchaseDate: DateTime.now(),
        notes: _notes.text.isEmpty ? null : _notes.text,
        createdAt: DateTime.now(),
      ));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _showError('Failed to save purchase: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
