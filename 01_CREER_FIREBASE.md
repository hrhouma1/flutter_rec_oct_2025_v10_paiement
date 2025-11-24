# 01 - Créer et configurer Firebase

## Durée : 10 minutes

## 1. Créer un projet Firebase

1. Va sur https://console.firebase.google.com
2. Clique sur **"Ajouter un projet"**
3. Nom du projet : `mon-app-stripe` (ou ce que tu veux)
4. Désactive **Google Analytics** (pas besoin pour ce projet)
5. Clique sur **"Créer un projet"**
6. Attends 1 minute
7. Clique sur **"Continuer"**

## 2. Activer Authentication

1. Dans le menu de gauche, clique sur **"Authentication"**
2. Clique sur **"Commencer"**
3. Clique sur **"Email/Password"**
4. Active le premier toggle (Email/Password)
5. Clique sur **"Enregistrer"**

## 3. Créer Firestore Database

1. Dans le menu de gauche, clique sur **"Firestore Database"**
2. Clique sur **"Créer une base de données"**
3. Sélectionne **"Démarrer en mode test"**
4. Choisis un emplacement : **europe-west1 (Belgique)** ou **europe-west3 (Allemagne)**
5. Clique sur **"Activer"**
6. Attends 30 secondes

## 4. Configurer les règles Firestore

1. Clique sur l'onglet **"Règles"**
2. Supprime tout et colle ce code :

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

3. Clique sur **"Publier"**

## 5. Connecter Firebase à Flutter

Dans ton terminal PowerShell, dans le dossier du projet :

```bash
# Installer FlutterFire CLI
dart pub global activate flutterfire_cli

# Configurer Firebase
flutterfire configure
```

Suis les instructions :
- Se connecter avec ton compte Google
- Sélectionner ton projet Firebase
- Sélectionner les plateformes (Android, iOS, Web)

## Vérification

- Fichier `lib/firebase_options.dart` est maintenant généré avec de vraies valeurs
- Tu ne vois plus "TON_API_KEY" mais de vraies clés comme "AIzaSy..."

## Prochaine étape

**[02_CREER_STRIPE.md](02_CREER_STRIPE.md)** - Créer ton compte Stripe

