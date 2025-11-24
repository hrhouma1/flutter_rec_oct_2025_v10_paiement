import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/subscription_service.dart';
import '../models/subscription_status.dart';
import 'paywall_screen.dart';
import 'premium_screen.dart';

/// Écran d'accueil principal
/// Affiche le statut d'abonnement et permet la navigation
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final subscriptionService = Provider.of<SubscriptionService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
            },
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: StreamBuilder<SubscriptionStatus>(
        stream: subscriptionService.getSubscriptionStatus(),
        builder: (context, snapshot) {
          // État de chargement
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Erreur
          if (snapshot.hasError) {
            return Center(
              child: Text('Erreur : ${snapshot.error}'),
            );
          }

          final status = snapshot.data ?? SubscriptionStatus.none;

          return _buildContent(context, status);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, SubscriptionStatus status) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Carte de statut d'abonnement
          _buildStatusCard(context, status),
          const SizedBox(height: 32),

          // Explication pédagogique
          _buildExplanationCard(context, status),
          const SizedBox(height: 32),

          // Bouton d'accès au contenu premium
          _buildPremiumButton(context, status),
          
          const Spacer(),

          // Informations utilisateur
          _buildUserInfo(context),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, SubscriptionStatus status) {
    final color = status.hasAccess ? Colors.green : Colors.orange;
    final icon = status.hasAccess ? Icons.check_circle : Icons.info;

    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Statut d\'abonnement',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status.description,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationCard(BuildContext context, SubscriptionStatus status) {
    String explanation;
    
    switch (status) {
      case SubscriptionStatus.none:
        explanation = 
          'Vous n\'avez pas d\'abonnement actif.\n\n'
          'Cette application démontre comment :\n'
          '• Gérer l\'authentification Firebase\n'
          '• Créer des sessions Stripe Checkout\n'
          '• Lire le statut d\'abonnement depuis Firestore\n'
          '• Afficher un paywall conditionnel';
        break;
      case SubscriptionStatus.active:
        explanation = 
          'Votre abonnement est actif !\n\n'
          'L\'extension Firebase Stripe a automatiquement :\n'
          '• Créé un client Stripe\n'
          '• Enregistré l\'abonnement dans Firestore\n'
          '• Synchronisé le statut en temps réel\n\n'
          'Vous pouvez maintenant accéder aux fonctionnalités premium.';
        break;
      case SubscriptionStatus.pastDue:
        explanation = 
          'Votre paiement est en retard.\n\n'
          'Stripe essaie de récupérer le paiement automatiquement.\n'
          'Vérifiez votre moyen de paiement.';
        break;
      case SubscriptionStatus.canceled:
        explanation = 
          'Votre abonnement a été annulé.\n\n'
          'Vous pouvez toujours avoir accès jusqu\'à la fin de la période payée.';
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Comprendre',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              explanation,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumButton(BuildContext context, SubscriptionStatus status) {
    if (status.hasAccess) {
      return ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PremiumScreen()),
          );
        },
        icon: const Icon(Icons.star),
        label: const Text('Accéder aux fonctionnalités Premium'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PaywallScreen()),
        );
      },
      icon: const Icon(Icons.lock),
      label: const Text('Débloquer les fonctionnalités Premium'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations utilisateur',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text('Email : ${user?.email ?? "Non disponible"}'),
            Text('UID : ${user?.uid ?? "Non disponible"}'),
          ],
        ),
      ),
    );
  }
}

