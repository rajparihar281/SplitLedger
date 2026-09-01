import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../groups/presentation/groups_screen.dart';
import 'auth_controller.dart';
import 'login_screen.dart';

class AuthStateWrapper extends StatefulWidget {
  const AuthStateWrapper({super.key, required this.authController});

  final AuthController authController;

  @override
  State<AuthStateWrapper> createState() => _AuthStateWrapperState();
}

class _AuthStateWrapperState extends State<AuthStateWrapper> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.paper,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.coral),
            ),
          );
        }

        final session = snapshot.data?.session;
        if (session != null) {
          return GroupsScreen(authController: widget.authController);
        } else {
          return LoginScreen(authController: widget.authController);
        }
      },
    );
  }
}
