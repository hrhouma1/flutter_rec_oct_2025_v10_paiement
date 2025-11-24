# Guide Rapide - Application Flutter Stripe Abonnements

## Diagramme de fonctionnement

```
┌─────────────────────────────────────────────────────────────────┐
│                     ARCHITECTURE GLOBALE                         │
└─────────────────────────────────────────────────────────────────┘

   UTILISATEUR                                    
       │
       │ 1. Crée un compte
       ▼
┌──────────────────┐
│  FIREBASE AUTH   │ ← Authentifie l'utilisateur
└────────┬─────────┘
         │ 2. Utilisateur connecté
         │
         ▼
┌──────────────────┐
│   FIRESTORE      │ ← Stocke: users/{uid}
└────────┬─────────┘    - email
         │              - stripeId (ajouté par extension)
         │
         │ 3. Clique "S'abonner"
         ▼
┌──────────────────┐
│  FLUTTER APP     │ ← Crée: checkout_sessions/{id}
└────────┬─────────┘    - price: "price_xxxxx"
         │              - mode: "subscription"
         │
         │ 4. Extension détecte le document
         ▼
┌──────────────────┐
│ EXTENSION STRIPE │ ← Cloud Function déclenchée
└────────┬─────────┘    - Appelle Stripe API
         │              - Ajoute URL au document
         │
         │ 5. Stripe crée session
         ▼
┌──────────────────┐
│     STRIPE       │ ← Génère URL Checkout
└────────┬─────────┘
         │
         │ 6. Flutter ouvre l'URL
         ▼
   UTILISATEUR paie avec carte 4242 4242 4242 4242
         │
         │ 7. Paiement réussi
         ▼
┌──────────────────┐
│     STRIPE       │ ← Envoie webhook
└────────┬─────────┘
         │
         │ 8. Webhook reçu
         ▼
┌──────────────────┐
│ EXTENSION STRIPE │ ← Cloud Function webhook
└────────┬─────────┘    - Parse événement
         │              - Écrit dans Firestore
         │
         │ 9. Crée subscription
         ▼
┌──────────────────┐
│   FIRESTORE      │ ← subscriptions/{subId}
└────────┬─────────┘    - status: "active"
         │              - current_period_end: ...
         │
         │ 10. Stream détecte changement
         ▼
┌──────────────────┐
│  FLUTTER APP     │ ← UI mise à jour automatiquement
└──────────────────┘    Affiche "Abonnement actif"
```

## Configuration en 5 étapes

### 1. Firebase
```bash
# Installer FlutterFire CLI
dart pub global activate flutterfire_cli

# Configurer
flutterfire configure
```

**Console Firebase :**
- Activer Authentication (Email/Password)
- Créer Firestore Database (mode test)
- Copier les règles depuis README.md

### 2. Stripe
**Dashboard Stripe (mode test) :**
- Créer produit "Plan Premium" : 19 €/mois
- Copier Price ID : `price_xxxxxxxxxxxxx`
- Copier Secret Key : `sk_test_xxxxxxxxxxxxx`

**Dans le code :**
```dart
// lib/services/subscription_service.dart ligne 20
static const String monthlyPriceId = 'price_xxxxxxxxxxxxx';
```

### 3. Extension Firebase
**Console Firebase > Extensions :**
- Installer "Run Payments with Stripe"
- Configurer :
  - Stripe API key : `sk_test_xxxxxxxxxxxxx`
  - Customer collection : `users`
  - Sync new users : `Sync`

### 4. Lancer l'app
```bash
flutter pub get
flutter run
```

### 5. Tester
1. Créer un compte : `test@example.com` / `password123`
2. Cliquer "Débloquer Premium"
3. Payer avec carte : `4242 4242 4242 4242`
4. Vérifier statut passe à "Actif"

## Structure du code

```
lib/
├── main.dart                     Point d'entrée
├── firebase_options.dart         Config Firebase (généré)
├── models/
│   └── subscription_status.dart  États: none, active, pastDue, canceled
├── services/
│   ├── auth_service.dart         signUp, signIn, signOut
│   └── subscription_service.dart createCheckoutSession, getSubscriptionStatus
└── screens/
    ├── auth_gate.dart            Routeur auth
    ├── login_screen.dart         Connexion/Inscription
    ├── home_screen.dart          Affiche statut
    ├── paywall_screen.dart       Vente
    └── premium_screen.dart       Contenu premium
```

## Flux de données clés

### Inscription
```
LoginScreen → AuthService.signUpWithEmail()
           → Firebase Auth crée compte
           → Firestore crée users/{uid}
           → Navigation automatique vers HomeScreen
```

### Abonnement
```
PaywallScreen → SubscriptionService.createCheckoutSession()
             → Firestore: checkout_sessions/{id}
             → Extension détecte (trigger)
             → Stripe API: crée session
             → Extension: ajoute URL
             → Flutter: ouvre URL
             → User paie
             → Stripe: webhook
             → Extension: écrit subscription
             → Flutter StreamBuilder: détecte
             → UI: "Abonnement actif"
```

### Vérification statut
```
HomeScreen → StreamBuilder<SubscriptionStatus>
          → SubscriptionService.getSubscriptionStatus()
          → Firestore: écoute subscriptions
          → Parse status
          → Affiche UI selon statut
```

## Firestore

### Après inscription
```
users/{uid}
  - email: "user@example.com"
  - createdAt: timestamp
```

### Après abonnement
```
users/{uid}
  - email: "user@example.com"
  - createdAt: timestamp
  - stripeId: "cus_xxxxx"          ← Ajouté par extension
  
  subscriptions/{subId}             ← Créé par extension
    - status: "active"
    - current_period_end: timestamp
    - items: [...]
```

## Dépannage rapide

### URL Checkout ne se crée pas
- Vérifier extension installée (Firebase Console > Extensions)
- Vérifier Price ID correct dans `subscription_service.dart`
- Vérifier clé Stripe dans extension

### Paiement non synchronisé
- Vérifier webhook dans Stripe Dashboard > Webhooks
- Vérifier logs Firebase Functions
- Vérifier `stripeId` existe dans users/{uid}

### Permission denied
- Vérifier règles Firestore publiées
- Vérifier utilisateur connecté

## Règles Firestore (copier/coller)

```javascript
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
        allow write: if false;
      }
    }
    
    match /products/{productId} {
      allow read: if true;
      match /prices/{priceId} {
        allow read: if true;
      }
    }
  }
}
```

## Ressources

- Firebase : https://console.firebase.google.com
- Stripe : https://dashboard.stripe.com
- Extension : https://github.com/stripe/stripe-firebase-extensions

