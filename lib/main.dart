import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/subscription_service.dart';
import 'screens/auth_gate.dart';

/// Point d'entrée de l'application
/// Cette application enseigne les concepts de base des abonnements avec Stripe
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialisation de Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider permet de partager les services dans toute l'application
    return MultiProvider(
      providers: [
        // Service d'authentification
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        // Service de gestion des abonnements
        Provider<SubscriptionService>(
          create: (_) => SubscriptionService(),
        ),
      ],
      child: MaterialApp(
        title: 'Flutter Stripe Learning',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const AuthGate(),
      ),
    );
  }
}

