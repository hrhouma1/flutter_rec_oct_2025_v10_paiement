# 16 - Exercices pratiques

## Exercice 1 : Ajouter un plan annuel

### Objectif
Permettre à l'utilisateur de choisir entre un plan mensuel et un plan annuel.

### Difficulté
⭐ Facile

### Étapes

1. **Créer le prix annuel dans Stripe**
   - Prix : 190 € / an (économie de 2 mois)
   - Récupérer le Price ID

2. **Ajouter la constante dans le code**
```dart
// subscription_service.dart
static const String monthlyPriceId = 'price_xxxxx';
static const String annualPriceId = 'price_yyyyy';  // ← Nouveau
```

3. **Modifier createCheckoutSession pour accepter un paramètre**
```dart
Future<void> createCheckoutSession({required String priceId}) async {
  // ...
  .add({
    'price': priceId,  // ← Utiliser le paramètre
    // ...
  });
}
```

4. **Modifier PaywallScreen**
```dart
// Ajouter un toggle ou deux boutons
bool _isAnnual = false;

// Dans le build
SegmentedButton<bool>(
  segments: [
    ButtonSegment(value: false, label: Text('Mensuel - 19 €')),
    ButtonSegment(value: true, label: Text('Annuel - 190 €')),
  ],
  selected: {_isAnnual},
  onSelectionChanged: (Set<bool> newSelection) {
    setState(() => _isAnnual = newSelection.first);
  },
)

// Dans _handleSubscribe
final priceId = _isAnnual 
  ? SubscriptionService.annualPriceId 
  : SubscriptionService.monthlyPriceId;
  
await subscriptionService.createCheckoutSession(priceId: priceId);
```

### Validation
- [ ] Deux prix visibles dans PaywallScreen
- [ ] Sélection fonctionne
- [ ] Paiement mensuel fonctionne
- [ ] Paiement annuel fonctionne
- [ ] HomeScreen affiche le bon plan

## Exercice 2 : Afficher la date de renouvellement

### Objectif
Afficher dans HomeScreen la date du prochain renouvellement.

### Difficulté
⭐ Facile

### Étapes

1. **Modifier getSubscriptionStatus pour retourner plus de données**
```dart
class SubscriptionData {
  final SubscriptionStatus status;
  final DateTime? nextRenewal;
  
  SubscriptionData({required this.status, this.nextRenewal});
}

Stream<SubscriptionData> getSubscriptionData() {
  return _firestore
    .collection('users/$userId/subscriptions')
    .snapshots()
    .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return SubscriptionData(status: SubscriptionStatus.none);
      }
      
      final data = snapshot.docs.first.data();
      final status = _parseSubscriptionStatus(data);
      
      DateTime? nextRenewal;
      if (data.containsKey('current_period_end')) {
        final periodEnd = data['current_period_end'] as int;
        nextRenewal = DateTime.fromMillisecondsSinceEpoch(periodEnd * 1000);
      }
      
      return SubscriptionData(status: status, nextRenewal: nextRenewal);
    });
}
```

2. **Ajouter le package intl**
```yaml
# pubspec.yaml
dependencies:
  intl: ^0.19.0
```

3. **Afficher dans HomeScreen**
```dart
import 'package:intl/intl.dart';

StreamBuilder<SubscriptionData>(
  stream: subscriptionService.getSubscriptionData(),
  builder: (context, snapshot) {
    final data = snapshot.data;
    
    if (data?.nextRenewal != null) {
      final formatted = DateFormat('dd MMMM yyyy', 'fr_FR')
        .format(data!.nextRenewal!);
      
      return Text('Prochain renouvellement : $formatted');
    }
    
    return const SizedBox.shrink();
  },
)
```

### Validation
- [ ] Date affichée pour abonnement actif
- [ ] Rien affiché pour utilisateur sans abonnement
- [ ] Format français correct

## Exercice 3 : Historique des paiements

### Objectif
Créer un écran affichant l'historique des paiements.

### Difficulté
⭐⭐ Moyen

### Étapes

1. **Créer PaymentsHistoryScreen**
```dart
class PaymentsHistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Historique des paiements')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
          .collection('users/$userId/payments')
          .orderBy('created', descending: true)
          .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final payments = snapshot.data!.docs;
          
          if (payments.isEmpty) {
            return const Center(child: Text('Aucun paiement'));
          }
          
          return ListView.builder(
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index].data() as Map<String, dynamic>;
              return _buildPaymentTile(payment);
            },
          );
        },
      ),
    );
  }
  
  Widget _buildPaymentTile(Map<String, dynamic> payment) {
    final amount = payment['amount'] as int;
    final currency = payment['currency'] as String;
    final status = payment['status'] as String;
    final created = (payment['created'] as Timestamp).toDate();
    
    return ListTile(
      leading: Icon(
        status == 'succeeded' ? Icons.check_circle : Icons.error,
        color: status == 'succeeded' ? Colors.green : Colors.red,
      ),
      title: Text('${amount / 100} ${currency.toUpperCase()}'),
      subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(created)),
      trailing: Chip(label: Text(status)),
    );
  }
}
```

