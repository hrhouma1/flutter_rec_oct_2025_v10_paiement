# Application Flutter - Apprendre les abonnements Stripe

Application pédagogique minimale pour comprendre l'intégration de Stripe avec Firebase et Flutter.

## Architecture

```
Flutter App
    |
    +-- Firebase Auth (authentification)
    |
    +-- Firestore (lecture du statut d'abonnement)
    |       ^
    |       |
    |       | (synchronisation automatique)
    |       |
    +-- Extension Firebase Stripe
            |
            +-- Cloud Functions (gestion webhooks)
            |
            +-- Stripe API (paiements)
```

## Prérequis

1. Flutter SDK installé (version 3.0+)
2. Compte Firebase avec projet créé
3. Compte Stripe (mode test)
4. FlutterFire CLI installé : `dart pub global activate flutterfire_cli`

## Configuration étape par étape

### Étape 1 : Configuration Firebase

1. Créer un projet Firebase sur https://console.firebase.google.com

2. Activer Firebase Authentication :
   - Aller dans "Authentication" > "Sign-in method"
   - Activer "Email/Password"

3. Activer Firestore :
   - Aller dans "Firestore Database"
   - Créer une base de données en mode test
   - Règles de sécurité (pour le développement) :
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{userId} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
         
         match /checkout_sessions/{sessionId} {
           allow read, write: if request.auth != null && request.auth.uid == userId;
         }
         
         match /subscriptions/{subscriptionId} {
           allow read: if request.auth != null && request.auth.uid == userId;
         }
       }
     }
   }
   ```

4. Configurer l'app Flutter avec Firebase :
   ```bash
   flutterfire configure
   ```
   Cette commande va générer le fichier `lib/firebase_options.dart` avec vos vraies valeurs.

### Étape 2 : Configuration Stripe

1. Créer un compte sur https://dashboard.stripe.com

2. Activer le mode test (toggle en haut à droite)

3. Créer un produit :
   - Aller dans "Products" > "Add product"
   - Nom : "Plan Premium"
   - Prix : 19 EUR (ou votre choix)
   - Type : Recurring (mensuel)

4. Récupérer l'ID du prix :
   - Cliquer sur le prix créé
   - Copier l'ID qui commence par `price_...`
   - Le coller dans `lib/services/subscription_service.dart` (ligne 20)

5. Récupérer les clés API :
   - Aller dans "Developers" > "API keys"
   - Noter la "Secret key" (commence par `sk_test_...`)
   - Vous en aurez besoin pour l'extension Firebase

### Étape 3 : Installation de l'extension Firebase Stripe

1. Aller dans Firebase Console > Extensions

2. Chercher "Run Payments with Stripe"

3. Installer l'extension avec ces paramètres :
   - **Stripe API key** : Votre clé secrète Stripe (`sk_test_...`)
   - **Firestore collection for customers** : `users`
   - **Firestore collection for products** : `products`
   - **Sync new users** : Yes
   - **Delete Stripe customers** : No (recommandé)

4. L'extension va automatiquement :
   - Créer des Cloud Functions
   - Configurer les webhooks Stripe
   - Créer les collections Firestore nécessaires

5. Vérifier que les webhooks sont configurés :
   - Aller dans Stripe Dashboard > "Developers" > "Webhooks"
   - Vous devriez voir un endpoint créé par Firebase

### Étape 4 : Synchroniser les produits Stripe vers Firestore

1. Dans Stripe Dashboard, trouver votre produit

2. Dans ses métadonnées, ajouter :
   - Clé : `firebaseRole`
   - Valeur : `premium`

3. Activer la synchronisation :
   - L'extension Firebase Stripe synchronise automatiquement les produits
   - Vérifier dans Firestore que la collection `products` contient votre produit

### Étape 5 : Lancer l'application

1. Installer les dépendances :
   ```bash
   flutter pub get
   ```

2. Lancer l'app :
   ```bash
   flutter run
   ```

3. Tester le flux complet :
   - Créer un compte
   - Cliquer sur "Débloquer Premium"
   - Utiliser la carte de test : `4242 4242 4242 4242`
   - Date : n'importe quelle date future
   - CVC : n'importe quel code à 3 chiffres

## Structure du code

```
lib/
├── main.dart                    # Point d'entrée, configuration Provider
├── firebase_options.dart        # Configuration Firebase (généré)
├── models/
│   └── subscription_status.dart # Enum des statuts d'abonnement
├── services/
│   ├── auth_service.dart        # Gestion authentification
│   └── subscription_service.dart # Gestion abonnements Stripe
└── screens/
    ├── auth_gate.dart           # Routeur auth/non-auth
    ├── login_screen.dart        # Écran de connexion
    ├── home_screen.dart         # Écran principal avec statut
    ├── paywall_screen.dart      # Écran de vente
    └── premium_screen.dart      # Écran premium protégé
