import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_chepita_mtc/models/user.dart';
import 'package:app_chepita_mtc/providers/auth_provider.dart';
import 'package:app_chepita_mtc/screens/login_screen.dart';
import 'package:app_chepita_mtc/screens/register_screen.dart';
import 'package:app_chepita_mtc/services/auth_service.dart';
import 'package:app_chepita_mtc/services/storage_service.dart';
import 'package:app_chepita_mtc/widgets/buttons/primary_button.dart';
import 'package:app_chepita_mtc/widgets/inputs/custom_text_field.dart';
import 'package:app_chepita_mtc/widgets/states/custom_loading_state.dart';

void main() {
  testWidgets('CustomLoadingState renders indicator and message', (
    WidgetTester tester,
  ) async {
    const testMessage = 'Cargando datos del examen...';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: CustomLoadingState(message: testMessage)),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text(testMessage), findsOneWidget);
  });

  testWidgets('CustomTextField toggles password visibility', (
    WidgetTester tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomTextField(
            controller: controller,
            labelText: 'Contraseña',
            prefixIcon: Icons.lock_outline,
            obscureText: true,
          ),
        ),
      ),
    );

    expect(
      tester.widget<TextField>(find.byType(TextField)).obscureText,
      isTrue,
    );
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();

    expect(
      tester.widget<TextField>(find.byType(TextField)).obscureText,
      isFalse,
    );
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
  });

  testWidgets(
    'PrimaryButton disables interaction and shows progress when busy',
    (WidgetTester tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PrimaryButton(
                label: 'Enviar',
                isLoading: true,
                onPressed: () => pressed = true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Enviar'), findsNothing);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.tap(find.byType(FilledButton));
      expect(pressed, isFalse);
    },
  );

  testWidgets('Login form validates input and submits valid credentials', (
    WidgetTester tester,
  ) async {
    final authService = FakeAuthService()
      ..error = Exception('credenciales inválidas');
    await _pumpAuthScreen(tester, const LoginScreen(), authService);

    await tester.tap(find.text('Iniciar Sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Ingresa tu correo electrónico'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña'), findsOneWidget);
    expect(authService.loginCalls, 0);

    final fields = find.byType(TextFormField);
    await _enterText(tester, fields.at(0), 'usuario-invalido');
    await _enterText(tester, fields.at(1), '123');
    await tester.ensureVisible(find.text('Iniciar Sesión'));
    await tester.tap(find.text('Iniciar Sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Ingresa un correo válido'), findsOneWidget);
    expect(
      find.text('La contraseña debe tener al menos 6 caracteres'),
      findsOneWidget,
    );
    expect(authService.loginCalls, 0);

    await _enterText(tester, fields.at(0), ' usuario@example.com ');
    await _enterText(tester, fields.at(1), 'clave-segura');
    await tester.ensureVisible(find.text('Iniciar Sesión'));
    await tester.tap(find.text('Iniciar Sesión'));
    await tester.pumpAndSettle();

    expect(authService.loginCalls, 1);
    expect(authService.lastEmail, 'usuario@example.com');
    expect(authService.lastPassword, 'clave-segura');
    expect(
      find.text('Error: Exception: credenciales inválidas'),
      findsOneWidget,
    );
  });

  testWidgets('Register form validates matching passwords before submission', (
    WidgetTester tester,
  ) async {
    final authService = FakeAuthService()
      ..error = Exception('registro rechazado');
    await _pumpAuthScreen(tester, const RegisterScreen(), authService);

    await tester.ensureVisible(find.text('Registrarse'));
    await tester.tap(find.text('Registrarse'));
    await tester.pumpAndSettle();
    expect(find.text('Ingresa tu nombre'), findsOneWidget);
    expect(find.text('Ingresa tu correo electrónico'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña'), findsOneWidget);
    expect(find.text('Confirma tu contraseña'), findsOneWidget);
    expect(authService.registerCalls, 0);

    final fields = find.byType(TextFormField);
    await _enterText(tester, fields.at(0), ' Usuario de prueba ');
    await _enterText(tester, fields.at(1), 'usuario@example.com');
    await _enterText(tester, fields.at(2), 'clave-segura');
    await _enterText(tester, fields.at(3), 'otra-clave');
    await tester.ensureVisible(find.text('Registrarse'));
    await tester.tap(find.text('Registrarse'));
    await tester.pumpAndSettle();
    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    expect(authService.registerCalls, 0);

    await _enterText(tester, fields.at(3), 'clave-segura');
    await tester.ensureVisible(find.text('Registrarse'));
    await tester.tap(find.text('Registrarse'));
    await tester.pumpAndSettle();

    expect(authService.registerCalls, 1);
    expect(authService.lastName, 'Usuario de prueba');
    expect(authService.lastEmail, 'usuario@example.com');
    expect(authService.lastPassword, 'clave-segura');
    expect(find.text('Error: Exception: registro rechazado'), findsOneWidget);
  });

  testWidgets('Login navigation opens the registration form', (
    WidgetTester tester,
  ) async {
    await _pumpAuthScreen(tester, const LoginScreen(), FakeAuthService());

    await tester.tap(find.text('Regístrate'));
    await tester.pumpAndSettle();

    expect(find.text('Registro'), findsOneWidget);
    expect(find.text('Crear cuenta'), findsOneWidget);
  });
}

Future<void> _pumpAuthScreen(
  WidgetTester tester,
  Widget screen,
  FakeAuthService authService,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(authService),
        storageServiceProvider.overrideWithValue(FakeStorageService()),
      ],
      child: MaterialApp(home: screen),
    ),
  );
}

Future<void> _enterText(WidgetTester tester, Finder field, String value) async {
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
}

class FakeAuthService extends AuthService {
  Object? error;
  int loginCalls = 0;
  int registerCalls = 0;
  String? lastName;
  String? lastEmail;
  String? lastPassword;

  @override
  Future<User> login({required String email, required String password}) async {
    loginCalls++;
    lastEmail = email;
    lastPassword = password;
    if (error != null) throw error!;
    return const User(id: 1, name: 'Usuario', email: 'usuario@example.com');
  }

  @override
  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    registerCalls++;
    lastName = name;
    lastEmail = email;
    lastPassword = password;
    if (error != null) throw error!;
    return User(id: 1, name: name, email: email);
  }
}

class FakeStorageService extends StorageService {
  @override
  Future<User?> getSession() async => null;

  @override
  Future<void> saveSession({required String token, required User user}) async {}

  @override
  Future<void> clearSession() async {}
}
