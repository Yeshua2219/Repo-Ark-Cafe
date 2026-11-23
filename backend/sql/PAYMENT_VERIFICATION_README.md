# Employee cash payment verification (integration)

This change adds a genuine employee/admin-only payment verification workflow
without changing existing customer, employee, or admin records.

## What was missing
Previously EmployeeApi.updatePaymentStatus() deliberately threw
UnsupportedError because no authorized backend endpoint existed. The
adminTransactionRoutes GET-only API is unrelated to this action.

## Backend contract
PATCH /api/orders/:id/payment
Authorization: Bearer <authorized employee/admin Supabase access token>
Content-Type: application/json

Approval body: {"status":"approved","cash_received":true}
Rejection body: {"status":"rejected"}

For *cash orders only*, once a real staff member confirms receipt or rejects:
- POSTGRES RPC ark_verify_cash_payment updates orders.payment_status to
  paid / rejected and payments.verification_status to verified / rejected.
- It records the authorized employee ID in payments.verified_by and time in
  payments.verified_at.
- An old order without a payments row gets one created in the same transaction.
- Orders already decided, unsupported online methods, and duplicate payment
  rows are rejected instead of silently overwritten.
- The SQL uses SECURITY INVOKER and EXECUTE only for service_role.
- API authenticates the bearer token then verifies role from public.users.
- No service role credentials are exposed to Flutter.

## Required deployment by Jester (not applied automatically)
1. Review backend/sql/employee_cash_payment_verification.sql.
2. In the existing team's Supabase database, deploy it with owner authorization.
3. Verify permissions: anon and authenticated must NOT be allowed to execute
   ark_verify_cash_payment. service_role must be allowed.
4. Separately secure the pre-existing ark_create_cash_order function if it is
   still publicly executable with SECURITY DEFINER.
5. Restart backend: cd backend; npm run dev.
6. Run backend unit checks: node --test test/paymentVerification.test.js.
7. Run flutter analyze and flutter test from mobile-app.

## End-to-end verification
1. Sign in using an authorized Employee account. Demo Mode does not save data.
2. Open Payment verification. The list must show real orders from /api/orders.
3. **Do not approve a test order unless physical cash was actually received.**
   Cash approval permanently marks the real order paid. Test only with an
   authorized, agreed-on record and actual receipt confirmation.
4. Choose an eligible cash order, check payment status, and press Approve.
   The UI must show a separate 'Confirm cash received?' dialog.
5. If confirmation is cancelled, the database must remain unchanged.
6. If staff confirms real cash receipt, the backend saves both statuses
   atomically. After refresh, Admin Transactions and Customer Order History
   should reflect the verified payment.
7. An unauthorized or customer token must return HTTP 403/401. An order with
   paid/rejected status must refuse another verification (HTTP 409).
8. Online payments are NOT enabled by this change.

Until the SQL script is deployed, the backend intentionally responds with
HTTP 503 instead of claiming a payment was saved.

Do not merge to main until the SQL is reviewed, analyzer and test results pass,
and the complete team validates the shared user roles and payments flow.
