import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minna_senshuken/features/auth/presentation/pages/sign_in_page.dart';

void main() {
  group('SignInPage', () {
    testWidgets('should display email and password fields', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SignInPage(),
          ),
        ),
      );

      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('メールアドレス'), findsOneWidget);
      expect(find.text('パスワード'), findsOneWidget);
    });

    testWidgets('should display sign in button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SignInPage(),
          ),
        ),
      );

      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'サインイン'), findsOneWidget);
    });

    testWidgets('should show email validation error for invalid email',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SignInPage(),
          ),
        ),
      );

      // Find email field and enter invalid email
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'invalid-email');

      // Tap sign in button to trigger validation
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(find.text('有効なメールアドレスを入力してください'), findsOneWidget);
    });

    testWidgets('should show password validation error for short password',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SignInPage(),
          ),
        ),
      );

      // Find email field and enter valid email
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'test@example.com');

      // Find password field and enter short password
      final passwordField = find.byType(TextFormField).last;
      await tester.enterText(passwordField, '12345');

      // Tap sign in button to trigger validation
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(find.text('パスワードは6文字以上で入力してください'), findsOneWidget);
    });

    testWidgets('should hide password by default', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SignInPage(),
          ),
        ),
      );

      // Find the password TextField widget
      final passwordTextField = tester.widget<TextField>(
        find.descendant(
          of: find.byType(TextFormField).last,
          matching: find.byType(TextField),
        ),
      );

      expect(passwordTextField.obscureText, isTrue);
    });
  });
}
