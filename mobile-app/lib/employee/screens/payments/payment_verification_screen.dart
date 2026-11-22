import 'package:flutter/material.dart';

import '../orders/incoming_orders_screen.dart';

class PaymentVerificationScreen extends StatefulWidget {
  const PaymentVerificationScreen({
    super.key,
    this.payments,
    this.isLoading = false,
  });

  static const routeName = '/employee-payment-verification';
  static final samplePayments = [
    PaymentVerificationRecord(
      order: IncomingOrdersScreen.sampleOrders[0],
      paymentMethod: 'GCash',
      referenceNumber: 'SAMPLE-GCASH-1042',
    ),
    PaymentVerificationRecord(
      order: IncomingOrdersScreen.sampleOrders[1],
      paymentMethod: 'Maya',
      referenceNumber: 'SAMPLE-MAYA-1041',
    ),
    PaymentVerificationRecord(
      order: IncomingOrdersScreen.sampleOrders[2],
      paymentMethod: 'GCash',
      referenceNumber: 'SAMPLE-GCASH-1040',
    ),
  ];

  final List<PaymentVerificationRecord>? payments;
  final bool isLoading;

  @override
  State<PaymentVerificationScreen> createState() =>
      _PaymentVerificationScreenState();
}

class _PaymentVerificationScreenState extends State<PaymentVerificationScreen> {
  late final List<PaymentVerificationRecord> _payments =
      List.of(widget.payments ?? PaymentVerificationScreen.samplePayments);

  void _openDetails(int index) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => _PaymentDetailsSheet(
        payment: _payments[index],
        onDecision: (decision) => _applyDecision(index, decision, sheetContext),
      ),
    );
  }

  void _applyDecision(
    int index,
    PaymentVerificationStatus decision,
    BuildContext sheetContext,
  ) {
    setState(() {
      _payments[index] = _payments[index].copyWith(status: decision);
    });
    Navigator.pop(sheetContext);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Demo only: marked ${decision.label.toLowerCase()}. '
          'No backend was updated.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment verification')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (widget.isLoading) {
      return const _PaymentState(
        message: 'Loading sample payments...',
        isLoading: true,
      );
    }

    if (_payments.isEmpty) {
      return const _PaymentState(
        icon: Icons.payments_outlined,
        message: 'There are no sample payments to review.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SamplePaymentNotice(),
        const SizedBox(height: 12),
        for (var index = 0; index < _payments.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PaymentRecordCard(
              payment: _payments[index],
              onTap: () => _openDetails(index),
            ),
          ),
      ],
    );
  }
}

enum PaymentVerificationStatus { pending, approved, rejected }

extension on PaymentVerificationStatus {
  String get label => switch (this) {
        PaymentVerificationStatus.pending => 'Pending verification',
        PaymentVerificationStatus.approved => 'Approved · demo only',
        PaymentVerificationStatus.rejected => 'Rejected · demo only',
      };
}

class PaymentVerificationRecord {
  const PaymentVerificationRecord({
    required this.order,
    required this.paymentMethod,
    required this.referenceNumber,
    this.status = PaymentVerificationStatus.pending,
  });

  final IncomingOrder order;
  final String paymentMethod;
  final String referenceNumber;
  final PaymentVerificationStatus status;

  double get amount => order.total;

  PaymentVerificationRecord copyWith({
    PaymentVerificationStatus? status,
  }) {
    return PaymentVerificationRecord(
      order: order,
      paymentMethod: paymentMethod,
      referenceNumber: referenceNumber,
      status: status ?? this.status,
    );
  }
}

