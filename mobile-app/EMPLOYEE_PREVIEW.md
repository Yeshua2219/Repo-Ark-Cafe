# Employee preview integration

Joanna's employee module from commit 2384928 is included verbatim in this review branch. The current customer entrypoint, customer code, Android package configuration, Flutter dependencies, admin frontend and backend are retained. The Android configuration was deliberately not replaced by the employee branch's competing generated Android configuration.

From mobile-app, run:
```
flutter run -d chrome -t lib/employee_main.dart
```

This is Joanna's existing demo frontend. Employee sign-in is not connected; debug demo mode uses sample orders, payments, sales and expenses and does not persist changes. Do not enter real staff credentials into the demo. Actual employee authentication, role-scoped API integration, payment verification and persistence require further work and team review.

Run flutter analyze and flutter test with the integrated code. Then verify both the customer entrypoint (with its existing --dart-define configuration) and the employee entrypoint separately. Do not merge main before the team has reviewed and agreed on the remaining integration work.