```

## Flux de données expliqué

### 1. Création de compte
```
User → LoginScreen → AuthService.signUpWithEmail()
                   → Firebase Auth (création)
                   → Firestore (document users/{uid})
```

### 2. Initiation du paiement
```
User → PaywallScreen → SubscriptionService.createCheckoutSession()
                     → Firestore (document checkout_sessions/{id})
                     → Extension Firebase (détecte le document)
                     → Stripe API (création session checkout)
                     → Extension (ajoute l'URL au document)
                     → Flutter (ouvre l'URL dans le navigateur)
```

### 3. Après le paiement
```
User paie sur Stripe → Stripe envoie webhook → Extension Firebase
                                              → Cloud Function activée
                                              → Firestore mis à jour
                                                (subscriptions/{id})
                                              → StreamBuilder Flutter
                                              → UI mise à jour
```

### 4. Vérification du statut
```
HomeScreen → StreamBuilder<SubscriptionStatus>
          → SubscriptionService.getSubscriptionStatus()
          → Firestore.collection('users/{uid}/subscriptions')
          → Parse status (active/canceled/etc.)
          → Affichage conditionnel Premium/Paywall
```

## Structure Firestore après un abonnement réussi

### Collection : users/{userId}
```json
{
  "email": "user@example.com",
  "createdAt": "2025-11-24T10:00:00Z",
  "stripeId": "cus_xxxxxxxxxxxxx"
}
```

### Sous-collection : users/{userId}/subscriptions/{subscriptionId}
```json
{
  "status": "active",
  "items": [
    {
      "price": "price_xxxxxxxxxxxxx",
      "quantity": 1
    }
  ],
  "current_period_start": 1700000000,
  "current_period_end": 1702678400,
  "cancel_at_period_end": false,
  "created": 1700000000,
  "stripeLink": "https://dashboard.stripe.com/subscriptions/sub_xxxxx"
}
```

## Statuts d'abonnement Stripe

| Statut | Signification | Accès Premium |
|--------|---------------|---------------|
| `active` | Abonnement actif et payé | Oui |
| `trialing` | Période d'essai | Oui |
| `past_due` | Paiement en retard | Non (ou Oui selon logique métier) |
| `canceled` | Annulé (peut être actif jusqu'à la fin) | Vérifier `current_period_end` |
| `incomplete` | Paiement initial non complété | Non |
| `incomplete_expired` | Paiement échoué définitivement | Non |

## Tester avec les cartes de test Stripe

| Carte | Résultat |
|-------|----------|
| `4242 4242 4242 4242` | Paiement réussi |
| `4000 0025 0000 3155` | Authentification 3D Secure requise |
| `4000 0000 0000 9995` | Paiement refusé |

## Points pédagogiques clés

### 1. Séparation des responsabilités
- **AuthService** : Uniquement l'authentification
- **SubscriptionService** : Uniquement la logique d'abonnement
- **Écrans** : Uniquement l'affichage

### 2. Réactivité avec StreamBuilder
```dart
StreamBuilder<SubscriptionStatus>(
  stream: subscriptionService.getSubscriptionStatus(),
  builder: (context, snapshot) {
    // L'UI se met à jour automatiquement
    // quand Firestore change
  },
)
```

### 3. Pas de backend personnalisé
- Pas besoin de serveur Node.js/Python
- Tout est géré par l'extension Firebase
- Les Cloud Functions sont générées automatiquement

### 4. Sécurité
- Les clés Stripe ne sont JAMAIS dans le code Flutter
- Tout passe par Firebase (sécurisé côté serveur)
- Les règles Firestore protègent les données

## Prochaines étapes d'apprentissage

1. Ajouter un plan annuel (créer un deuxième prix dans Stripe)
2. Implémenter une période d'essai gratuite
3. Ajouter des webhooks personnalisés
4. Créer un écran d'historique de facturation
5. Gérer le changement de plan (upgrade/downgrade)
6. Ajouter des analytics (qui s'abonne, taux de conversion)

## Débogage

### Vérifier que l'extension fonctionne
```
Firebase Console > Functions
```
Vous devriez voir des fonctions comme :
- `ext-firestore-stripe-payments-createPortalLink`
- `ext-firestore-stripe-payments-onCustomerDataDeleted`
- `ext-firestore-stripe-payments-onUserDeleted`

### Voir les logs
```
Firebase Console > Functions > Logs
```

### Vérifier les webhooks Stripe
```
Stripe Dashboard > Developers > Webhooks > [votre endpoint] > Events
```

## Ressources

- [Documentation Extension Firebase Stripe](https://github.com/stripe/stripe-firebase-extensions)
- [Documentation Stripe Checkout](https://stripe.com/docs/payments/checkout)
- [Documentation Firebase Auth](https://firebase.google.com/docs/auth)
- [Documentation Firestore](https://firebase.google.com/docs/firestore)

## Licence

Ce code est fourni à des fins pédagogiques uniquement.

