import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class AuthRepository {
  Future<User?> signUp({required String email, required String password});

  Future<User?> signIn({required String email, required String password});

  Future<void> signOut();

  User? get currentUser;
}
