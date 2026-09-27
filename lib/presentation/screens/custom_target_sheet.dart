import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/logic/target_validator.dart';
import '../../l10n/app_localizations.dart';

/// Bottom sheet for entering a custom alarm target between 1% and 100%.
/// Returns the validated integer via [Navigator.pop], or null if cancelled.
class CustomTargetSheet extends StatefulWidget {
  const CustomTargetSheet({super.key, required this.initialValue});

  final int initialValue;

  static Future<int?> show(BuildContext context, {required int initialValue}) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CustomTargetSheet(initialValue: initialValue),
    );
  }

  @override
  State<CustomTargetSheet> createState() => _CustomTargetSheetState();
}

class _CustomTargetSheetState extends State<CustomTargetSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue.toString());
  final _validator = const TargetValidator();
  String? _errorKey;

  void _submit() {
    final parsed = int.tryParse(_controller.text);
    final result = _validator.validate(parsed);
    if (!result.isValid) {
      setState(() => _errorKey = result.errorKey);
      return;
    }
    Navigator.of(context).pop(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final errorText = switch (_errorKey) {
      'errorTargetRequired' => l10n.errorTargetRequired,
      'errorTargetOutOfRange' => l10n.errorTargetOutOfRange,
      _ => null,
    };

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.customTargetTitle, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            l10n.customTargetDescription,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            decoration: InputDecoration(
              labelText: l10n.customTargetFieldLabel,
              suffixText: '%',
              errorText: errorText,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(onPressed: _submit, child: Text(l10n.save)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
