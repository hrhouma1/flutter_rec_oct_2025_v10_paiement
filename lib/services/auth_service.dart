import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service d'authentification
/// Gère l'inscription, la connexion et la déconnexion des utilisateurs
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream de l'utilisateur actuel
  /// Permet de réagir en temps réel aux changements d'état d'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Utilisateur actuellement connecté
  User? get currentUser => _auth.currentUser;

  /// Inscription avec email et mot de passe
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    try {
      // Création du compte Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Création du document utilisateur dans Firestore
      // Ce document contiendra les informations de profil et d'abonnement
      await _createUserDocument(userCredential.user!);

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  /// Connexion avec email et mot de passe
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Création du document utilisateur dans Firestore
  /// Structure importante pour l'extension Stripe
  Future<void> _createUserDocument(User user) async {
    await _firestore.collection('users').doc(user.uid).set({
      'email': user.email,
      'createdAt': FieldValue.serverTimestamp(),
      // Le champ stripeId sera ajouté automatiquement par l'extension Stripe
      // lors du premier paiement
    });
  }
}

