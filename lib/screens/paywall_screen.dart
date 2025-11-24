import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/subscription_service.dart';

/// Écran de paywall
/// Présente l'offre d'abonnement et permet de lancer le paiement Stripe
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _isLoading = false;

  Future<void> _handleSubscribe() async {
    setState(() => _isLoading = true);

    try {
      final subscriptionService = Provider.of<SubscriptionService>(context, listen: false);
      
      // Cette méthode va :
      // 1. Créer un document dans Firestore (collection checkout_sessions)
      // 2. L'extension Stripe va détecter ce document
      // 3. L'extension va créer une session Stripe Checkout
      // 4. L'extension va ajouter l'URL de checkout au document
      // 5. On récupère cette URL et on l'ouvre dans le navigateur
      await subscriptionService.createCheckoutSession();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Redirection vers le paiement...'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Passer à Premium'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icône
            const Icon(
              Icons.workspace_premium,
              size: 100,
              color: Colors.amber,
            ),
            const SizedBox(height: 24),

            // Titre
            Text(
              'Devenez Premium',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Liste des avantages
            _buildFeatureCard(
              icon: Icons.check_circle,
              title: 'Accès illimité',
              description: 'Toutes les fonctionnalités premium débloquées',
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              icon: Icons.support,
              title: 'Support prioritaire',
              description: 'Réponses rapides à vos questions',
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              icon: Icons.update,
              title: 'Mises à jour en avant-première',
              description: 'Accédez aux nouvelles fonctionnalités en premier',
            ),
            const SizedBox(height: 32),

            // Carte de prix
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      '19 € / mois',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Annulable à tout moment',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Bouton de souscription
            ElevatedButton(
              onPressed: _isLoading ? null : _handleSubscribe,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(20),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'S\'abonner maintenant',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 16),

            // Note pédagogique
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Note de développement',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'En mode test Stripe, utilisez la carte :\n'
                      '• Numéro : 4242 4242 4242 4242\n'
                      '• Date : n\'importe quelle date future\n'
                      '• CVC : n\'importe quel code à 3 chiffres',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.green, size: 32),
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
}

