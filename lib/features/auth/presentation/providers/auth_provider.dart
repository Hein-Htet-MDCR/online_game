import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/providers/supabase_provider.dart';
import '../../data/auth_repository.dart';
import '../../domain/user_profile.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return AuthRepository(supabase);
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});

final currentUserProfileProvider = FutureProvider<UserProfile?>((ref) async {
  ref.watch(authStateProvider);
  final authRepository = ref.watch(authRepositoryProvider);
  return await authRepository.getCurrentProfile();
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(const AsyncValue.data(null));

  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () =>
          _repository.signInWithEmailPassword(email: email, password: password),
    );
  }

  Future<void> signUpWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.signUpWithEmailPassword(
        email: email,
        password: password,
        displayName: displayName,
      ),
    );
  }

  Future<void> signInWithGoogle({
    required String webClientId,
    required String iosClientId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.signInWithGoogle(
        webClientId: webClientId,
        iosClientId: iosClientId,
      ),
    );
  }

  Future<void> signInWithApple() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.signInWithApple());
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.signOut());
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
      final repository = ref.watch(authRepositoryProvider);
      return AuthController(repository);
    });
