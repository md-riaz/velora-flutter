import 'package:flutter/material.dart';

import 'package:velora/velora.dart';

import '../../routes/app_routes.dart';
import 'starter_auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController(text: 'admin@example.com');
  final password = TextEditingController(text: 'password');
  bool loading = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _demoLogin() async {
    setState(() => loading = true);
    final response = await Get.find<StarterAuthService>().login({
      'email': email.text,
      'password': password.text,
    });
    if (!mounted) return;
    setState(() => loading = false);

    if (!response.success) {
      Velora.toast.error(response.message ?? 'Unable to start demo session');
      return;
    }

    Velora.toast.success('Demo session started');
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    await Velora.nav.offAll<void>(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Velora Starter',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: email,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: loading ? null : _demoLogin,
                    child: Text(
                      loading ? 'Signing in...' : 'Start demo session',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
