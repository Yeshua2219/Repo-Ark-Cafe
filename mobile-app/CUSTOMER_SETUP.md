# ARK Cafe Customer Mobile App (Joshua)

## Setup
The GitHub repository initially contains only Flutter placeholders. Create missing
Flutter platform scaffolding **locally** from inside `mobile-app`:

```bash
cd mobile-app
flutter create --project-name ark_cafe_mobile .
flutter pub get
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_KEY \
  --dart-define=API_BASE_URL=http://10.0.2.2:5000/api
```

For a physical Android device, replace 10.0.2.2 with your backend computer's
LAN IP. Do not commit credentials. Only use the Supabase public anon key in
mobile; service-role keys stay on the backend. Use HTTPS for production.

## Implemented customer UI
- Customer sign-up and sign-in using Supabase Auth
- Digital menu from GET /api/products, search and categories
- Product customization notes and cart quantity updates
- Checkout for cash or online payment selection
- Transaction history and order status display
- Basic account screen with sign-out

## Backend contracts still required (Jester / Kenneth)
1. `POST /api/orders` authenticated: Body:
   `{"payment_method":"cash|online","items":[{"product_id":1,"quantity":2,"customization":"less ice"}]}`.
   Response: `{"order":{"id":123}}`. Ignore client-supplied totals;
   calculate prices from the database. Validate inventory, values and role.
   Use authenticated customer ID from server-validated bearer token.
2. `GET /api/orders/mine` authenticated: Return only authenticated
   customer's orders, including `id`, `total_amount`, `order_status`,
   `payment_status`, and optionally `order_items`.
3. Product listing uses existing `GET /api/products`.
4. Online payment proof submission and verification require a separate
   secure upload flow and API contract; this app does **not** take or confirm
   online payments. Do not mark an order paid based on this UI.
5. Supabase Auth account metadata does not automatically populate your
   custom `users` table; backend must create the customer record and enforce
   `role=customer`, not trust client-specified roles.
6. Restrict CORS and authenticate all private backend routes before release.
7. Confirm cash and online order status transitions with the backend team.

## Shared-project caution
The new `mobile-app/lib/main.dart` currently starts CustomerApp. Before
combining with Joanna's employee UI, add server-verified role routing rather
than manual role selection. Keep employee screens in a separate folder.

## Verification checklist
Run `flutter analyze` and `flutter test` locally after generating platform
files; not run inside ChatGPT. Test signup, menu, filters, cart, checkout
errors, valid backend order creation, and order ownership isolation.
