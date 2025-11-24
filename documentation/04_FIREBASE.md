# 04 - Guide Firebase

## Introduction à Firebase

Firebase est une plateforme Backend-as-a-Service (BaaS) développée par Google qui fournit des services backend prêts à l'emploi pour les applications mobiles et web.

## Services Firebase utilisés dans l'application

### 1. Firebase Authentication
Gère l'authentification des utilisateurs

### 2. Cloud Firestore
Base de données NoSQL en temps réel

### 3. Cloud Functions
Code exécuté côté serveur

### 4. Extensions
Plugins qui ajoutent des fonctionnalités

## Étape 1 : Créer un projet Firebase

### 1.1 Accéder à la console

1. Aller sur https://console.firebase.google.com
2. Se connecter avec un compte Google
3. Cliquer sur "Ajouter un projet"

### 1.2 Configurer le projet

**Étape 1 : Nom du projet**
```
Nom : flutter-stripe-learning
(ou votre choix)
```

**Étape 2 : Google Analytics**
```
Option 1 : Désactiver (recommandé pour ce projet d'apprentissage)
Option 2 : Activer (si vous voulez des statistiques)
```

**Étape 3 : Création**
- Cliquer sur "Créer un projet"
- Attendre 1-2 minutes

### 1.3 Accéder au projet

Une fois créé, vous arrivez sur le tableau de bord du projet.

## Étape 2 : Activer Firebase Authentication

### 2.1 Accéder à Authentication

1. Dans le menu de gauche, cliquer sur "Authentication"
2. Cliquer sur "Commencer"
3. Vous arrivez sur l'écran de configuration

### 2.2 Activer Email/Password

1. Onglet "Sign-in method"
2. Cliquer sur "Email/Password"
3. Activer le premier toggle "Email/Password"
4. Laisser le deuxième toggle "Email link" désactivé
5. Cliquer sur "Enregistrer"

### 2.3 Vérification

Vous devriez voir dans la liste des méthodes :
```
Email/Password : Activé
```

## Étape 3 : Créer la base de données Firestore

### 3.1 Accéder à Firestore

1. Dans le menu de gauche, cliquer sur "Firestore Database"
2. Cliquer sur "Créer une base de données"

### 3.2 Choisir le mode de sécurité

Deux options :

**Mode production (recommandé pour production)**
```
Accès refusé par défaut
Vous devez écrire des règles de sécurité
```

**Mode test (recommandé pour développement)**
```
Accès ouvert pendant 30 jours
Parfait pour l'apprentissage
⚠️ Penser à sécuriser avant le déploiement
```

Pour ce projet d'apprentissage : **Choisir "Démarrer en mode test"**

### 3.3 Choisir l'emplacement

Sélectionner un emplacement géographique proche de vos utilisateurs :

```
Europe :
- europe-west1 (Belgique)
- europe-west3 (Allemagne)
- europe-west6 (Suisse)

Amérique du Nord :
- us-central1 (Iowa)
- us-east1 (Caroline du Sud)

Autres :
- asia-northeast1 (Tokyo)
- australia-southeast1 (Sydney)
```

⚠️ **Important** : Une fois choisi, l'emplacement ne peut plus être changé.

### 3.4 Création

1. Cliquer sur "Activer"
2. Attendre 30 secondes

Vous devriez voir l'interface Firestore avec un message "Aucune collection".

## Étape 4 : Configurer les règles de sécurité Firestore

### 4.1 Accéder aux règles

1. Dans Firestore, cliquer sur l'onglet "Règles"
2. Vous voyez l'éditeur de règles

### 4.2 Règles pour le développement

