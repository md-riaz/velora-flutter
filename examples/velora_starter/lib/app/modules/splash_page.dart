import 'package:flutter/material.dart';
import 'package:velora/velora.dart';

import '../routes/app_routes.dart';
import 'auth/logout_state.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      final route = Velora.auth.check && !isVeloraLogoutRunning()
          ? AppRoutes.dashboard
          : AppRoutes.login;
      Velora.nav.offAll(route);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
