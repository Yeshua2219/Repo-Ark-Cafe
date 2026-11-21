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
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'ARK Cafe',
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF79513B)),
      scaffoldBackgroundColor: const Color(0xFFFAF6F0),
    ),
    home: const CustomerApp(),
  ));
}
