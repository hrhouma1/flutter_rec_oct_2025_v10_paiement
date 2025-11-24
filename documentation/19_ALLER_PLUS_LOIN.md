# 19 - Aller plus loin

## Fonctionnalités avancées à implémenter

### 1. Plusieurs plans tarifaires

**Concept :** Offrir Basic, Pro, Enterprise

**Implémentation :**

```dart
enum Plan {
  basic,
  pro,
  enterprise,
}

class PlanConfig {
  final Plan plan;
  final String priceId;
  final double monthlyPrice;
  final double annualPrice;
  final List<String> features;
  
  const PlanConfig({
    required this.plan,
    required this.priceId,
    required this.monthlyPrice,
    required this.annualPrice,
    required this.features,
  });
}

const plans = [
  PlanConfig(
    plan: Plan.basic,
    priceId: 'price_basic_monthly',
    monthlyPrice: 9.99,
    annualPrice: 99.99,
    features: [
      'Fonctionnalité A',
      'Fonctionnalité B',
    ],
  ),
  PlanConfig(
    plan: Plan.pro,
    priceId: 'price_pro_monthly',
    monthlyPrice: 19.99,
    annualPrice: 199.99,
    features: [
      'Tout Basic +',
      'Fonctionnalité C',
      'Fonctionnalité D',
    ],
  ),
  PlanConfig(
    plan: Plan.enterprise,
    priceId: 'price_enterprise_monthly',
    monthlyPrice: 49.99,
    annualPrice: 499.99,
    features: [
      'Tout Pro +',
      'Fonctionnalité E',
      'Support prioritaire',
    ],
  ),
];
```

### 2. Upgrade / Downgrade d'abonnement

**Stripe gère automatiquement le prorata**

**Implémentation :**

```dart
Future<void> changeSubscription(String newPriceId) async {
  final userId = _auth.currentUser?.uid;
  
  if (userId == null) {
    throw Exception('Non connecté');
  }
  
  // Récupérer l'abonnement actuel
  final subSnapshot = await _firestore
    .collection('users/$userId/subscriptions')
    .where('status', isEqualTo: 'active')
    .limit(1)
    .get();
  
  if (subSnapshot.docs.isEmpty) {
    throw Exception('Aucun abonnement actif');
  }
  
  final subId = subSnapshot.docs.first.id;
  
  // Créer une demande de changement
  await _firestore
    .collection('users/$userId/subscriptions')
    .doc(subId)
    .collection('subscription_updates')
    .add({
      'items': [
        {
          'price': newPriceId,
        }
      ],
      'proration_behavior': 'create_prorations',
      'metadata': {
        'action': 'upgrade',
      },
    });
}
```

**Cloud Function correspondante :**
```javascript
exports.handleSubscriptionUpdate = functions.firestore
  .document('users/{uid}/subscriptions/{subId}/subscription_updates/{updateId}')
  .onCreate(async (snap, context) => {
    const updateData = snap.data();
    const subscriptionId = context.params.subId;
    
    // Mettre à jour via Stripe API
    await stripe.subscriptions.update(subscriptionId, {
      items: updateData.items,
      proration_behavior: updateData.proration_behavior,
    });
    
    // Marquer comme traité
    await snap.ref.update({ processed: true });
  });
```

### 3. Période d'essai gratuite

**Concept :** 7 jours gratuits, puis facturation

**Configuration Stripe :**
1. Stripe Dashboard > Products > votre produit
2. Free trial : 7 days

**Ou dans le code :**
```dart
await _firestore
  .collection('users/$userId/checkout_sessions')
  .add({
    'price': priceId,
    'trial_period_days': 7,
    'mode': 'subscription',
  });
```

**Gestion dans l'app :**
```dart
Widget buildTrialInfo(Map<String, dynamic> subscription) {
  if (subscription['status'] != 'trialing') {
    return const SizedBox.shrink();
  }
  
  final trialEnd = subscription['trial_end'] as int;
  final endDate = DateTime.fromMillisecondsSinceEpoch(trialEnd * 1000);
  final daysLeft = endDate.difference(DateTime.now()).inDays;
  
  return Card(
    color: Colors.blue.shade50,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            'Essai gratuit',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text('$daysLeft jours restants'),
          Text(
            'Première facturation le ${DateFormat('dd/MM/yyyy').format(endDate)}',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    ),
  );
}
```

### 4. Codes promo et coupons

**Créer un coupon dans Stripe :**
1. Stripe Dashboard > Products > Coupons
2. Créer un coupon :
   - Type : Pourcentage ou montant fixe
   - Valeur : 20%
   - Durée : Une fois, toujours, ou X mois
   - ID : PROMO20

