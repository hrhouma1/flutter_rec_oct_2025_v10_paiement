# 17 - Sécurité et bonnes pratiques

## Principes fondamentaux

### 1. Ne jamais faire confiance au client

**Règle d'or :** Toute donnée venant du client peut être manipulée.

**Mauvais exemple :**
```dart
// ❌ DANGEREUX : Créer l'abonnement côté client
await FirebaseFirestore.instance
  .collection('users/$userId/subscriptions')
  .add({
    'status': 'active',  // ← N'importe qui pourrait écrire ça !
    'plan': 'premium',
  });
```

**Bon exemple :**
```dart
// ✅ SÉCURISÉ : Seule l'extension (serveur) crée l'abonnement
// après vérification du paiement Stripe
```

### 2. Validation côté serveur obligatoire

**Règle :** Toujours vérifier les permissions côté serveur.

**Implémentation avec règles Firestore :**
```javascript
// ❌ DANGEREUX
allow write: if true;

// ✅ SÉCURISÉ
allow write: if request.auth != null 
  && request.auth.uid == userId
  && validSubscriptionExists(request.auth.uid);
```

### 3. Principe du moindre privilège

**Règle :** Chaque partie du système n'a accès qu'au minimum nécessaire.

**Application :**
- Flutter : lecture seule des abonnements
- Cloud Functions : lecture/écriture complète
- Utilisateur : lecture/écriture uniquement de ses propres données

## Règles Firestore production-ready

### Collection users

```javascript
match /users/{userId} {
  // L'utilisateur peut lire et écrire son propre document
  allow read: if request.auth != null && request.auth.uid == userId;
  allow write: if request.auth != null && request.auth.uid == userId
    && !request.resource.data.diff(resource.data).affectedKeys().hasAny(['stripeId']);
  // ↑ Empêche la modification du stripeId (réservé à l'extension)
  
  match /checkout_sessions/{sessionId} {
    // L'utilisateur peut créer des sessions
    allow create: if request.auth != null && request.auth.uid == userId;
    // L'utilisateur peut lire ses sessions
    allow read: if request.auth != null && request.auth.uid == userId;
    // Seule l'extension peut mettre à jour (ajouter l'URL)
    allow update, delete: if false;
  }
  
  match /subscriptions/{subscriptionId} {
    // Lecture seule pour l'utilisateur
    allow read: if request.auth != null && request.auth.uid == userId;
    // Écriture réservée aux Cloud Functions
    allow write: if false;
  }
  
  match /payments/{paymentId} {
    // Lecture seule
    allow read: if request.auth != null && request.auth.uid == userId;
    allow write: if false;
  }
}
```

### Collection products

```javascript
match /products/{productId} {
  // Lecture publique des produits actifs
  allow read: if resource.data.active == true;
  // Écriture admin uniquement
  allow write: if false;
  
  match /prices/{priceId} {
    // Lecture publique des prix actifs
    allow read: if resource.data.active == true;
    allow write: if false;
  }
}
```

### Fonction utilitaire pour vérifier l'abonnement

```javascript
function hasActiveSubscription(userId) {
  return exists(/databases/$(database)/documents/users/$(userId)/subscriptions/$(subscription))
    && get(/databases/$(database)/documents/users/$(userId)/subscriptions/$(subscription)).data.status == 'active';
}

// Utilisation
match /premium_content/{docId} {
  allow read: if request.auth != null && hasActiveSubscription(request.auth.uid);
}
```

## Sécurité des clés API

### Clés publiques (OK dans le code)

```dart
// ✅ Ces clés PEUVENT être dans le code
const firebaseApiKey = 'AIzaSy...';  // Firebase Web API Key
const stripePublishableKey = 'pk_test_...';  // Stripe Publishable Key
```

**Pourquoi c'est sûr ?**
- Ces clés sont limitées en permissions
- Protégées par les règles Firestore côté serveur
- Conçues pour être publiques

### Clés secrètes (JAMAIS dans le code)

```dart
// ❌ DANGEREUX - JAMAIS faire ça
const stripeSecretKey = 'sk_test_...';  // ← DANGER
```

**Conséquences si exposée :**
- Accès complet à votre compte Stripe
- Création d'abonnements gratuits
- Remboursements frauduleux
- Vol de données clients