class _SamplePaymentNotice extends StatelessWidget {
  const _SamplePaymentNotice();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: colors.onSecondaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'SAMPLE PAYMENTS · Demo references and placeholder only. '
              'Approve/Reject actions do not update the backend.',
              style: TextStyle(
                color: colors.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentRecordCard extends StatelessWidget {
  const _PaymentRecordCard({
    required this.payment,
    required this.onTap,
  });

  final PaymentVerificationRecord payment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Order #${payment.order.number}',
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  _PaymentStatusBadge(status: payment.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(payment.order.customerName, style: textTheme.bodyLarge),
              const SizedBox(height: 12),
              _PaymentInfoRow(
                label: 'Method',
                value: payment.paymentMethod,
              ),
              const SizedBox(height: 6),
              _PaymentInfoRow(
                label: 'Reference',
                value: payment.referenceNumber,
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Amount',
                      style: textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    _money(payment.amount),
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Review details'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentStatusBadge extends StatelessWidget {
  const _PaymentStatusBadge({required this.status});

  final PaymentVerificationStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = switch (status) {
      PaymentVerificationStatus.pending => colors.primaryContainer,
      PaymentVerificationStatus.approved => colors.tertiaryContainer,
      PaymentVerificationStatus.rejected => colors.errorContainer,
    };
    final foreground = switch (status) {
      PaymentVerificationStatus.pending => colors.onPrimaryContainer,
      PaymentVerificationStatus.approved => colors.onTertiaryContainer,
      PaymentVerificationStatus.rejected => colors.onErrorContainer,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _PaymentDetailsSheet extends StatelessWidget {
  const _PaymentDetailsSheet({
    required this.payment,
    required this.onDecision,
  });

  final PaymentVerificationRecord payment;
  final ValueChanged<PaymentVerificationStatus> onDecision;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Order #${payment.order.number}',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    _PaymentStatusBadge(status: payment.status),
                  ],
                ),
                const SizedBox(height: 16),
                _PaymentInfoRow(
                  label: 'Customer',
                  value: payment.order.customerName,
                ),
                const SizedBox(height: 8),
                _PaymentInfoRow(
                  label: 'Payment method',
                  value: payment.paymentMethod,
                ),
                const SizedBox(height: 8),
                _PaymentInfoRow(
                  label: 'Reference number',
                  value: payment.referenceNumber,
                ),
                const SizedBox(height: 8),
                _PaymentInfoRow(
                  label: 'Payment status',
                  value: payment.status.label,
                ),
                const SizedBox(height: 20),
                Text(
                  'Order items',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                for (final item in payment.order.items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('${item.quantity} × ${item.name}'),
                        ),
                        Text(_money(item.lineTotal)),
                      ],
                    ),
                  ),
                const Divider(height: 28),
                _PaymentInfoRow(
                  label: 'Amount',
                  value: _money(payment.amount),
                  emphasize: true,
                ),
                const SizedBox(height: 20),
                Text(
                  'Payment proof',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    border: Border.all(color: colors.outlineVariant),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.image_not_supported_outlined,
                        size: 36,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'SAMPLE PLACEHOLDER',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'No customer payment proof is displayed.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Demo actions only. Approving or rejecting does not update '
                  'the real backend.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
                if (payment.status == PaymentVerificationStatus.pending) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () =>
                            onDecision(PaymentVerificationStatus.rejected),
                        icon: const Icon(Icons.close),
                        label: const Text('Reject'),
                      ),
                      FilledButton.icon(
                        onPressed: () =>
                            onDecision(PaymentVerificationStatus.approved),
                        icon: const Icon(Icons.check),
                        label: const Text('Approve'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentInfoRow extends StatelessWidget {
  const _PaymentInfoRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final valueStyle = emphasize
        ? Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w700)
        : Theme.of(context).textTheme.bodyMedium;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: valueStyle,
          ),
        ),
      ],
    );
  }
}

class _PaymentState extends StatelessWidget {
  const _PaymentState({
    required this.message,
    this.icon,
    this.isLoading = false,
  });

  final String message;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const CircularProgressIndicator()
            else
              Icon(icon, size: 44, color: colors.primary),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

String _money(num amount) => '₱${amount.toStringAsFixed(2)}';