**Appliquer dans l'app :**
```dart
await _firestore
  .collection('users/$userId/checkout_sessions')
  .add({
    'price': priceId,
    'allow_promotion_codes': true,  // ← L'utilisateur peut saisir un code
    'mode': 'subscription',
  });
```

**Ou appliquer automatiquement :**
```dart
await _firestore
  .collection('users/$userId/checkout_sessions')
  .add({
    'price': priceId,
    'discounts': [
      {'coupon': 'PROMO20'}  // ← Appliqué automatiquement
    ],
    'mode': 'subscription',
  });
```

### 5. Webhooks personnalisés

**Réagir à des événements spécifiques**

**Exemple : Email de bienvenue**
```javascript
exports.onSubscriptionCreated = functions.firestore
  .document('users/{uid}/subscriptions/{subId}')
  .onCreate(async (snap, context) => {
    const subscription = snap.data();
    const userId = context.params.uid;
    
    // Récupérer l'email de l'utilisateur
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(userId)
      .get();
    
    const email = userDoc.data().email;
    
    // Envoyer un email de bienvenue
    await sendWelcomeEmail(email, subscription);
  });
```

**Exemple : Notifications push**
```javascript
exports.onPaymentFailed = functions.firestore
  .document('users/{uid}/payments/{paymentId}')
  .onCreate(async (snap, context) => {
    const payment = snap.data();
    
    if (payment.status === 'failed') {
      const userId = context.params.uid;
      
      // Envoyer une notification push
      await admin.messaging().send({
        token: userToken,
        notification: {
          title: 'Paiement échoué',
          body: 'Veuillez mettre à jour votre moyen de paiement',
        },
      });
    }
  });
```

### 6. Analytics avancées

**Suivre la conversion**

```dart
class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  
  // Funnel d'abonnement
  Future<void> logViewPaywall() async {
    await _analytics.logEvent(name: 'view_paywall');
  }
  
  Future<void> logInitiateCheckout(String priceId, double value) async {
    await _analytics.logBeginCheckout(
      value: value,
      currency: 'EUR',
      items: [
        AnalyticsEventItem(
          itemId: priceId,
          itemName: 'subscription',
        ),
      ],
    );
  }
  
  Future<void> logCompletePurchase(String priceId, double value) async {
    await _analytics.logPurchase(
      value: value,
      currency: 'EUR',
      items: [
        AnalyticsEventItem(
          itemId: priceId,
          itemName: 'subscription',
        ),
      ],
    );
  }
  
  // Cohort analysis
  Future<void> setUserProperties(String plan) async {
    await _analytics.setUserProperty(
      name: 'subscription_plan',
      value: plan,
    );
  }
}
```

**Tableaux de bord recommandés :**
- Taux de conversion (vues paywall → abonnements)
- MRR (Monthly Recurring Revenue)
- Churn rate (taux d'annulation)
- LTV (Lifetime Value)

### 7. Tests A/B

**Tester différents prix**

```dart
// Assigner aléatoirement un prix
String getTestPrice() {
  final random = Random();
  final variant = random.nextBool() ? 'A' : 'B';
  
  // Logger le variant
  FirebaseAnalytics.instance.setUserProperty(
    name: 'price_test_variant',
    value: variant,
  );
  
  return variant == 'A' 
    ? 'price_19_per_month'
    : 'price_24_per_month';
}
```

**Analyser les résultats dans Firebase Analytics**

### 8. Gestion des taxes

**Stripe Tax (automatique)**

```dart
await _firestore
  .collection('users/$userId/checkout_sessions')
  .add({
    'price': priceId,
    'automatic_tax': {'enabled': true},  // ← Calcul automatique
    'mode': 'subscription',
  });
```

Stripe calculera automatiquement les taxes selon le pays de l'utilisateur.

### 9. Facturation usage-based

**Concept :** Facturer selon l'utilisation (ex: nombre d'appels API)

**Configuration Stripe :**
1. Créer un prix "metered" dans Stripe
2. Reporter l'usage via API

**Cloud Function pour reporter l'usage :**
```javascript
exports.reportUsage = functions.https.onCall(async (data, context) => {
  const userId = context.auth.uid;
  const quantity = data.quantity;
  
  // Récupérer l'abonnement
  const subSnapshot = await admin.firestore()
    .collection(`users/${userId}/subscriptions`)
    .where('status', '==', 'active')
    .limit(1)
    .get();
  
  const subscription = subSnapshot.docs[0].data();
  const subscriptionItemId = subscription.items[0].id;
  
  // Reporter l'usage à Stripe
  await stripe.subscriptionItems.createUsageRecord(
    subscriptionItemId,
    {
      quantity: quantity,
      timestamp: Math.floor(Date.now() / 1000),
    }
  );
});
```

