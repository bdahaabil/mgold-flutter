import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/design/app_spacing.dart';
import '../../app/design/tokens.dart';

class FormDialog extends StatelessWidget {
  const FormDialog({
    super.key,
    required this.title,
    required this.children,
    this.onSave,
    this.onCancel,
    this.saving = false,
    this.saveLabel = 'Save',
    this.scrollable = true,
  });

  final String title;
  final List<Widget> children;
  final VoidCallback? onSave;
  final VoidCallback? onCancel;
  final bool saving;
  final String saveLabel;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _withGaps(children),
    );

    return AlertDialog(
      title: Text(title),
      content: scrollable
          ? SingleChildScrollView(child: body)
          : body,
      actions: [
        TextButton(
          onPressed: saving ? null : onCancel ?? () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: saving ? null : onSave,
          child: saving
              ? SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(saveLabel),
        ),
      ],
    );
  }

  List<Widget> _withGaps(List<Widget> widgets) {
    if (widgets.isEmpty) return widgets;
    final result = <Widget>[widgets.first];
    for (var i = 1; i < widgets.length; i++) {
      result.add(VGap(AppTokens.fieldGap));
      result.add(widgets[i]);
    }
    return result;
  }
}

/// Builds a vertically spaced form field list.
List<Widget> formFields(List<Widget> fields) => fields;