Remplacer le contenu par :

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Collection des utilisateurs
    match /users/{userId} {
      // L'utilisateur peut lire et écrire son propre document
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Sous-collection des sessions de checkout
      match /checkout_sessions/{sessionId} {
        // L'utilisateur peut créer et lire ses propres sessions
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      // Sous-collection des abonnements
      match /subscriptions/{subscriptionId} {
        // Lecture seule pour l'utilisateur (écriture par l'extension)
        allow read: if request.auth != null && request.auth.uid == userId;
        // Écriture réservée aux Cloud Functions
        allow write: if false;
      }
      
      // Sous-collection des paiements
      match /payments/{paymentId} {
        // Lecture seule pour l'utilisateur
        allow read: if request.auth != null && request.auth.uid == userId;
        allow write: if false;
      }
    }
    
    // Collection des produits (lecture publique)
    match /products/{productId} {
      allow read: if true;
      
      // Sous-collection des prix
      match /prices/{priceId} {
        allow read: if true;
      }
    }
    
    // Collection des clients (gérée par l'extension)
    match /customers/{customerId} {
      allow read: if request.auth != null;
      allow write: if false;
    }
  }
}
```

### 4.3 Explication des règles

**Règle users**
```javascript
allow read, write: if request.auth != null && request.auth.uid == userId;
```
- `request.auth != null` : l'utilisateur doit être connecté
- `request.auth.uid == userId` : l'UID doit correspondre à l'ID du document

**Règle subscriptions**
```javascript
allow read: if request.auth != null && request.auth.uid == userId;
allow write: if false;
```
- Lecture : autorisée pour l'utilisateur propriétaire
- Écriture : interdite (seules les Cloud Functions peuvent écrire)

**Règle products**
```javascript
allow read: if true;
```
- Lecture publique (les produits sont visibles par tous)

### 4.4 Publier les règles

1. Cliquer sur "Publier"
2. Attendre quelques secondes

Les règles sont maintenant actives.

## Étape 5 : Connecter Flutter à Firebase

### 5.1 Installer FlutterFire CLI

Le FlutterFire CLI facilite la configuration de Firebase dans Flutter.

```bash
# Installer globalement
dart pub global activate flutterfire_cli

# Vérifier l'installation
flutterfire --version
```

**Problème PATH ?**

Si la commande n'est pas trouvée, ajouter au PATH :

**Windows**
```
Ajouter : %USERPROFILE%\AppData\Local\Pub\Cache\bin
```

**Mac/Linux**
```bash
export PATH="$PATH":"$HOME/.pub-cache/bin"
# Ajouter cette ligne à ~/.bashrc ou ~/.zshrc
```

### 5.2 Configurer Firebase dans le projet Flutter

Dans le dossier du projet Flutter :

```bash
flutterfire configure
```

Cette commande va :

1. **Lister vos projets Firebase**
   ```
   ? Select a Firebase project to configure your Flutter application with:
   > flutter-stripe-learning (flutter-stripe-learning-xxxxx)
   ```
   Sélectionner votre projet

2. **Choisir les plateformes**
   ```
   ? Which platforms should your configuration support?
   [x] android
   [x] ios
   [x] web
   [ ] macos
   [ ] windows
   ```
   Cocher les plateformes souhaitées (Android, iOS, Web minimum)

3. **Générer la configuration**
   ```
   i Firebase android app com.example.flutter_stripe_subscriptions_learning registered.
   i Firebase ios app com.example.flutterStripeSubscriptionsLearning registered.
   i Firebase web app registered.
   
   Firebase configuration file lib/firebase_options.dart generated successfully.
   ```

### 5.3 Vérifier le fichier généré

Un fichier `lib/firebase_options.dart` a été créé avec un contenu similaire à :

```dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Platform not supported');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
    appId: '1:123456789:web:xxxxxxxxxxxxx',
    messagingSenderId: '123456789',
    projectId: 'flutter-stripe-learning',
    authDomain: 'flutter-stripe-learning.firebaseapp.com',
    storageBucket: 'flutter-stripe-learning.appspot.com',
  );

  // ... configurations Android et iOS
}
```

⚠️ **Ce fichier ne doit PAS être commité dans Git** (il est dans `.gitignore`)

### 5.4 Initialiser Firebase dans main.dart

Le fichier `main.dart` contient déjà :

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialisation de Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}
```

## Étape 6 : Tester la connexion

### 6.1 Lancer l'application

```bash
flutter run
```

### 6.2 Créer un compte de test

1. Sur l'écran de login, cliquer sur "S'inscrire"
2. Saisir :
   ```
   Email : test@example.com
   Mot de passe : password123
   ```
3. Cliquer sur "S'inscrire"

### 6.3 Vérifier dans Firebase Console