### 10. Multi-devises

**Supporter plusieurs devises**

```dart
enum Currency {
  eur,
  usd,
  gbp,
}

class PriceInfo {
  final String priceIdEur;
  final String priceIdUsd;
  final String priceIdGbp;
  
  String getPriceId(Currency currency) {
    switch (currency) {
      case Currency.eur:
        return priceIdEur;
      case Currency.usd:
        return priceIdUsd;
      case Currency.gbp:
        return priceIdGbp;
    }
  }
}

// Détecter la devise de l'utilisateur
Currency detectUserCurrency() {
  final locale = Localizations.localeOf(context);
  
  switch (locale.countryCode) {
    case 'US':
    case 'CA':
      return Currency.usd;
    case 'GB':
      return Currency.gbp;
    default:
      return Currency.eur;
  }
}
```

## Ressources pour aller plus loin

### Documentation officielle

**Flutter**
- Architecture : https://docs.flutter.dev/development/data-and-backend/state-mgmt
- Performance : https://docs.flutter.dev/perf/best-practices

**Firebase**
- Extensions : https://firebase.google.com/products/extensions
- Best practices : https://firebase.google.com/docs/firestore/best-practices

**Stripe**
- Subscriptions guide : https://stripe.com/docs/billing/subscriptions/overview
- Testing : https://stripe.com/docs/testing
- Webhooks : https://stripe.com/docs/webhooks

### Cours et tutoriels

- Firebase YouTube Channel
- Stripe YouTube Channel
- Flutter & Firebase Course (Fireship.io)

### Outils

- Stripe CLI : https://stripe.com/docs/stripe-cli
- FlutterFire CLI : https://firebase.google.com/docs/flutter/setup
- Postman Stripe Collection

### Communautés

- r/FlutterDev (Reddit)
- Flutter Discord
- Stack Overflow (tags: flutter, firebase, stripe)

## Projets d'exemple

### Construire une app complète

**Idées de projets :**

1. **App de méditation**
   - Plan gratuit : 5 méditations
   - Plan premium : bibliothèque complète
   - Période d'essai : 7 jours

2. **App de fitness**
   - Plan gratuit : exercices de base
   - Plan premium : programmes personnalisés
   - Facturation annuelle avec réduction

3. **App d'apprentissage de langues**
   - Plan gratuit : 10 leçons
   - Plan premium : cours illimités
   - Codes promo pour les étudiants

4. **App de productivité**
   - Plan gratuit : 3 projets
   - Plan pro : projets illimités
   - Plan entreprise : collaboration équipe

## Certification et déploiement

### Checklist avant publication

**Technique**
- [ ] Tests unitaires
- [ ] Tests d'intégration
- [ ] Tests sur vrais appareils
- [ ] Performance optimisée
- [ ] Taille de l'app réduite

**Sécurité**
- [ ] Règles Firestore production
- [ ] Clés Stripe en mode live
- [ ] Audit de sécurité
- [ ] HTTPS partout

**Légal**
- [ ] Politique de confidentialité
- [ ] Conditions d'utilisation
- [ ] Politique de remboursement
- [ ] Mentions légales

**Business**
- [ ] Prix validés
- [ ] Descriptions claires
- [ ] Support client préparé
- [ ] Monitoring activé

### Publier sur les stores

**Google Play Store**
1. Créer un compte développeur (25 $ unique)
2. Préparer les assets (icône, screenshots)
3. Remplir la fiche (description, catégorie)
4. Build release : `flutter build appbundle`
5. Upload et soumettre

**Apple App Store**
1. Créer un compte développeur (99 $/an)
2. Préparer les assets
3. Build release : `flutter build ipa`
4. Upload via Xcode ou Transporter
5. Soumettre à la revue

## Conclusion

Vous avez maintenant toutes les connaissances pour :
- Construire une app Flutter avec abonnements
- Intégrer Firebase et Stripe
- Gérer le cycle de vie complet
- Optimiser coûts et performances
- Passer en production

**Prochaines étapes suggérées :**
1. Construire un vrai projet
2. Le publier sur les stores
3. Itérer selon les retours utilisateurs
4. Faire grandir votre base d'abonnés

Bonne chance dans vos projets !

