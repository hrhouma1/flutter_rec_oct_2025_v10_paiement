import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/subscription_status.dart';

/// Service de gestion des abonnements
/// Interagit avec Firestore pour lire/écrire les données d'abonnement
/// et avec Stripe via l'extension Firebase
class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ID du prix Stripe (à récupérer depuis ton Dashboard Stripe)
  /// Format : price_xxxxxxxxxxxxx
  /// IMPORTANT : Remplace cette valeur par ton propre Price ID
  static const String monthlyPriceId = 'price_VOTRE_PRICE_ID_ICI';

  /// Stream du statut d'abonnement de l'utilisateur actuel
  /// Écoute en temps réel les changements dans Firestore
  Stream<SubscriptionStatus> getSubscriptionStatus() {
    final userId = _auth.currentUser?.uid;
    
    if (userId == null) {
      return Stream.value(SubscriptionStatus.none);
    }

    // L'extension Stripe crée une sous-collection "subscriptions" dans le document utilisateur
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('subscriptions')
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return SubscriptionStatus.none;
      }

      // On prend le premier abonnement (cas le plus simple)
      // Dans une vraie app, tu pourrais avoir plusieurs abonnements
      final subscriptionData = snapshot.docs.first.data();
      
      return _parseSubscriptionStatus(subscriptionData);
    });
  }

  /// Parse les données Firestore pour déterminer le statut d'abonnement
  SubscriptionStatus _parseSubscriptionStatus(Map<String, dynamic> data) {
    final status = data['status'] as String?;
    
    // Les statuts possibles viennent de Stripe :
    // - active : abonnement actif
    // - past_due : paiement en retard
    // - canceled : annulé (mais peut être actif jusqu'à la fin de la période)
    // - incomplete : paiement initial non complété
    // - trialing : période d'essai
    
    switch (status) {
      case 'active':
      case 'trialing':
        return SubscriptionStatus.active;
      case 'past_due':
        return SubscriptionStatus.pastDue;
      case 'canceled':
        return SubscriptionStatus.canceled;
      default:
        return SubscriptionStatus.none;
    }
  }

  /// Crée une session Stripe Checkout pour souscrire à un abonnement
  /// Cette méthode appelle une Cloud Function qui retourne une URL de paiement
  Future<void> createCheckoutSession() async {
    final userId = _auth.currentUser?.uid;
    
    if (userId == null) {
      throw Exception('Utilisateur non connecté');
    }

    try {
      // L'extension Stripe crée automatiquement une collection "checkout_sessions"
      // On ajoute un document avec le Price ID, et l'extension génère l'URL
      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('checkout_sessions')
          .add({
        'price': monthlyPriceId,
        'success_url': 'https://votre-app.com/success', // URL de retour après succès
        'cancel_url': 'https://votre-app.com/cancel',   // URL de retour après annulation
        'mode': 'subscription',
      });

      // Attendre que l'extension Stripe traite la demande et ajoute l'URL
      // Timeout après 10 secondes
      await _waitForCheckoutUrl(docRef);
    } catch (e) {
      throw Exception('Erreur lors de la création de la session : $e');
    }
  }

  /// Attend que l'URL de checkout soit générée par l'extension
  Future<void> _waitForCheckoutUrl(DocumentReference docRef) async {
    final completer = await docRef.snapshots().firstWhere(
      (snapshot) {
        final data = snapshot.data() as Map<String, dynamic>?;
        return data != null && (data.containsKey('url') || data.containsKey('error'));
      },
      orElse: () => throw TimeoutException('Timeout en attendant l\'URL de checkout'),
    );

    final data = completer.data() as Map<String, dynamic>;

    if (data.containsKey('error')) {
      throw Exception('Erreur Stripe : ${data['error']}');
    }

    final url = data['url'] as String;
    await _launchCheckoutUrl(url);
  }

  /// Ouvre l'URL de checkout Stripe dans le navigateur
  Future<void> _launchCheckoutUrl(String url) async {
    final uri = Uri.parse(url);
    
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Impossible d\'ouvrir l\'URL de paiement');
    }
  }

  /// Crée une session pour le portail client Stripe
  /// Permet à l'utilisateur de gérer son abonnement (annulation, changement de carte, etc.)
  Future<void> createPortalSession() async {
    final userId = _auth.currentUser?.uid;
    
    if (userId == null) {
      throw Exception('Utilisateur non connecté');
    }

    try {
      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('checkout_sessions')
          .add({
        'returnUrl': 'https://votre-app.com/account',
      });

      await _waitForPortalUrl(docRef);
    } catch (e) {
      throw Exception('Erreur lors de l\'ouverture du portail : $e');
    }
  }

  /// Attend que l'URL du portail soit générée
  Future<void> _waitForPortalUrl(DocumentReference docRef) async {
    final completer = await docRef.snapshots().firstWhere(
      (snapshot) {
        final data = snapshot.data() as Map<String, dynamic>?;
        return data != null && data.containsKey('url');
      },
      orElse: () => throw TimeoutException('Timeout en attendant l\'URL du portail'),
    );

    final data = completer.data() as Map<String, dynamic>;
    final url = data['url'] as String;
    
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// Exception de timeout personnalisée
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  
  @override
  String toString() => message;
}

