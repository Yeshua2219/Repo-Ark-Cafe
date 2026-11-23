# Customer order tracking UI review

Only the Flutter Customer App has been changed. The existing customer checkout,
admin frontend, employee app, backend, and database are unmodified.

## Test without creating an order
1. Pull the latest customer branch, run flutter analyze and flutter test.
2. Start the Customer app on Android with the existing --dart-define values.
3. Sign in and open Orders. Empty history remains an honest empty state.
4. Tap **How order tracking works**. The five possible stages should fit on
   the phone, with none marked complete.
5. Tap Close. No order or simulated progress is created.

## Later: test a real saved order (after backend security review)
1. Open Orders and tap Refresh to fetch GET /api/orders/mine.
2. Tap a saved order for its backend status, payment status and items.
3. Authorized staff update the status, then customer refreshes Orders.
4. The backend currently supports transitions to confirmed, preparing and
   ready. The Completed stage is display-only until the backend permits it.

Do not treat the tracking guide as a mock transaction and do not merge main
before customer, employee, admin and role security testing are complete.
