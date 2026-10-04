import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_chepita_mtc/models/user.dart';
import 'package:app_chepita_mtc/providers/auth_provider.dart';
import 'package:app_chepita_mtc/services/auth_service.dart';
import 'package:app_chepita_mtc/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StorageService', () {
    late StorageService storageService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storageService = StorageService();
    });

    test('saves and restores a session', () async {
      const user = User(id: 12, name: 'Luis', email: 'luis@example.com');

      await storageService.saveSession(token: 'session-token', user: user);

      expect(await storageService.getToken(), 'session-token');
      final restoredUser = await storageService.getSession();
      expect(restoredUser?.id, 12);
      expect(restoredUser?.name, 'Luis');
      expect(restoredUser?.email, 'luis@example.com');
      expect(restoredUser?.token, 'session-token');
    });

    test(
      'returns no session when storage is empty and clears saved data',
      () async {
        expect(await storageService.getToken(), isNull);
        expect(await storageService.getSession(), isNull);

        await storageService.saveSession(
          token: 'session-token',
          user: const User(id: 12, name: 'Luis', email: 'luis@example.com'),
        );
        await storageService.clearSession();

        expect(await storageService.getToken(), isNull);
        expect(await storageService.getSession(), isNull);
      },
    );
  });

  group('AuthNotifier', () {
    late FakeAuthService authService;
    late FakeStorageService storageService;
    late AuthNotifier notifier;

    setUp(() {
      authService = FakeAuthService();
      storageService = FakeStorageService();
      notifier = AuthNotifier(authService, storageService);
    });

    tearDown(() => notifier.dispose());

    test('restores a saved session', () async {
      storageService.session = _user;

      await notifier.restoreSession();

      expect(notifier.state.value, _user);
    });

    test(
      'login saves the token and publishes the authenticated user',
      () async {
        authService.result = _user;

        await notifier.login(email: _user.email, password: 'secret');

        expect(authService.lastEmail, _user.email);
        expect(authService.lastPassword, 'secret');
        expect(storageService.savedToken, _user.token);
        expect(storageService.session, _user);
        expect(notifier.state.value, _user);
      },
    );

    test('registration saves the token and publishes the new user', () async {
      authService.result = _user;

      await notifier.register(
        name: _user.name,
        email: _user.email,
        password: 'secret',
      );

      expect(authService.lastName, _user.name);
      expect(authService.lastEmail, _user.email);
      expect(authService.lastPassword, 'secret');
      expect(storageService.savedToken, _user.token);
      expect(notifier.state.value, _user);
    });

    test('publishes authentication failures as AsyncValue errors', () async {
      authService.error = Exception('invalid credentials');

      await notifier.login(email: _user.email, password: 'wrong');

      expect(notifier.state.error, authService.error);
    });

    test('logout clears persisted session and resets state', () async {
      storageService.session = _user;

      await notifier.logout();

      expect(storageService.clearCount, 1);
      expect(storageService.session, isNull);
      expect(notifier.state.value, isNull);
    });
  });
}

const _user = User(
  id: 9,
  name: 'María',
  email: 'maria@example.com',
  token: 'auth-token',
);

class FakeAuthService extends AuthService {
  User result = _user;
  Object? error;
  String? lastName;
  String? lastEmail;
  String? lastPassword;

  @override
  Future<User> login({required String email, required String password}) async {
    lastEmail = email;
    lastPassword = password;
    if (error != null) throw error!;
    return result;
  }

  @override
  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    lastName = name;
    lastEmail = email;
    lastPassword = password;
    if (error != null) throw error!;
    return result;
  }
}

class FakeStorageService extends StorageService {
  User? session;
  String? savedToken;
  int clearCount = 0;

  @override
  Future<User?> getSession() async => session;

  @override
  Future<void> saveSession({required String token, required User user}) async {
    savedToken = token;
    session = user;
  }

  @override
  Future<void> clearSession() async {
    clearCount++;
    session = null;
    savedToken = null;
  }
}