**Authentication :**
1. Aller dans Firebase Console > Authentication
2. Onglet "Users"
3. Vous devriez voir :
   ```
   test@example.com
   UID : kSd8f9JKldfjKL3j9sdkfj2Lksdf
   Created : il y a quelques secondes
   ```

**Firestore :**
1. Aller dans Firebase Console > Firestore Database
2. Vous devriez voir :
   ```
   Collection : users
   └─ Document : kSd8f9JKldfjKL3j9sdkfj2Lksdf
       ├─ email : "test@example.com"
       └─ createdAt : 24 novembre 2025 à 10:30:00
   ```

Si vous voyez ces données, **la connexion fonctionne !**

## Étape 7 : Comprendre la structure Firestore

### 7.1 Collections et documents

**Collection `users`**
```
users/
├─ {userId1}/
│   ├─ email: "user1@example.com"
│   ├─ createdAt: timestamp
│   └─ (sous-collections)
│
├─ {userId2}/
│   ├─ email: "user2@example.com"
│   ├─ createdAt: timestamp
│   └─ (sous-collections)
```

### 7.2 Sous-collections

Chaque document utilisateur aura des sous-collections :

**checkout_sessions**
```
users/{userId}/checkout_sessions/
└─ {sessionId}/
    ├─ price: "price_xxxxx"
    ├─ mode: "subscription"
    ├─ url: "https://checkout.stripe.com/..."
    └─ created: timestamp
```

**subscriptions**
```
users/{userId}/subscriptions/
└─ {subscriptionId}/
    ├─ status: "active"
    ├─ current_period_end: timestamp
    ├─ items: [...]
    └─ created: timestamp
```

## Étape 8 : Configuration avancée (optionnel)

### 8.1 Indexes Firestore

Pour des requêtes complexes, vous pourriez avoir besoin d'indexes.

**Créer un index :**
1. Firestore > Onglet "Indexes"
2. Cliquer sur "Créer un index"
3. Configurer :
   ```
   Collection : subscriptions
   Champs :
   - status : Ascending
   - created : Descending
   ```

Pour ce projet simple, **aucun index n'est nécessaire**.

### 8.2 Quotas et limites

**Plan gratuit (Spark) :**
```
Firestore :
- 50 000 lectures/jour
- 20 000 écritures/jour
- 20 000 suppressions/jour
- 1 GB stockage

Auth :
- Utilisateurs illimités
- 10 000 vérifications/mois

Functions :
- 2 000 000 invocations/mois
- 400 000 GB-sec/mois
- 200 000 CPU-sec/mois
```

Pour dépasser ces limites, passer au plan **Blaze** (pay-as-you-go).

### 8.3 Monitoring

**Voir l'utilisation :**
1. Firebase Console > Usage
2. Graphiques de :
   - Lectures/écritures Firestore
   - Utilisateurs actifs
   - Invocations Functions

## Checklist de validation

Avant de passer à Stripe, vérifier :

- [ ] Projet Firebase créé
- [ ] Firebase Authentication activé (Email/Password)
- [ ] Firestore Database créé
- [ ] Règles de sécurité configurées et publiées
- [ ] FlutterFire CLI installé
- [ ] `firebase_options.dart` généré
- [ ] Application Flutter lance sans erreur
- [ ] Compte de test créé
- [ ] Utilisateur visible dans Authentication
- [ ] Document visible dans Firestore

## Questions de révision

1. Quelle est la différence entre une collection et un document dans Firestore ?
2. Pourquoi les règles Firestore sont-elles importantes ?
3. Que fait la commande `flutterfire configure` ?
4. Où est stockée la clé API Firebase dans le projet Flutter ?
5. Pourquoi l'écriture dans la collection `subscriptions` est interdite côté client ?

## Erreurs courantes

### Erreur : "Firebase not initialized"

**Solution :**
Vérifier que `Firebase.initializeApp()` est appelé avant `runApp()` dans `main.dart`.

### Erreur : "Permission denied"

**Solution :**
Vérifier que les règles Firestore sont publiées et correctes.

### Erreur : "flutterfire command not found"

**Solution :**
Installer FlutterFire CLI et ajouter au PATH.

## Prochaine étape

Firebase est configuré ! Passez maintenant à la configuration de Stripe : [Guide Stripe](05_STRIPE.md)

