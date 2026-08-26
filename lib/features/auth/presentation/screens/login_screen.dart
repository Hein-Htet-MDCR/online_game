import 'package:flutter/foundation.dart'; // ✅ Works everywhere
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();

  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final displayName = _displayNameController.text.trim();

    FocusScope.of(context).unfocus();

    if (_isSignUp) {
      await ref
          .read(authControllerProvider.notifier)
          .signUpWithEmailPassword(
            email: email,
            password: password,
            displayName: displayName.isNotEmpty ? displayName : 'Player',
          );

      final session = ref.read(supabaseClientProvider).auth.currentSession;
      if (mounted &&
          session == null &&
          !ref.read(authControllerProvider).hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Account created! If confirmation is required, check your email.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      await ref
          .read(authControllerProvider.notifier)
          .signInWithEmailPassword(email: email, password: password);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      if (next.hasError) {
        final errorMsg = next.error is AuthException
            ? (next.error as AuthException).message
            : next.error.toString().replaceAll('Exception: ', '');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.redAccent),
        );
      }
    });

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.translate_rounded,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            const Text(
              '日本語 MATCH',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              _isSignUp
                  ? 'Create a new player account'
                  : 'Sign in to start matching words',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 28),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  if (_isSignUp) ...[
                    TextFormField(
                      controller: _displayNameController,
                      decoration: const InputDecoration(
                        labelText: 'Display Name',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (_isSignUp && (val == null || val.trim().isEmpty)) {
                          return 'Please enter a display name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null ||
                          val.trim().isEmpty ||
                          !val.contains('@')) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  if (isLoading)
                    const CircularProgressIndicator()
                  else
                    ElevatedButton(
                      onPressed: _submitForm,
                      child: Text(_isSignUp ? 'Sign Up' : 'Sign In'),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                setState(() {
                  _isSignUp = !_isSignUp;
                });
              },
              child: Text(
                _isSignUp
                    ? 'Already have an account? Sign In'
                    : "Don't have an account? Sign Up",
                style: const TextStyle(color: AppColors.accent),
              ),
            ),

            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(child: Divider(color: Colors.white24)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    'OR',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ),
                Expanded(child: Divider(color: Colors.white24)),
              ],
            ),
            const SizedBox(height: 16),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
              ),
              icon: const Icon(Icons.g_mobiledata, size: 32, color: Colors.red),
              label: const Text('Continue with Google'),
              onPressed: isLoading
                  ? null
                  : () {
                      ref
                          .read(authControllerProvider.notifier)
                          .signInWithGoogle(
                            webClientId:
                                'YOUR_GOOGLE_WEB_CLIENT_ID.apps.googleusercontent.com',
                            iosClientId:
                                'YOUR_GOOGLE_IOS_CLIENT_ID.apps.googleusercontent.com',
                          );
                    },
            ),
            const SizedBox(height: 12),

            if (!kIsWeb &&
                (defaultTargetPlatform == TargetPlatform.iOS ||
                    defaultTargetPlatform == TargetPlatform.macOS))
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.apple, size: 24),
                label: const Text('Continue with Apple'),
                onPressed: isLoading
                    ? null
                    : () {
                        ref
                            .read(authControllerProvider.notifier)
                            .signInWithApple();
                      },
              ),
          ],
        ),
      ),
    );
  }
}
