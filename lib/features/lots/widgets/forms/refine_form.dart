import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/refining_job.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/widgets/form_dialog.dart';

class RefineFormDialog extends ConsumerStatefulWidget {
  const RefineFormDialog({super.key, required this.lotId});
  final String lotId;

  @override
  ConsumerState<RefineFormDialog> createState() => _RefineFormDialogState();
}

class _RefineFormDialogState extends ConsumerState<RefineFormDialog> {
  final _input = TextEditingController();
  final _output = TextEditingController();
  final _purity = TextEditingController(text: '9950');
  final _refinery = TextEditingController();
  bool _received = false;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: 'Refining Job',
      saving: _saving,
      onSave: _save,
      children: [
        TextField(
          controller: _input,
          decoration: const InputDecoration(labelText: 'Input Weight (g)'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Received from refinery'),
          value: _received,
          onChanged: (v) => setState(() => _received = v),
        ),
        if (_received) ...[
          TextField(
            controller: _output,
            decoration: const InputDecoration(labelText: 'Output Weight (g)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          TextField(
            controller: _purity,
            decoration: const InputDecoration(
              labelText: 'Output Purity',
              hintText: 'e.g. 9999 = 100%, 9950 = 99.50%',
            ),
            keyboardType: TextInputType.number,
          ),
        ],
        TextField(
          controller: _refinery,
          decoration: const InputDecoration(labelText: 'Refinery'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final input = double.tryParse(_input.text) ?? 0;
    if (input <= 0) return;
    setState(() => _saving = true);
    final repo = ref.read(lotRepositoryProvider);
    await repo.addRefining(RefiningJob(
      id: '',
      lotId: widget.lotId,
      inputWeightG: input,
      outputWeightG: _received ? double.tryParse(_output.text) : null,
      outputPurity: _received ? double.tryParse(_purity.text) : null,
      refinery: _refinery.text.isEmpty ? null : _refinery.text,
      sentDate: DateTime.now(),
      receivedDate: _received ? DateTime.now() : null,
      createdAt: DateTime.now(),
    ));
    if (mounted) Navigator.pop(context, true);
  }
}