**Où stocker les clés secrètes ?**
- Firebase Secret Manager (utilisé par l'extension)
- Variables d'environnement serveur
- Jamais dans Git, jamais dans le code client

## Validation des données

### Côté client (UX)

```dart
// Validation pour améliorer l'UX, mais pas pour la sécurité
validator: (value) {
  if (value == null || !value.contains('@')) {
    return 'Email invalide';
  }
  return null;
}
```

### Côté serveur (sécurité)

```javascript
// Règles Firestore : validation stricte
match /users/{userId} {
  allow create: if request.resource.data.keys().hasAll(['email', 'createdAt'])
    && request.resource.data.email is string
    && request.resource.data.email.matches('[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}');
}
```

## Prévenir les abus

### Rate limiting

Les Cloud Functions ont un rate limiting automatique, mais vous pouvez ajouter :

```dart
// Limiter les tentatives de paiement
class RateLimiter {
  final Map<String, DateTime> _lastAttempts = {};
  final Duration _cooldown = const Duration(seconds: 30);
  
  bool canAttempt(String userId) {
    final lastAttempt = _lastAttempts[userId];
    
    if (lastAttempt == null) {
      _lastAttempts[userId] = DateTime.now();
      return true;
    }
    
    final elapsed = DateTime.now().difference(lastAttempt);
    if (elapsed > _cooldown) {
      _lastAttempts[userId] = DateTime.now();
      return true;
    }
    
    return false;
  }
}
```

### Limiter les sessions Checkout

```javascript
// Cloud Function
exports.createCheckoutSession = functions.firestore
  .document('users/{uid}/checkout_sessions/{sessionId}')
  .onCreate(async (snap, context) => {
    // Vérifier le nombre de sessions créées récemment
    const recentSessions = await admin.firestore()
      .collection(`users/${context.params.uid}/checkout_sessions`)
      .where('created', '>', Date.now() - 3600000) // 1 heure
      .get();
    
    if (recentSessions.size > 5) {
      throw new Error('Too many checkout sessions');
    }
    
    // Créer la session Stripe...
  });
```

## Protection contre les attaques

### 1. Injection NoSQL

Firestore est naturellement protégé, mais attention aux requêtes dynamiques :

```dart
// ❌ Potentiellement dangereux
final query = userInput;
FirebaseFirestore.instance.collection('users').where('email', isEqualTo: query);

// ✅ Valider les entrées
final email = sanitizeEmail(userInput);
if (!isValidEmail(email)) {
  throw Exception('Email invalide');
}
FirebaseFirestore.instance.collection('users').where('email', isEqualTo: email);
```

### 2. XSS (Cross-Site Scripting)

Flutter est naturellement protégé, mais attention aux WebViews :

```dart
// Si vous utilisez WebView pour afficher du contenu
WebView(
  javascriptMode: JavascriptMode.disabled,  // ← Désactiver JS si pas nécessaire
  initialUrl: sanitizeUrl(userProvidedUrl),
)
```

### 3. CSRF (Cross-Site Request Forgery)

Firebase Auth gère automatiquement les tokens CSRF.

Vérifier toujours `request.auth` dans les règles Firestore.

## Conformité RGPD

### Données personnelles collectées

```
- Email (nécessaire pour l'authentification)
- UID Firebase (identifiant technique)
- Stripe Customer ID (nécessaire pour la facturation)
- Historique des paiements (obligation légale)
```

### Droits des utilisateurs

**Droit d'accès :**
```dart
// Permettre à l'utilisateur de télécharger ses données
Future<Map<String, dynamic>> exportUserData(String userId) async {
  final userData = await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .get();
  
  final subscriptions = await FirebaseFirestore.instance
    .collection('users/$userId/subscriptions')
    .get();
  
  final payments = await FirebaseFirestore.instance
    .collection('users/$userId/payments')
    .get();
  
  return {
    'user': userData.data(),
    'subscriptions': subscriptions.docs.map((d) => d.data()).toList(),
    'payments': payments.docs.map((d) => d.data()).toList(),
  };
}
```

**Droit à l'oubli :**
```dart
// Supprimer toutes les données utilisateur
Future<void> deleteUserData(String userId) async {
  // 1. Annuler l'abonnement Stripe (via extension)
  // 2. Supprimer les sous-collections Firestore
  // 3. Supprimer le compte Firebase Auth
  
  await FirebaseAuth.instance.currentUser?.delete();
}
```

### Politique de confidentialité

Vous DEVEZ avoir une politique de confidentialité mentionnant :
- Données collectées
- Utilisation des données
- Partage avec Stripe
- Droits des utilisateurs
- Contact

## Audit de sécurité

### Checklist avant production

**Authentification**
- [ ] Règles Firestore restrictives
- [ ] Pas de clé secrète dans le code
- [ ] Firebase Auth activé
- [ ] Email verification (optionnel)

**Paiements**
- [ ] Clé Stripe en mode live
- [ ] Webhooks sécurisés (signature vérifiée)
- [ ] Extension correctement configurée

**Données**
- [ ] Règles Firestore en production
- [ ] Pas d'écriture directe dans subscriptions
- [ ] Validation des entrées

**RGPD**
- [ ] Politique de confidentialité
- [ ] Consentement cookies (si applicable)
- [ ] Droit d'accès implémenté
- [ ] Droit à l'oubli implémenté

**Monitoring**
- [ ] Logs activés
- [ ] Alertes erreurs
- [ ] Monitoring Stripe
- [ ] Monitoring Firebase

## Tests de sécurité

### Test 1 : Tentative d'accès non autorisé

```dart
// Tenter de lire l'abonnement d'un autre utilisateur
test('Cannot read other user subscription', () async {
  final otherUserId = 'autre_user_id';
  
  expect(
    () => FirebaseFirestore.instance
      .collection('users/$otherUserId/subscriptions')
      .get(),
    throwsA(isA<FirebaseException>()),
  );
});
```

### Test 2 : Modification du statut d'abonnement

```dart
// Tenter de modifier le statut d'abonnement
test('Cannot modify subscription status', () async {
  final userId = FirebaseAuth.instance.currentUser!.uid;
  
  expect(
    () => FirebaseFirestore.instance
      .collection('users/$userId/subscriptions')
      .doc('sub_id')
      .update({'status': 'active'}),
    throwsA(isA<FirebaseException>()),
  );
});
```

## Prochaine étape

Optimiser l'application : [Optimisations](18_OPTIMISATIONS.md)