2. **Ajouter un bouton dans HomeScreen**
```dart
TextButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PaymentsHistoryScreen()),
    );
  },
  icon: const Icon(Icons.history),
  label: const Text('Historique des paiements'),
)
```

### Validation
- [ ] Liste des paiements affichée
- [ ] Montants corrects
- [ ] Dates formatées
- [ ] Statuts visuels (icônes, couleurs)

## Exercice 4 : Période d'essai

### Objectif
Ajouter une période d'essai gratuite de 7 jours.

### Difficulté
⭐⭐ Moyen

### Étapes

1. **Activer la période d'essai dans Stripe**
   - Stripe Dashboard > Products > votre produit
   - Section "Trial period" : 7 days

2. **Modifier la session Checkout**
```dart
// subscription_service.dart
.add({
  'price': priceId,
  'trial_period_days': 7,  // ← Nouveau
  'mode': 'subscription',
  // ...
});
```

3. **Adapter le parsing du statut**
```dart
SubscriptionStatus _parseSubscriptionStatus(Map<String, dynamic> data) {
  final status = data['status'] as String?;
  
  switch (status) {
    case 'active':
    case 'trialing':  // ← Période d'essai
      return SubscriptionStatus.active;
    // ...
  }
}
```

4. **Afficher l'info dans HomeScreen**
```dart
if (subscriptionData['status'] == 'trialing') {
  final trialEnd = subscriptionData['trial_end'] as int;
  final endDate = DateTime.fromMillisecondsSinceEpoch(trialEnd * 1000);
  final daysLeft = endDate.difference(DateTime.now()).inDays;
  
  return Card(
    child: Text('Essai gratuit : encore $daysLeft jours'),
  );
}
```

### Validation
- [ ] Paiement initial à 0 €
- [ ] Status "trialing" dans Firestore
- [ ] Accès premium immédiat
- [ ] Première facturation dans 7 jours

## Exercice 5 : Code promo

### Objectif
Permettre d'appliquer un code promo à l'abonnement.

### Difficulté
⭐⭐⭐ Difficile

### Étapes

1. **Créer un code promo dans Stripe**
   - Stripe Dashboard > Products > Coupons
   - Créer un coupon : 20% de réduction
   - Récupérer l'ID du coupon

2. **Ajouter un champ dans PaywallScreen**
```dart
final _promoController = TextEditingController();

TextField(
  controller: _promoController,
  decoration: InputDecoration(
    labelText: 'Code promo',
    hintText: 'PROMO20',
  ),
)
```

3. **Passer le code à la session Checkout**
```dart
final data = {
  'price': priceId,
  'mode': 'subscription',
  'success_url': '...',
  'cancel_url': '...',
};

// Ajouter le code promo si présent
if (_promoController.text.isNotEmpty) {
  data['promotion_code'] = _promoController.text.trim();
}

await _firestore
  .collection('users/$userId/checkout_sessions')
  .add(data);
```

4. **Gérer les erreurs**
   - Code invalide
   - Code expiré
   - Code déjà utilisé

### Validation
- [ ] Code promo valide accepté
- [ ] Réduction appliquée dans Stripe
- [ ] Code invalide refusé avec message clair

## Exercice 6 : Analytics

### Objectif
Tracker les événements importants.

### Difficulté
⭐⭐ Moyen

### Étapes

1. **Ajouter Firebase Analytics**
```yaml
# pubspec.yaml
dependencies:
  firebase_analytics: ^11.3.3
```

2. **Créer un service Analytics**
```dart
class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  
  Future<void> logSignUp() async {
    await _analytics.logSignUp(signUpMethod: 'email');
  }
  
  Future<void> logPurchase(double value, String currency) async {
    await _analytics.logPurchase(
      value: value,
      currency: currency,
      items: [
        AnalyticsEventItem(
          itemName: 'subscription',
          itemCategory: 'premium',
        ),
      ],
    );
  }
  
  Future<void> logSubscriptionStart() async {
    await _analytics.logEvent(
      name: 'subscription_start',
      parameters: {'method': 'stripe'},
    );
  }
  
  Future<void> logSubscriptionCancel() async {
    await _analytics.logEvent(name: 'subscription_cancel');
  }
}
```

3. **Logger les événements**
```dart
// Lors de l'inscription
await analyticsService.logSignUp();

// Lors du paiement réussi
await analyticsService.logPurchase(19.0, 'EUR');
await analyticsService.logSubscriptionStart();
```

### Validation
- [ ] Événements visibles dans Firebase Analytics
- [ ] Funnel de conversion traçable

## Solutions

Les solutions complètes sont disponibles dans des branches Git séparées.

Pour voir une solution :
```bash
git checkout exercice-1-plan-annuel
```

## Prochaine étape

Approfondir la sécurité : [Sécurité et bonnes pratiques](17_SECURITE.md)

