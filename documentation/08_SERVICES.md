# 08 - Services et logique métier

## Qu'est-ce qu'un service ?

Un service est une classe qui encapsule la logique métier de l'application. Il :
- Effectue des opérations (authentification, requêtes API, etc.)
- Transforme des données
- Communique avec des services externes (Firebase, Stripe)
- Ne contient PAS de widgets ou d'UI

## Architecture des services

```
Services (lib/services/)
├── AuthService
│   └── Authentification Firebase
└── SubscriptionService
    └── Gestion abonnements Stripe
```

## AuthService - Service d'authentification

### Fichier : `lib/services/auth_service.dart`

### Responsabilité unique

Gérer tout ce qui concerne l'authentification des utilisateurs.

### Dépendances

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
```

### Attributs privés

```dart
final FirebaseAuth _auth = FirebaseAuth.instance;
final FirebaseFirestore _firestore = FirebaseFirestore.instance;
```

Privés (`_`) car utilisés uniquement à l'intérieur de la classe.

### Propriétés publiques

#### 1. authStateChanges

```dart
Stream<User?> get authStateChanges => _auth.authStateChanges();
```

**Type :** Stream de User (nullable)

**Usage :**
```dart
authService.authStateChanges.listen((user) {
  if (user != null) {
    print('Utilisateur connecté : ${user.email}');
  } else {
    print('Utilisateur déconnecté');
  }
});
```

**Pourquoi un Stream ?**
- Émet à chaque changement d'état (connexion, déconnexion)
- Permet la réactivité en temps réel
- Utilisé dans AuthGate pour naviguer automatiquement

#### 2. currentUser

```dart
User? get currentUser => _auth.currentUser;
```

**Type :** User (nullable)

**Usage :**
```dart
final user = authService.currentUser;
if (user != null) {
  print('UID : ${user.uid}');
  print('Email : ${user.email}');
}
```

**Différence avec authStateChanges :**
- `currentUser` : valeur instantanée (snapshot)
- `authStateChanges` : flux continu de valeurs

### Méthodes publiques

#### 1. signUpWithEmail

```dart
Future<UserCredential> signUpWithEmail(String email, String password) async
```

**Paramètres :**
- `email` : Adresse email de l'utilisateur
- `password` : Mot de passe (minimum 6 caractères)

**Retour :** UserCredential contenant les infos de l'utilisateur créé

**Processus :**
```
1. Appelle Firebase Auth pour créer le compte
2. Firebase génère un UID unique
3. Crée un document Firestore pour l'utilisateur
4. Retourne le UserCredential
```

**Code détaillé :**
```dart
Future<UserCredential> signUpWithEmail(String email, String password) async {
  try {
    // Création du compte dans Firebase Auth
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Création du document utilisateur dans Firestore
    await _createUserDocument(userCredential.user!);

    return userCredential;
  } catch (e) {
    rethrow; // Relance l'exception pour que le widget puisse l'afficher
  }
}
```

**Erreurs possibles :**
```
email-already-in-use : Email déjà utilisé
invalid-email : Format d'email invalide
weak-password : Mot de passe trop faible
```

#### 2. signInWithEmail

```dart
Future<UserCredential> signInWithEmail(String email, String password) async
```

**Paramètres :**
- `email` : Adresse email
- `password` : Mot de passe

**Retour :** UserCredential de l'utilisateur connecté

**Processus :**
```
1. Appelle Firebase Auth pour vérifier les identifiants
2. Firebase vérifie le hash du mot de passe
3. Génère un token JWT
4. Retourne le UserCredential
```

**Code :**
```dart
Future<UserCredential> signInWithEmail(String email, String password) async {
  try {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  } catch (e) {
    rethrow;
  }
}
```

**Erreurs possibles :**
```
user-not-found : Utilisateur inexistant
wrong-password : Mot de passe incorrect
user-disabled : Compte désactivé
too-many-requests : Trop de tentatives
```

#### 3. signOut

```dart
Future<void> signOut() async
```

**Processus :**
```
1. Supprime le token JWT local
2. Notifie authStateChanges
3. AuthGate redirige vers LoginScreen
```

**Code :**
```dart
Future<void> signOut() async {
  await _auth.signOut();
}
```

### Méthodes privées

#### _createUserDocument

```dart
Future<void> _createUserDocument(User user) async {
  await _firestore.collection('users').doc(user.uid).set({
    'email': user.email,
    'createdAt': FieldValue.serverTimestamp(),
  });
}
```

**Pourquoi privée ?**
Utilisée uniquement par `signUpWithEmail`, pas besoin d'être publique.

**Structure créée :**
```
Collection: users
Document ID: [UID généré par Firebase]
Données:
{
  "email": "user@example.com",
  "createdAt": Timestamp(2025-11-24 10:30:00)
}
```

**FieldValue.serverTimestamp() :**
- Génère le timestamp côté serveur
- Évite les décalages d'horloge client
- Toujours précis

### Utilisation dans les widgets

```dart
// Dans un StatefulWidget
final authService = Provider.of<AuthService>(context, listen: false);

