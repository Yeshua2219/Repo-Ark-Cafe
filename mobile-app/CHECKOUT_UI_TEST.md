# Customer checkout UI: testing steps

This change affects only mobile-app/lib/customer/customer_app.dart.

1. Run flutter analyze and flutter test from mobile-app.
2. Run the Customer app on Android with the existing SUPABASE_URL, SUPABASE_ANON_KEY, API_BASE_URL define values.
3. Sign in, add two Iced Lattes with a customization.
4. Open Cart. Tap Review checkout and check the item list, customization, and ₱320.00 total.
5. Tap Online · preview. Check that payment instructions are labeled as pending; Upload proof and online checkout are disabled and no data is submitted.
6. Select Cash. Check the pending-order description. Tap Back to cart to return without creating a record.

Do NOT tap Confirm cash order until the database maintainer has reviewed and deployed backend/sql/customer_cash_order.sql and you agree with the team to create a real pending test order. The pending database function and grants are not resolved by this UI commit.

The employee and admin modules are unchanged.
