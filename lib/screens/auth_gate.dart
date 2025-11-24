import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';

/// Écran de contrôle d'authentification
/// Affiche l'écran de connexion si l'utilisateur n'est pas connecté,
/// sinon affiche l'écran d'accueil
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    // StreamBuilder écoute les changements d'état d'authentification
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // En attente de la connexion
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Si l'utilisateur est connecté, afficher l'écran d'accueil
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        // Sinon, afficher l'écran de connexion
        return const LoginScreen();
      },
    );
  }
}

