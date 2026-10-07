import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_chepita_mtc/providers/auth_provider.dart';
import 'package:app_chepita_mtc/screens/login_screen.dart';
import 'package:app_chepita_mtc/widgets/buttons/primary_button.dart';
import 'package:app_chepita_mtc/widgets/buttons/secondary_button.dart';
import 'package:app_chepita_mtc/widgets/cards/recommendation_home_card.dart';
import 'package:app_chepita_mtc/widgets/inputs/custom_text_field.dart';

import 'widget_test.dart';

void main() {
  testWidgets('CustomTextField triggers onFieldSubmitted and links focusNode', (
    WidgetTester tester,
  ) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    String submittedText = '';

    addTearDown(() {
      controller.dispose();
      focusNode.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomTextField(
            controller: controller,
            focusNode: focusNode,
            labelText: 'Test',
            prefixIcon: Icons.edit,
            onFieldSubmitted: (val) => submittedText = val,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'hola mundo');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(submittedText, 'hola mundo');
  });

  testWidgets('PrimaryButton and SecondaryButton invoke callbacks with haptics', (
    WidgetTester tester,
  ) async {
    var primaryTapped = false;
    var secondaryTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              PrimaryButton(
                label: 'Aceptar',
                onPressed: () => primaryTapped = true,
              ),
              SecondaryButton(
                label: 'Cancelar',
                onPressed: () => secondaryTapped = true,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Aceptar'));
    expect(primaryTapped, isTrue);

    await tester.tap(find.text('Cancelar'));
    expect(secondaryTapped, isTrue);
  });

  testWidgets('LoginScreen submits form via keyboard on password field', (
    WidgetTester tester,
  ) async {
    final authService = FakeAuthService()
      ..error = Exception('credenciales inválidas');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(authService),
          storageServiceProvider.overrideWithValue(FakeStorageService()),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'conductor@example.com');
    await tester.enterText(fields.at(1), '123456');

    // Simulate keyboard "done" action on password field
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(authService.loginCalls, 1);
    expect(authService.lastEmail, 'conductor@example.com');
    expect(authService.lastPassword, '123456');
  });

  testWidgets('RecommendationHomeCard renders shimmer skeleton while loading', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RecommendationHomeCard(),
        ),
      ),
    );

    // Initial frame has loading state with AnimatedBuilder and shimmer
    expect(find.byType(RecommendationHomeCard), findsOneWidget);
    // Pump a few frames to verify animation runs without errors
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  });
}
