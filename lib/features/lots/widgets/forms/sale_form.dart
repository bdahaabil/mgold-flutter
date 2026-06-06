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
    this.initial,
  });

  final String lotId;
  final List<Holding> holdings;
  final Sale? initial;

  bool get isEditing => initial != null;

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

  List<Holding> get _holdingsForDropdown {
    final active = _active;
    final holdingId = widget.initial?.holdingId;
    if (holdingId == null) return active;
    final linked = widget.holdings.where((h) => h.id == holdingId).toList();
    if (linked.isEmpty) return active;
    if (active.any((h) => h.id == holdingId)) return active;
    return [...active, linked.first];
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _type = initial.saleType;
      _customer.text = initial.customerName;
      _weight.text = initial.weightG.toString();
      _purity.text = initial.purity.toString();
      _price.text = initial.pricePerG.toString();
      _notes.text = initial.notes ?? '';
      if (initial.holdingId != null) {
        final linked = widget.holdings
            .where((h) => h.id == initial.holdingId)
            .toList();
        if (linked.isNotEmpty) _holding = linked.first;
      }
    } else {
      final active = _active;
      if (active.isNotEmpty) _applyHolding(active.first);
    }
  }

  void _applyHolding(Holding h) {
    setState(() {
      _holding = h;
      if (!widget.isEditing) {
        _purity.text = h.purity.toString();
        _weight.text = h.weightG.toString();
      }
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
    final holdings = _holdingsForDropdown;
    final cogs = _estimatedCogs;
    final profit = _estimatedProfit;

    final fields = <Widget>[
      if (holdings.isNotEmpty)
        DropdownButtonFormField<Holding>(
          value: _holding,
          decoration: const InputDecoration(labelText: 'Holding'),
          items: holdings
              .map(
                (h) => DropdownMenuItem(
                  value: h,
                  child: Text(
                    '${h.label}: ${formatWeight(h.weightG)} @ ${formatPurityLabel(h.purity)}',
                  ),
                ),
              )
              .toList(),
          onChanged: widget.isEditing
              ? null
              : (h) {
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
          helperText: _holding != null && !widget.isEditing
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
        readOnly: _holding != null && !widget.isEditing,
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
      title: widget.isEditing ? 'Edit Sale' : 'Add Sale',
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
    if (!widget.isEditing &&
        _holding != null &&
        weight > _holding!.weightG + 0.0001) {
      _showError('Weight exceeds holding balance');
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(lotRepositoryProvider);
      final cogs = _estimatedCogs ?? widget.initial?.cogsMyr;
      final sale = Sale(
        id: widget.initial?.id ?? '',
        lotId: widget.lotId,
        saleType: _type,
        weightG: weight,
        purity: purity,
        pricePerG: price,
        totalMyr: weight * price,
        customerName: _customer.text.trim(),
        saleDate: widget.initial?.saleDate ?? DateTime.now(),
        holdingId: _holding?.id ?? widget.initial?.holdingId,
        cogsMyr: cogs,
        notes: _notes.text.isEmpty ? null : _notes.text,
        createdAt: widget.initial?.createdAt ?? DateTime.now(),
        lotNumber: widget.initial?.lotNumber,
      );
      if (widget.isEditing) {
        await repo.updateSale(sale);
      } else {
        await repo.addSale(sale);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _showError('Failed to save sale: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
