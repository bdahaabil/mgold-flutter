import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/enums.dart';
import '../../../../core/models/holding.dart';
import '../../../../core/models/sale.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/form_dialog.dart';

class SaleFormDialog extends ConsumerStatefulWidget {
  const SaleFormDialog({
    super.key,
    required this.lotId,
    this.holdings = const [],
  });

  final String lotId;
  final List<Holding> holdings;

  @override
  ConsumerState<SaleFormDialog> createState() => _SaleFormDialogState();
}

class _SaleFormDialogState extends ConsumerState<SaleFormDialog> {
  SaleType _type = SaleType.direct;
  Holding? _holding;
  final _weight = TextEditingController();
  final _purity = TextEditingController(text: '9990');
  final _price = TextEditingController();
  final _customer = TextEditingController();
  final _notes = TextEditingController();
  bool _saving = false;

  List<Holding> get _active =>
      widget.holdings.where((h) => h.isInHand).toList();

  @override
  void initState() {
    super.initState();
    final active = _active;
    if (active.isNotEmpty) _applyHolding(active.first);
  }

  void _applyHolding(Holding h) {
    setState(() {
      _holding = h;
      _purity.text = h.purity.toString();
      _weight.text = h.weightG.toString();
    });
  }

  double? get _estimatedCogs {
    final h = _holding;
    final weight = double.tryParse(_weight.text) ?? 0;
    if (h == null || weight <= 0) return null;
    return h.costPerG * weight;
  }

  double? get _estimatedProfit {
    final weight = double.tryParse(_weight.text) ?? 0;
    final price = double.tryParse(_price.text) ?? 0;
    final cogs = _estimatedCogs;
    if (weight <= 0 || price <= 0) return null;
    return weight * price - (cogs ?? 0);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final active = _active;
    final cogs = _estimatedCogs;
    final profit = _estimatedProfit;

    final fields = <Widget>[
      if (active.isNotEmpty)
        DropdownButtonFormField<Holding>(
          value: _holding,
          decoration: const InputDecoration(labelText: 'Holding'),
          items: active
              .map(
                (h) => DropdownMenuItem(
                  value: h,
                  child: Text(
                    '${h.label}: ${formatWeight(h.weightG)} @ ${formatPurityLabel(h.purity)}',
                  ),
                ),
              )
              .toList(),
          onChanged: (h) {
            if (h != null) _applyHolding(h);
          },
        ),
      DropdownButtonFormField<SaleType>(
        value: _type,
        decoration: const InputDecoration(labelText: 'Sale Type'),
        items: SaleType.values
            .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
            .toList(),
        onChanged: (v) {
          if (v != null) {
            setState(() {
              _type = v;
              if (_holding == null) {
                if (v == SaleType.refined) _purity.text = '9950';
                if (v == SaleType.exchange916) _purity.text = '9160';
              }
            });
          }
        },
      ),
      TextField(
        controller: _customer,
        decoration: const InputDecoration(labelText: 'Customer'),
      ),
      TextField(
        controller: _weight,
        decoration: InputDecoration(
          labelText: 'Weight (g)',
          helperText: _holding != null
              ? 'Max ${formatWeight(_holding!.weightG)}'
              : null,
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) => setState(() {}),
      ),
      TextField(
        controller: _purity,
        decoration: const InputDecoration(
          labelText: 'Purity',
          hintText: 'e.g. 9999 = 100%, 9990 = 99.90%',
        ),
        keyboardType: TextInputType.number,
        readOnly: _holding != null,
      ),
      TextField(
        controller: _price,
        decoration: const InputDecoration(labelText: 'Price per g (MYR)'),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) => setState(() {}),
      ),
      if (cogs != null)
        Text('Est. COGS: ${formatMyr(cogs)}',
            style: Theme.of(context).textTheme.bodyMedium),
      if (profit != null)
        Text(
          'Est. Profit: ${formatMyr(profit)}',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: profit >= 0 ? Colors.green : Colors.red,
              ),
        ),
      TextField(
        controller: _notes,
        decoration: const InputDecoration(labelText: 'Notes'),
      ),
    ];

    return FormDialog(
      title: 'Add Sale',
      saving: _saving,
      onSave: _save,
      children: fields,
    );
  }

  Future<void> _save() async {
    final weight = double.tryParse(_weight.text) ?? 0;
    final price = double.tryParse(_price.text) ?? 0;
    final purity = double.tryParse(_purity.text) ?? 0;
    if (weight <= 0 || price <= 0 || _customer.text.isEmpty) {
      _showError('Enter customer, weight, and price');
      return;
    }
    if (_holding != null && weight > _holding!.weightG + 0.0001) {
      _showError('Weight exceeds holding balance');
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(lotRepositoryProvider);
    await repo.addSale(Sale(
      id: '',
      lotId: widget.lotId,
      saleType: _type,
      weightG: weight,
      purity: purity,
      pricePerG: price,
      totalMyr: weight * price,
      customerName: _customer.text.trim(),
      saleDate: DateTime.now(),
      holdingId: _holding?.id,
      notes: _notes.text.isEmpty ? null : _notes.text,
      createdAt: DateTime.now(),
    ));
    if (mounted) Navigator.pop(context, true);
  }
}
