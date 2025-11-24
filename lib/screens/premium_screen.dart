import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/subscription_service.dart';

/// Écran des fonctionnalités Premium
/// Accessible uniquement aux utilisateurs avec un abonnement actif
class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Premium'),
        backgroundColor: Colors.amber,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Badge Premium
            const Center(
              child: Icon(
                Icons.workspace_premium,
                size: 80,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Bienvenue dans l\'espace Premium',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Contenu premium fictif
            _buildPremiumFeature(
              context,
              icon: Icons.analytics,
              title: 'Analyses avancées',
              description: 'Accédez à des statistiques détaillées et des rapports personnalisés.',
            ),
            const SizedBox(height: 16),
            _buildPremiumFeature(
              context,
              icon: Icons.cloud_upload,
              title: 'Stockage illimité',
              description: 'Sauvegardez tous vos fichiers sans limite de taille.',
            ),
            const SizedBox(height: 16),
            _buildPremiumFeature(
              context,
              icon: Icons.speed,
              title: 'Performances accrues',
              description: 'Profitez d\'une application plus rapide et plus fluide.',
            ),
            const SizedBox(height: 32),

            // Explication pédagogique
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.school, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          'Point pédagogique',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Cet écran est protégé par le statut d\'abonnement.\n\n'
                      'Le flux de données :\n'
                      '1. L\'utilisateur paie via Stripe Checkout\n'
                      '2. Stripe envoie un webhook à Firebase\n'
                      '3. L\'extension met à jour Firestore\n'
                      '4. Flutter lit Firestore en temps réel\n'
                      '5. L\'UI se met à jour automatiquement\n\n'
                      'Aucun backend personnalisé nécessaire !',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Bouton pour gérer l'abonnement
            OutlinedButton.icon(
              onPressed: () => _openCustomerPortal(context),
              icon: const Icon(Icons.settings),
              label: const Text('Gérer mon abonnement'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumFeature(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.amber.shade700, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
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

  Future<void> _openCustomerPortal(BuildContext context) async {
    try {
      final subscriptionService = Provider.of<SubscriptionService>(context, listen: false);
      
      // Le portail client Stripe permet de :
      // - Annuler l'abonnement
      // - Mettre à jour le moyen de paiement
      // - Voir l'historique de facturation
      // - Télécharger les factures
      await subscriptionService.createPortalSession();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ouverture du portail de gestion...'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

