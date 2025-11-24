# Guide d'installation pas à pas

Ce guide vous accompagne dans la configuration complète de l'application.

## Prérequis système

Avant de commencer, vérifiez que vous avez :

- [ ] Flutter SDK 3.0 ou supérieur installé
- [ ] Un éditeur (VS Code ou Android Studio)
- [ ] Git installé
- [ ] Un compte Google (pour Firebase)
- [ ] Un compte email (pour Stripe)

Vérifier votre installation Flutter :
```bash
flutter doctor
```

## Partie 1 : Configuration Firebase (15 minutes)

### 1.1 Créer le projet Firebase

1. Aller sur https://console.firebase.google.com
2. Cliquer sur "Ajouter un projet"
3. Nom du projet : `flutter-stripe-learning` (ou votre choix)
4. Désactiver Google Analytics (optionnel pour ce projet d'apprentissage)
5. Cliquer sur "Créer un projet"
6. Attendre la création (environ 1 minute)

### 1.2 Activer l'authentification

1. Dans le menu de gauche, cliquer sur "Authentication"
2. Cliquer sur "Commencer"
3. Onglet "Sign-in method"
4. Cliquer sur "Email/Password"
5. Activer le premier toggle (Email/Password)
6. Cliquer sur "Enregistrer"

### 1.3 Créer la base de données Firestore

1. Dans le menu de gauche, cliquer sur "Firestore Database"
2. Cliquer sur "Créer une base de données"
3. Choisir "Démarrer en mode test" (pour le développement)
4. Choisir un emplacement (europe-west par exemple)
5. Cliquer sur "Activer"

### 1.4 Configurer les règles de sécurité Firestore

1. Dans Firestore, aller sur l'onglet "Règles"
2. Remplacer le contenu par :

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Règles pour les documents utilisateur
    match /users/{userId} {
      // L'utilisateur peut lire et écrire son propre document
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Sessions de checkout Stripe
      match /checkout_sessions/{sessionId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      // Abonnements (lecture seule, écriture par l'extension)
      match /subscriptions/{subscriptionId} {
        allow read: if request.auth != null && request.auth.uid == userId;
      }
      
      // Paiements (lecture seule)
      match /payments/{paymentId} {
        allow read: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // Collection des produits (lecture publique)
    match /products/{productId} {
      allow read: if true;
      
      match /prices/{priceId} {
        allow read: if true;
      }
    }
  }
}
```

3. Cliquer sur "Publier"

### 1.5 Connecter Flutter à Firebase

1. Installer FlutterFire CLI :
```bash
dart pub global activate flutterfire_cli
```

2. Dans le dossier de votre projet Flutter, exécuter :
```bash
flutterfire configure
```

3. Sélectionner votre projet Firebase
4. Sélectionner les plateformes (Android, iOS, Web selon vos besoins)
5. Le fichier `lib/firebase_options.dart` est créé automatiquement

## Partie 2 : Configuration Stripe (10 minutes)

### 2.1 Créer un compte Stripe

1. Aller sur https://dashboard.stripe.com/register
2. Créer un compte avec votre email
3. Vérifier votre email
4. Compléter les informations de base

### 2.2 Activer le mode test

1. En haut à droite du dashboard Stripe
2. Vérifier que le toggle "Test" est activé
3. Toutes les opérations seront en mode test (pas d'argent réel)

### 2.3 Créer un produit et un prix

1. Dans le menu de gauche, cliquer sur "Products"
2. Cliquer sur "Add product"
3. Remplir :
   - **Name** : Plan Premium
   - **Description** : Accès illimité aux fonctionnalités premium
   - **Pricing model** : Standard pricing
   - **Price** : 19.00 EUR (ou votre choix)
   - **Billing period** : Monthly
4. Cliquer sur "Add product"

### 2.4 Récupérer l'ID du prix

1. Dans la page du produit, section "Pricing"
2. Cliquer sur le prix que vous venez de créer
3. En haut, vous verrez "Price ID" : `price_xxxxxxxxxxxxx`
4. **Copier cet ID** (vous en aurez besoin)

### 2.5 Récupérer la clé secrète API

1. Dans le menu de gauche, cliquer sur "Developers"
2. Cliquer sur "API keys"
3. Trouver "Secret key" (commence par `sk_test_`)
4. Cliquer sur "Reveal test key"
5. **Copier cette clé** (IMPORTANT : ne jamais la partager publiquement)

### 2.6 Mettre à jour le code Flutter avec l'ID du prix

1. Ouvrir `lib/services/subscription_service.dart`
2. Ligne 20, remplacer :
```dart
static const String monthlyPriceId = 'price_VOTRE_PRICE_ID_ICI';
```
par :
```dart
static const String monthlyPriceId = 'price_xxxxxxxxxxxxx'; // Votre ID
```

## Partie 3 : Installation de l'extension Firebase Stripe (15 minutes)

### 3.1 Installer l'extension

1. Retourner dans Firebase Console
2. Dans le menu de gauche, cliquer sur "Extensions"
3. Cliquer sur "Explorer les extensions"
4. Chercher "Run Payments with Stripe"
5. Cliquer sur l'extension (éditeur : Stripe)
6. Cliquer sur "Install in console"

### 3.2 Configurer l'extension

L'installation vous demandera plusieurs paramètres :

**Écran 1 : Review billing and usage**
- Cliquer sur "Next"

**Écran 2 : Review APIs enabled and resources created**
- Cliquer sur "Next"

**Écran 3 : Configure extension**

Remplir les champs suivants :

1. **Stripe API key with restricted access**
   - Coller votre clé secrète Stripe (`sk_test_...`)

2. **Products and pricing plans collection**
   - Laisser : `products`

3. **Customer details and subscriptions collection**
   - Laisser : `customers`
   - OU mettre : `users` (recommandé pour cette app)

4. **Sync new users to Stripe customers**
   - Sélectionner : `Sync`

5. **Delete Stripe customer objects**
   - Sélectionner : `Do not delete` (recommandé)

6. **Stripe webhook secret**
   - Laisser vide pour l'instant (sera configuré automatiquement)

Autres paramètres : laisser les valeurs par défaut

7. Cliquer sur "Install extension"
8. Attendre 3-5 minutes (l'extension déploie des Cloud Functions)

### 3.3 Vérifier l'installation

1. Aller dans "Functions" (menu de gauche)
2. Vous devriez voir plusieurs fonctions :
   - `ext-firestore-stripe-payments-createPortalLink`
   - `ext-firestore-stripe-payments-onUserDeleted`
   - `ext-firestore-stripe-payments-onCustomerDataDeleted`
   - etc.

3. Aller dans "Firestore Database"
4. Vous devriez voir la collection `products` (ou `customers`)

### 3.4 Vérifier les webhooks Stripe

1. Retourner dans Stripe Dashboard
2. Aller dans "Developers" > "Webhooks"
3. Vous devriez voir un endpoint créé automatiquement
4. Format : `https://us-central1-VOTRE_PROJET.cloudfunctions.net/ext-firestore-stripe-payments-handleWebhookEvents`
5. Les événements écoutés sont configurés automatiquement

## Partie 4 : Synchroniser les produits (5 minutes)

Pour que l'extension connaisse vos produits :

### Option 1 : Via l'API Stripe (recommandé)

1. Dans Stripe Dashboard, aller sur votre produit "Plan Premium"
2. Cliquer sur "Edit product"
3. Descendre à "Product metadata"
4. Ajouter une métadonnée :
   - **Key** : `firebaseRole`
   - **Value** : `premium`
5. Sauvegarder

L'extension va automatiquement synchroniser ce produit vers Firestore.

### Option 2 : Manuellement dans Firestore

1. Dans Firebase Console > Firestore
2. Créer un document dans `products` :
   - ID du document : (auto)
   - Champs :
     ```
     name: "Plan Premium"
     description: "Accès illimité"
     active: true
     role: "premium"
     images: [] (array vide)
     ```
3. Créer une sous-collection `prices` :
   - ID du document : votre `price_xxxxx` de Stripe
   - Champs :
     ```
     active: true
     currency: "eur"
     interval: "month"
     unit_amount: 1900 (en centimes)
     type: "recurring"
     ```

## Partie 5 : Lancer l'application (5 minutes)

### 5.1 Installer les dépendances

```bash
flutter pub get
```

### 5.2 Vérifier la configuration

Vérifier que vous avez bien :
- [x] `lib/firebase_options.dart` créé par FlutterFire CLI
- [x] L'ID du prix Stripe dans `subscription_service.dart`
- [x] L'extension Firebase installée
- [x] Les règles Firestore configurées

### 5.3 Lancer l'app

```bash
flutter run
```

Choisir votre device (émulateur, navigateur, ou téléphone)

### 5.4 Tester le flux complet

1. **Créer un compte** :
   - Email : `test@example.com`
   - Mot de passe : `password123`

2. **Vérifier dans Firestore** :
   - Un document devrait être créé dans `users/[uid]`

3. **Cliquer sur "Débloquer Premium"**

4. **Compléter le paiement Stripe** :
   - Carte : `4242 4242 4242 4242`
   - Date : `12/34` (n'importe quelle date future)
   - CVC : `123` (n'importe quel code)
   - Nom : n'importe quoi

5. **Vérifier dans Firestore** :
   - Une sous-collection `subscriptions` devrait apparaître
   - Avec un document contenant `status: "active"`

6. **Retourner dans l'app** :
   - Le statut devrait passer à "Abonnement actif"
   - Le bouton "Accéder au Premium" devrait être débloqué

## Dépannage

### Erreur : "Firebase not initialized"
```bash
# Relancer la configuration
flutterfire configure
```

### Erreur : "No Firebase App '[DEFAULT]' has been created"
- Vérifier que `Firebase.initializeApp()` est bien dans `main()`
- Vérifier que `firebase_options.dart` existe

### L'URL de checkout ne s'ouvre pas
- Vérifier les logs Firebase Functions
- Vérifier que l'extension est bien installée
- Vérifier que la clé Stripe est valide

### Le statut d'abonnement ne se met pas à jour
- Vérifier les webhooks dans Stripe Dashboard
- Vérifier les règles Firestore (lecture autorisée)
- Attendre 10-30 secondes après le paiement

### Erreur "Permission denied" dans Firestore
- Vérifier que les règles Firestore sont publiées
- Vérifier que l'utilisateur est bien connecté
- Vérifier que l'UID correspond

## Checklist finale

Avant de considérer l'installation terminée :

- [ ] Je peux créer un compte dans l'app
- [ ] Un document utilisateur est créé dans Firestore
- [ ] Je peux cliquer sur "Débloquer Premium"
- [ ] L'URL Stripe Checkout s'ouvre
- [ ] Je peux effectuer un paiement test
- [ ] Le statut d'abonnement passe à "actif"
- [ ] Je peux accéder à l'écran Premium
- [ ] Je comprends le flux de données complet

## Questions de révision

1. Quelle est la différence entre un Product et un Price dans Stripe ?
2. Pourquoi la clé secrète Stripe n'est-elle jamais dans le code Flutter ?
3. Quel est le rôle de l'extension Firebase Stripe ?
4. Comment Flutter sait-il qu'un utilisateur est abonné ?
5. Que se passe-t-il si un paiement échoue ?

## Prochaines étapes

Maintenant que tout fonctionne :

1. Lire le code source avec attention
2. Modifier les textes et le design
3. Ajouter un deuxième plan d'abonnement
4. Tester les différents statuts (annulation, etc.)
5. Déployer sur un vrai device

Bon apprentissage !

