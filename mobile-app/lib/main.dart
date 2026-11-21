import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'customer/customer_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_ANON_KEY');
  if (url.isEmpty || key.isEmpty) {
    runApp(const MaterialApp(home: Scaffold(body: Center(child: Text(
      'Set SUPABASE_URL and SUPABASE_ANON_KEY using --dart-define.',
      textAlign: TextAlign.center,
    )))));
    return;
  }
  await Supabase.initialize(url: url, publishableKey: key);

  final colors = ColorScheme.fromSeed(seedColor: ArkColors.coffeeBrown)
      .copyWith(
        primary: ArkColors.coffeeBrown,
        onPrimary: ArkColors.white,
        primaryContainer: ArkColors.warmBeige,
        onPrimaryContainer: ArkColors.darkBrown,
        secondary: ArkColors.coffeeBrown,
        onSecondary: ArkColors.white,
        secondaryContainer: ArkColors.warmBeige,
        onSecondaryContainer: ArkColors.darkBrown,
        surface: ArkColors.cream,
        onSurface: ArkColors.darkBrown,
        onSurfaceVariant: ArkColors.coffeeBrown,
        outline: ArkColors.mutedBrown,
        outlineVariant: ArkColors.warmBeige,
      );

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'ARK Cafe',
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: ArkColors.cream,
      appBarTheme: const AppBarTheme(
        backgroundColor: ArkColors.darkBrown,
        foregroundColor: ArkColors.white,
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ArkColors.coffeeBrown,
          foregroundColor: ArkColors.white,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ArkColors.coffeeBrown,
          side: const BorderSide(color: ArkColors.coffeeBrown),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    ),
    home: const CustomerApp(),
  ));
}
