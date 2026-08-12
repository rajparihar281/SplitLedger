import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_repository.dart';

class AuthController {
  AuthController(this._repository);

  final AuthRepository _repository;

  Future<User?> signUp({required String email, required String password}) {
    return _repository.signUp(email: email, password: password);
  }

  Future<User?> signIn({required String email, required String password}) {
    return _repository.signIn(email: email, password: password);
  }

  Future<void> signOut() {
    return _repository.signOut();
  }

  User? get currentUser {
    return _repository.currentUser;
  }
}