// Inscription
try {
  await authService.signUpWithEmail(email, password);
  // Succès : AuthGate navigue automatiquement
} catch (e) {
  // Erreur : afficher un message
  print('Erreur : $e');
}

// Connexion
try {
  await authService.signInWithEmail(email, password);
} catch (e) {
  print('Erreur : $e');
}

// Déconnexion
await authService.signOut();
```

## SubscriptionService - Service des abonnements

### Fichier : `lib/services/subscription_service.dart`

### Responsabilité unique

Gérer tout ce qui concerne les abonnements Stripe.

### Dépendances

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
```

### Configuration

```dart
static const String monthlyPriceId = 'price_VOTRE_PRICE_ID_ICI';
```

⚠️ **À remplacer** par votre vrai Price ID Stripe.

### Méthodes publiques

#### 1. getSubscriptionStatus

```dart
Stream<SubscriptionStatus> getSubscriptionStatus()
```

**Retour :** Stream de SubscriptionStatus (enum)

**Processus :**
```
1. Écoute la sous-collection subscriptions de l'utilisateur
2. Firebase émet à chaque changement
3. Parse les données Firestore
4. Retourne le statut (enum)
```

**Code détaillé :**
```dart
Stream<SubscriptionStatus> getSubscriptionStatus() {
  final userId = _auth.currentUser?.uid;
  
  if (userId == null) {
    return Stream.value(SubscriptionStatus.none);
  }

  // Stream sur la sous-collection subscriptions
  return _firestore
      .collection('users')
      .doc(userId)
      .collection('subscriptions')
      .snapshots()
      .map((snapshot) {
    // Si pas d'abonnements
    if (snapshot.docs.isEmpty) {
      return SubscriptionStatus.none;
    }

    // Parser le premier abonnement
    final subscriptionData = snapshot.docs.first.data();
    return _parseSubscriptionStatus(subscriptionData);
  });
}
```

**Utilisation dans un widget :**
```dart
StreamBuilder<SubscriptionStatus>(
  stream: subscriptionService.getSubscriptionStatus(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final status = snapshot.data!;
      if (status == SubscriptionStatus.active) {
        return Text('Vous êtes premium !');
      }
    }
    return Text('Pas d\'abonnement');
  },
)
```

#### 2. createCheckoutSession

```dart
Future<void> createCheckoutSession() async
```

**Processus complexe :**
```
1. Créer un document dans checkout_sessions
2. L'extension Firebase détecte le document (trigger)
3. L'extension appelle Stripe API
4. L'extension écrit l'URL dans le document
5. Flutter attend l'URL (polling via Stream)
6. Flutter ouvre l'URL dans le navigateur
```

**Code détaillé :**
```dart
Future<void> createCheckoutSession() async {
  final userId = _auth.currentUser?.uid;
  
  if (userId == null) {
    throw Exception('Utilisateur non connecté');
  }

  try {
    // Créer le document déclencheur
    final docRef = await _firestore
        .collection('users')
        .doc(userId)
        .collection('checkout_sessions')
        .add({
      'price': monthlyPriceId,              // ID du prix Stripe
      'success_url': 'https://votre-app.com/success',
      'cancel_url': 'https://votre-app.com/cancel',
      'mode': 'subscription',               // Type d'abonnement
    });

    // Attendre que l'extension ajoute l'URL
    await _waitForCheckoutUrl(docRef);
  } catch (e) {
    throw Exception('Erreur lors de la création de la session : $e');
  }
}
```

**Paramètres Firestore :**
- `price` : Le Price ID Stripe à facturer
- `success_url` : Où rediriger après succès
- `cancel_url` : Où rediriger si l'utilisateur annule
- `mode` : "subscription" (récurrent) ou "payment" (unique)

#### 3. _waitForCheckoutUrl (privée)

```dart
Future<void> _waitForCheckoutUrl(DocumentReference docRef) async
```

**Rôle :** Attendre que l'extension ajoute l'URL au document

