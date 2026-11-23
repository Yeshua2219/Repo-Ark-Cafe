import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';

import '../../../customer/customer_api.dart';
import '../dashboard/employee_dashboard_screen.dart';

class EmployeeSession {
  static String? token;
  static Map<String, dynamic>? user;
}

class EmployeeLoginScreen extends StatefulWidget {
  const EmployeeLoginScreen({super.key});

  @override
  State<EmployeeLoginScreen> createState() => _EmployeeLoginScreenState();
}

class _EmployeeLoginScreenState extends State<EmployeeLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final uri = Uri.parse('${CustomerApi.baseUrl}/auth/employee-login');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': _emailController.text.trim(),
              'password': _passwordController.text,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        EmployeeSession.token = decoded['token']?.toString();
        EmployeeSession.user = decoded['user'] is Map
            ? Map<String, dynamic>.from(decoded['user'] as Map)
            : null;

        if (!mounted) return;
        Navigator.pushReplacementNamed(
          context,
          EmployeeDashboardScreen.routeName,
        );
      } else {
        final message = (decoded is Map && decoded['message'] != null)
            ? decoded['message'].toString()
            : 'Unable to sign in (${response.statusCode}).';
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot connect to ARK Cafe backend: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 36),
                    Icon(
                      Icons.local_cafe_rounded,
                      size: 44,
                      color: colors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ARK Cafe',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Employee sign in',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.username],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Enter your email address.'
                              : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Show password'
                              : 'Hide password',
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter your password.'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(_isLoading ? 'Signing in...' : 'Sign in'),
                      ),
                    ),
                    if (kDebugMode) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          EmployeeDashboardScreen.routeName,
                        ),
                        icon: const Icon(Icons.science_outlined),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Continue in Demo Mode'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Frontend testing only. This does not authenticate '
                        'an employee.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}