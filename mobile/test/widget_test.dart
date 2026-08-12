import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/auth_repository.dart';
import 'package:mobile/features/auth/presentation/auth_controller.dart';
import 'package:mobile/features/auth/presentation/signup_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeAuthRepository implements AuthRepository {
  @override
  Future<void> signOut() async {}

  @override
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    return null;
  }

  @override
  Future<User?> signUp({
    required String email,
    required String password,
  }) async {
    return null;
  }

  @override
  User? get currentUser => null;
}

void main() {
  testWidgets('Signup screen renders correctly', (WidgetTester tester) async {
    final authRepository = FakeAuthRepository();
    final authController = AuthController(authRepository);

    await tester.pumpWidget(
      MaterialApp(home: SignupScreen(authController: authController)),
    );

    expect(find.text('Create account'), findsNWidgets(2));
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
