/// Read-only representation of order_status values returned by ARK Cafe.
/// No elapsed-time estimates and no fake progress.
class OrderTracking {
  static const stages = <String>[
    'pending', 'confirmed', 'preparing', 'ready', 'completed',
  ];

  static String _normalize(Object? status) =>
      status?.toString().trim().toLowerCase() ?? '';

  static int stageIndex(Object? status) =>
      stages.indexOf(_normalize(status));

  static bool isCancelled(Object? status) =>
      const <String>['cancelled', 'canceled'].contains(_normalize(status));

  static String label(Object? status) {
    switch (_normalize(status)) {
      case 'pending': return 'Pending';
      case 'confirmed': return 'Confirmed';
      case 'preparing': return 'Preparing';
      case 'ready': return 'Ready';
      case 'completed': return 'Completed';
      case 'cancelled':
      case 'canceled': return 'Cancelled';
      default: return 'Unknown';
    }
  }

  static String description(String stage) {
    switch (stage) {
      case 'pending': return 'Waiting for staff confirmation.';
      case 'confirmed': return 'Accepted by the café staff.';
      case 'preparing': return 'Your order is being prepared.';
      case 'ready': return 'Ready for pickup.';
      case 'completed': return 'Order fulfilled.';
      default: return 'Status not available.';
    }
  }
}
