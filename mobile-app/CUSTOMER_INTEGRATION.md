# Customer integration review
This branch combines the existing customer code with the original admin-portal commit 0d292fb (not a redesign). No change to main or the admin/employee branch.
## Prerequisites
Use the updated Express backend with SUPABASE_URL, SUPABASE_SECRET_KEY and SUPABASE_PUBLISHABLE_KEY in its local ignored .env. Use the publishable key in Flutter only. Keep both servers running. Jester must review and apply backend/sql/customer_cash_order.sql to the existing Supabase project before checkout. The script is not deployed by this commit.
## Acceptance testing
1. Sign in with the existing confirmed customer account. Open Profile. Check the saved name and role. If profile sync fails, use Retry and inspect the backend terminal. Admin-only user management should display the new customer read-only after refresh.
2. Search Iced Latte, select Coffee, add two with a note. Cart should show ₱320 if price is still ₱160.
3. After database owner deploys SQL, submit one cash test order (coordinate with team; it is a real pending record). Check Orders, then ask an authorized admin to reload Transactions and verify the same order ID, total, customer, items and pending payment.
4. Test logout and sign-in, order history scoped to own account, profile name editing, and expired token rejection. Staff-only list/status endpoints now require verified admin/employee token. Do not use someone else's credentials.
5. Run flutter analyze, flutter test, npm ci and npm run build in admin-web, node --check on new server files. Existing Flutter basic test is not end-to-end coverage.
## Not completed
Online payments, QR/proof upload, employee authentication/live API integration and payment verification still need team work. Do not mark paid on customer submission. Existing staff routes are not comprehensively audited. Do not merge main until team review and tests pass.
