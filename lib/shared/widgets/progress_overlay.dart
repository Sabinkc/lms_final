import 'package:flutter/material.dart';

/// Runs [action] behind a blocking "please wait" dialog and returns its
/// result. For API calls whose button has no spinner of its own — deletes
/// after a confirm dialog, exports, logout, group management — so the user
/// always sees something happening and can't trigger the call twice.
/// Buttons inside forms keep their own inline spinner instead.
Future<T> runWithProgress<T>(
  BuildContext context,
  Future<T> Function() action, {
  String message = 'Please wait…',
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  var showing = true;
  showDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    builder: (_) => PopScope(canPop: false, child: ProgressDialog(message: message)),
  ).whenComplete(() => showing = false);
  try {
    return await action();
  } finally {
    if (showing) navigator.pop();
  }
}

class ProgressDialog extends StatelessWidget {
  final String message;

  const ProgressDialog({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
            const SizedBox(width: 20),
            Flexible(child: Text(message, style: Theme.of(context).textTheme.bodyLarge)),
          ],
        ),
      ),
    );
  }
}
