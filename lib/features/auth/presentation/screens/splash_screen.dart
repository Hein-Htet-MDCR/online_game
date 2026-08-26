import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/constants/app_routes.dart';
import '../../../../core/providers/supabase_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final session = ref.read(supabaseClientProvider).auth.currentSession;
    if (session != null) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '日本語 MATCH',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 24),
          CircularProgressIndicator(),
        ],
      ),
    );
  }
}
