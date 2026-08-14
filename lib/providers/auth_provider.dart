import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
      return AuthNotifier(
        ref.read(authServiceProvider),
        ref.read(storageServiceProvider),
      );
    });

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthService _authService;
  final StorageService _storageService;

  AuthNotifier(this._authService, this._storageService)
    : super(const AsyncValue.data(null));

  Future<void> restoreSession() async {
    final user = await _storageService.getSession();
    if (user != null) {
      state = AsyncValue.data(user);
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.login(email: email, password: password);
      if (user.token != null) {
        await _storageService.saveSession(token: user.token!, user: user);
      }
      state = AsyncValue.data(user);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.register(
        name: name,
        email: email,
        password: password,
      );
      if (user.token != null) {
        await _storageService.saveSession(token: user.token!, user: user);
      }
      state = AsyncValue.data(user);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> logout() async {
    await _storageService.clearSession();
    state = const AsyncValue.data(null);
  }
}
