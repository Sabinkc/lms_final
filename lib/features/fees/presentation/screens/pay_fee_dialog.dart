import 'package:flutter/material.dart';

import '../providers/self_fee_provider.dart';
import '../../../../shared/widgets/success_overlay.dart';
import '../../../../shared/widgets/form_sheet.dart';

/// Student/Parent: submit a fee payment for manual verification
/// (`implementation_backlog.md` E7-F4). **No payment-method selector** —
/// confirmed by reading `paymentController.js`'s `submitFeePayment`
/// directly: it destructures only `{ feeId, installmentId, phoneNumber,
/// transactionPin }` from the body and always hardcodes `method: "esewa"`
/// on the created `Payment`, ignoring anything else submitted. The
/// `PaymentSchema`'s `method` enum (`esewa|khalti|bank_qr|cash`) exists but
/// this endpoint never reads a client-supplied value for it — building a
/// selector here would let the payer pick something the backend silently
/// discards, so the form only asks for what's actually used: the phone
/// number and confirmation PIN/reference their payment app showed.
Future<void> showPayFeeDialog(
  BuildContext context,
  SelfFeeProvider provider, {
  required String feeId,
  String? installmentId,
  required double amount,
}) async {
  final phoneController = TextEditingController();
  final pinController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  await showFormSheet<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => FormSheet(
        title: const Text('Submit Payment'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Amount: Rs ${amount.toStringAsFixed(0)}'),
              const SizedBox(height: 4),
              Text(
                'After paying via eSewa, Khalti, or bank transfer, enter the phone number and the '
                'transaction PIN / reference code your payment confirmation showed. The school will '
                'verify and approve it manually.',
                style: Theme.of(dialogContext).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone number'),
                keyboardType: TextInputType.phone,
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Phone number is required' : null,
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: pinController,
                decoration: const InputDecoration(labelText: 'Transaction PIN / reference code'),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'This is required' : null,
              ),
              if (provider.paymentActionError != null) ...[
                const SizedBox(height: 12),
                Text(
                  provider.paymentActionError!.message,
                  style: TextStyle(color: Theme.of(dialogContext).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: provider.isSubmittingPayment
                ? null
                : () async {
                    if (!formKey.currentState!.validate()) return;
                    final succeeded = await provider.submitPayment(
                      feeId: feeId,
                      installmentId: installmentId,
                      phoneNumber: phoneController.text.trim(),
                      transactionPin: pinController.text.trim(),
                    );
                    if (succeeded && dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                      if (context.mounted) {
                        await showSuccess(
                          context,
                          title: 'Payment sent',
                          subtitle: 'The school will confirm it shortly.',
                        );
                      }
                      return;
                    }
                    setDialogState(() {});
                  },
            child: provider.isSubmittingPayment
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Submit'),
          ),
        ],
      ),
    ),
  );
}