**Stratégie :** Polling via Stream

```dart
Future<void> _waitForCheckoutUrl(DocumentReference docRef) async {
  // Écouter les changements du document
  final completer = await docRef.snapshots().firstWhere(
    (snapshot) {
      final data = snapshot.data() as Map<String, dynamic>?;
      // Attendre que 'url' ou 'error' apparaisse
      return data != null && (data.containsKey('url') || data.containsKey('error'));
    },
    orElse: () => throw TimeoutException('Timeout en attendant l\'URL de checkout'),
  );

  final data = completer.data() as Map<String, dynamic>;

  // Vérifier les erreurs
  if (data.containsKey('error')) {
    throw Exception('Erreur Stripe : ${data['error']}');
  }

  // Ouvrir l'URL
  final url = data['url'] as String;
  await _launchCheckoutUrl(url);
}
```

**Temps d'attente typique :** 2-5 secondes

#### 4. _launchCheckoutUrl (privée)

```dart
Future<void> _launchCheckoutUrl(String url) async {
  final uri = Uri.parse(url);
  
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw Exception('Impossible d\'ouvrir l\'URL de paiement');
  }
}
```

**LaunchMode.externalApplication :**
- Ouvre dans le navigateur externe (Safari, Chrome)
- Pas dans un WebView intégré
- Recommandé pour les paiements (meilleures performances)

#### 5. createPortalSession

```dart
Future<void> createPortalSession() async
```

**Rôle :** Ouvrir le portail client Stripe

Le portail permet à l'utilisateur de :
- Annuler son abonnement
- Mettre à jour sa carte bancaire
- Voir ses factures
- Télécharger ses reçus

**Code :**
```dart
Future<void> createPortalSession() async {
  final userId = _auth.currentUser?.uid;
  
  if (userId == null) {
    throw Exception('Utilisateur non connecté');
  }

  try {
    final docRef = await _firestore
        .collection('users')
        .doc(userId)
        .collection('checkout_sessions')
        .add({
      'returnUrl': 'https://votre-app.com/account',
    });

    await _waitForPortalUrl(docRef);
  } catch (e) {
    throw Exception('Erreur lors de l\'ouverture du portail : $e');
  }
}
```

### Méthodes privées de parsing

#### _parseSubscriptionStatus

```dart
SubscriptionStatus _parseSubscriptionStatus(Map<String, dynamic> data) {
  final status = data['status'] as String?;
  
  switch (status) {
    case 'active':
    case 'trialing':
      return SubscriptionStatus.active;
    case 'past_due':
      return SubscriptionStatus.pastDue;
    case 'canceled':
      return SubscriptionStatus.canceled;
    default:
      return SubscriptionStatus.none;
  }
}
```

**Mapping Stripe → App :**
```
Stripe               Application
active        →      active
trialing      →      active  (période d'essai = accès)
past_due      →      pastDue
canceled      →      canceled
incomplete    →      none
unpaid        →      none
```

## Gestion des erreurs

### Stratégie

Les services **relancent** les exceptions (`rethrow`) au lieu de les gérer.

**Pourquoi ?**
- La gestion d'erreur (affichage) est responsabilité de l'UI
- Les services restent réutilisables
- Les widgets décident comment afficher l'erreur

### Pattern utilisé dans les widgets

```dart
try {
  await subscriptionService.createCheckoutSession();
  // Succès
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Redirection...')),
  );
} catch (e) {
  // Erreur
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Erreur : ${e.toString()}'),
      backgroundColor: Colors.red,
    ),
  );
}
```

## Tests unitaires (exemple)

```dart
// test/services/auth_service_test.dart
void main() {
  test('signUpWithEmail crée un utilisateur', () async {
    final authService = AuthService();
    
    final userCredential = await authService.signUpWithEmail(
      'test@example.com',
      'password123',
    );
    
    expect(userCredential.user, isNotNull);
    expect(userCredential.user!.email, 'test@example.com');
  });
}
```

## Bonnes pratiques appliquées

### 1. Single Responsibility Principle
Chaque service a une responsabilité unique.

### 2. Dependency Injection
Les services sont injectés via Provider, pas instanciés directement.

### 3. Séparation UI/Logique
Aucun widget dans les services.

### 4. Gestion explicite des erreurs
Toutes les exceptions sont propagées clairement.

### 5. Immutabilité des paramètres
Les paramètres des méthodes sont immuables.

## Prochaine étape

Maintenant que vous comprenez les services, explorez l'interface utilisateur : [Interface utilisateur](09_INTERFACE.md)

