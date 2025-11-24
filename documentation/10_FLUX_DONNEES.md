# 10 - Flux de données complet

## Vue d'ensemble

Ce module détaille étape par étape comment les données circulent dans l'application, depuis l'action de l'utilisateur jusqu'à la mise à jour de l'interface.

## Flux 1 : Inscription d'un utilisateur

### Diagramme de séquence

```
Utilisateur   LoginScreen   AuthService   Firebase Auth   Firestore
    |              |              |              |            |
    |--Clic--->    |              |              |            |
    |   "S'inscrire"              |              |            |
    |              |              |              |            |
    |              |--signUpWithEmail()--------> |            |
    |              |              |              |            |
    |              |              |--createUserWithEmailAndPassword()
    |              |              |              |            |
    |              |              | <---User-----|            |
    |              |              |    (UID)     |            |
    |              |              |              |            |
    |              |--_createUserDocument()------|----------> |
    |              |              |              |   users/   |
    |              |              |              |   {uid}    |
    |              | <-Success----|              |            |
    | <-Navigate---|              |              |            |
    |  HomeScreen  |              |              |            |
```

### Étapes détaillées

#### Étape 1 : Saisie utilisateur
```dart
// login_screen.dart ligne 34-40
_emailController.text = "user@example.com"
_passwordController.text = "password123"
// Utilisateur clique sur "S'inscrire"
```

**Données** :
```
email: "user@example.com"
password: "password123"
```

#### Étape 2 : Validation du formulaire
```dart
// login_screen.dart ligne 27
if (!_formKey.currentState!.validate()) {
  return; // Affiche les erreurs de validation
}
```

**Validations** :
- Email contient un `@`
- Mot de passe a au moins 6 caractères

#### Étape 3 : Appel du service d'authentification
```dart
// login_screen.dart ligne 34
final authService = Provider.of<AuthService>(context, listen: false);
await authService.signUpWithEmail(
  _emailController.text.trim(),
  _passwordController.text,
);
```

#### Étape 4 : Création du compte Firebase Auth
```dart
// auth_service.dart ligne 28-32
UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
  email: email,
  password: password,
);
```

**Ce que fait Firebase Auth** :
1. Vérifie que l'email n'existe pas déjà
2. Hash le mot de passe avec bcrypt
3. Crée le compte
4. Génère un UID unique
5. Retourne un UserCredential

**Réponse** :
```dart
UserCredential {
  user: User {
    uid: "kSd8f9JKldfjKL3j9sdkfj2Lksdf",
    email: "user@example.com",
    emailVerified: false,
  }
}
```

#### Étape 5 : Création du document Firestore
```dart
// auth_service.dart ligne 35
await _createUserDocument(userCredential.user!);

// Ligne 54-58
await _firestore.collection('users').doc(user.uid).set({
  'email': user.email,
  'createdAt': FieldValue.serverTimestamp(),
});
```

**Document créé dans Firestore** :
```
Collection: users
Document ID: kSd8f9JKldfjKL3j9sdkfj2Lksdf
Données:
{
  "email": "user@example.com",
  "createdAt": Timestamp(2025-11-24 10:30:00)
}
```

#### Étape 6 : Retour au widget
```dart
// login_screen.dart ligne 34
// La méthode signUpWithEmail() retourne
// Le StreamBuilder dans AuthGate détecte le changement
```

#### Étape 7 : Navigation automatique
```dart
// auth_gate.dart ligne 19-22
StreamBuilder<User?>(
  stream: authService.authStateChanges,
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return const HomeScreen(); // ← Navigation ici
    }
    return const LoginScreen();
  },
)
```

### Données à chaque niveau

| Niveau | Données présentes |
|--------|-------------------|
| UI (LoginScreen) | Email, mot de passe en clair |
| AuthService | Email, mot de passe en clair (temporaire) |
| Firebase Auth | Email, hash du mot de passe, UID généré |
| Firestore | Email, UID, timestamp |
| UI (HomeScreen) | User avec UID et email |

### Temps d'exécution typique

- Validation : instantané
- Création Firebase Auth : 200-500 ms
- Création Firestore : 100-300 ms
- Navigation : instantané
- **Total : 300-800 ms**

## Flux 2 : Création d'un abonnement (le plus complexe)

### Diagramme de séquence complet

```
User  Paywall  SubscriptionService  Firestore  Extension  Stripe  Browser
 |       |              |              |          |         |        |
 |--Clic "S'abonner"--> |              |          |         |        |
 |       |              |              |          |         |        |
 |       |--createCheckoutSession()-->|          |         |        |
 |       |              |              |          |         |        |
 |       |              |--add document           |         |        |
 |       |              |  checkout_sessions     |         |        |
 |       |              |              |          |         |        |
 |       |              | <--Doc ID----|          |         |        |
 |       |              |              |          |         |        |
 |       |              |              |--Trigger |         |        |
 |       |              |              |  onCreate|         |        |
 |       |              |              |          |         |        |
 |       |              |              |          |--createSession-->|
 |       |              |              |          |    (API) |        |
 |       |              |              |          | <-URL----|        |
 |       |              |              | <-Update |          |        |
 |       |              |              |   +url   |          |        |
 |       |              |              |          |          |        |
 |       |--Listen document changes--> |          |          |        |
 |       |              |              |          |          |        |
 |       |              | <--url-------|          |          |        |
 |       |              |              |          |          |        |
 |       |              |--launchUrl()------------------------->      |
 |       |              |              |          |          |        |
 | <--Redirect to Stripe Checkout page--------------------------->   |
 |       |              |              |          |          |        |
 |--Pay on Stripe---------------------------------------------->     |
 |       |              |              |          |          |        |
 |       |              |              |          |          | <-Payment
 |       |              |              |          |          |  confirm|
 |       |              |              |          | <-Webhook|        |
 |       |              |              |          |          |        |
 |       |              |              | <-Write  |          |        |
 |       |              |              | subscription        |        |
 |       |              |              |          |          |        |
 | <--Redirect back to app----------------------------------->        |
 |       |              |              |          |          |        |
 |--HomeScreen opened-> |              |          |          |        |
 |       |              |              |          |          |        |
 |       |--getSubscriptionStatus()-->|          |          |        |
 |       |              |              |          |          |        |
 |       |              | <-Stream active subscription      |        |
 |       |              |              |          |          |        |
 | <-UI updates "Active"|              |          |          |        |
```

### Partie A : Création de la session Checkout

#### Étape A1 : Clic utilisateur
```dart
// paywall_screen.dart ligne 23
Future<void> _handleSubscribe() async {
  setState(() => _isLoading = true);
  
  final subscriptionService = Provider.of<SubscriptionService>(context, listen: false);
  await subscriptionService.createCheckoutSession();
}
```

#### Étape A2 : Ajout du document dans Firestore
```dart
// subscription_service.dart ligne 70-79
final docRef = await _firestore
  .collection('users')
  .doc(userId) // "kSd8f9JKldfjKL3j9sdkfj2Lksdf"
  .collection('checkout_sessions')
  .add({
    'price': monthlyPriceId, // "price_xxxxxxxxxxxxx"
    'success_url': 'https://votre-app.com/success',
    'cancel_url': 'https://votre-app.com/cancel',
    'mode': 'subscription',
  });
```

**Document créé** :
```
Collection: users/kSd8f9JK.../checkout_sessions
Document ID: session_auto_generated_id
Données initiales:
{
  "price": "price_1234567890abcdef",
  "success_url": "https://votre-app.com/success",
  "cancel_url": "https://votre-app.com/cancel",
  "mode": "subscription",
  "created": Timestamp(2025-11-24 10:35:00)
}
```

#### Étape A3 : L'extension Firebase détecte le document
```javascript
// Cloud Function générée par l'extension
exports.createCheckoutSession = functions.firestore
  .document('users/{uid}/checkout_sessions/{sessionId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const priceId = data.price;
    
    // Appeler l'API Stripe
    const session = await stripe.checkout.sessions.create({
      customer: stripeCustomerId,
      line_items: [{
        price: priceId,
        quantity: 1,
      }],
      mode: 'subscription',
      success_url: data.success_url,
      cancel_url: data.cancel_url,
    });
    
    // Écrire l'URL dans Firestore
    await snap.ref.update({
      url: session.url,
      sessionId: session.id,
    });
  });
```

#### Étape A4 : Création de la session Stripe

**Requête à Stripe API** :
```http
POST https://api.stripe.com/v1/checkout/sessions
Authorization: Bearer sk_test_xxxxxxxxxxxxx
Content-Type: application/x-www-form-urlencoded

customer=cus_xxxxxxxxxxxxx
&line_items[0][price]=price_xxxxxxxxxxxxx
&line_items[0][quantity]=1
&mode=subscription
&success_url=https://votre-app.com/success
&cancel_url=https://votre-app.com/cancel
```

**Réponse de Stripe** :
```json
{
  "id": "cs_test_xxxxxxxxxxxxx",
  "object": "checkout.session",
  "url": "https://checkout.stripe.com/c/pay/cs_test_xxxxxxxxxxxxx",
  "customer": "cus_xxxxxxxxxxxxx",
  "mode": "subscription",
  "status": "open",
  ...
}
```

#### Étape A5 : Mise à jour du document Firestore
```
Collection: users/kSd8f9JK.../checkout_sessions
Document ID: session_auto_generated_id
Données mises à jour:
{
  "price": "price_1234567890abcdef",
  "success_url": "https://votre-app.com/success",
  "cancel_url": "https://votre-app.com/cancel",
  "mode": "subscription",
  "created": Timestamp(2025-11-24 10:35:00),
  "url": "https://checkout.stripe.com/c/pay/cs_test_xxxxxxxxxxxxx",  ← AJOUTÉ
  "sessionId": "cs_test_xxxxxxxxxxxxx"  ← AJOUTÉ
}
```

#### Étape A6 : Flutter détecte l'URL
```dart
// subscription_service.dart ligne 92-104
Future<void> _waitForCheckoutUrl(DocumentReference docRef) async {
  final completer = await docRef.snapshots().firstWhere(
    (snapshot) {
      final data = snapshot.data() as Map<String, dynamic>?;
      return data != null && data.containsKey('url');
    },
  );

  final data = completer.data() as Map<String, dynamic>;
  final url = data['url'] as String;
  await _launchCheckoutUrl(url);
}
```

**Temps d'attente typique** : 2-5 secondes

#### Étape A7 : Ouverture de l'URL dans le navigateur
```dart
// subscription_service.dart ligne 113-119
Future<void> _launchCheckoutUrl(String url) async {
  final uri = Uri.parse(url);
  
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
```

**URL ouverte** :
```
https://checkout.stripe.com/c/pay/cs_test_xxxxxxxxxxxxx
```

### Partie B : Paiement sur Stripe

#### Étape B1 : Page Stripe Checkout
L'utilisateur voit une page hébergée par Stripe avec :
- Résumé du produit
- Formulaire de carte bancaire
- Informations de facturation

#### Étape B2 : Saisie des données de paiement
```
Numéro de carte : 4242 4242 4242 4242
Date d'expiration : 12/34
CVC : 123
Nom : Test User
```

#### Étape B3 : Validation du paiement
1. Stripe vérifie la carte
2. Stripe charge le montant
3. Stripe crée l'abonnement
4. Stripe redirige vers `success_url`

### Partie C : Synchronisation après paiement

#### Étape C1 : Stripe envoie un webhook

**Événement** : `customer.subscription.created`

**Payload envoyé à Firebase** :
```http
POST https://us-central1-PROJET.cloudfunctions.net/ext-firestore-stripe-payments-handleWebhookEvents
Stripe-Signature: t=1234567890,v1=xxxxxxxxxxxxx

{
  "id": "evt_xxxxxxxxxxxxx",
  "type": "customer.subscription.created",
  "data": {
    "object": {
      "id": "sub_xxxxxxxxxxxxx",
      "customer": "cus_xxxxxxxxxxxxx",
      "status": "active",
      "items": {
        "data": [{
          "price": {
            "id": "price_xxxxxxxxxxxxx",
            "unit_amount": 1900,
            "currency": "eur",
            "recurring": {"interval": "month"}
          }
        }]
      },
      "current_period_start": 1700000000,
      "current_period_end": 1702678400,
      ...
    }
  }
}
```

#### Étape C2 : Extension traite le webhook
```javascript
// Cloud Function générée par l'extension
exports.handleWebhookEvents = functions.https.onRequest(async (req, res) => {
  const signature = req.headers['stripe-signature'];
  
  // Vérifier la signature
  const event = stripe.webhooks.constructEvent(req.rawBody, signature, webhookSecret);
  
  if (event.type === 'customer.subscription.created' || 
      event.type === 'customer.subscription.updated') {
    const subscription = event.data.object;
    
    // Trouver le document utilisateur via le customer ID
    const customerDoc = await findUserByStripeId(subscription.customer);
    
    // Créer/mettre à jour le document subscription
    await admin.firestore()
      .collection('users')
      .doc(customerDoc.uid)
      .collection('subscriptions')
      .doc(subscription.id)
      .set({
        status: subscription.status,
        current_period_start: subscription.current_period_start,
        current_period_end: subscription.current_period_end,
        cancel_at_period_end: subscription.cancel_at_period_end,
        items: subscription.items.data.map(item => ({
          price: item.price.id,
          quantity: item.quantity,
        })),
        created: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
  }
  
  res.json({ received: true });
});
```

#### Étape C3 : Document créé dans Firestore

**Nouveau document** :
```
Collection: users/kSd8f9JK.../subscriptions
Document ID: sub_xxxxxxxxxxxxx
Données:
{
  "status": "active",
  "current_period_start": 1700000000,
  "current_period_end": 1702678400,
  "cancel_at_period_end": false,
  "items": [{
    "price": "price_xxxxxxxxxxxxx",
    "quantity": 1
  }],
  "created": Timestamp(2025-11-24 10:35:45),
  "metadata": {},
  "role": null,
  "stripeLink": "https://dashboard.stripe.com/subscriptions/sub_xxxxxxxxxxxxx"
}
```

### Partie D : Mise à jour de l'interface Flutter

#### Étape D1 : Stream détecte le changement
```dart
// subscription_service.dart ligne 31-48
Stream<SubscriptionStatus> getSubscriptionStatus() {
  return _firestore
    .collection('users')
    .doc(userId)
    .collection('subscriptions')
    .snapshots() // ← Ce Stream émet quand Firestore change
    .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return SubscriptionStatus.none;
      }
      
      final subscriptionData = snapshot.docs.first.data();
      return _parseSubscriptionStatus(subscriptionData);
    });
}
```

#### Étape D2 : StreamBuilder se reconstruit
```dart
// home_screen.dart ligne 24-37
StreamBuilder<SubscriptionStatus>(
  stream: subscriptionService.getSubscriptionStatus(),
  builder: (context, snapshot) {
    // Ce builder est appelé quand le stream émet
    final status = snapshot.data ?? SubscriptionStatus.none;
    return _buildContent(context, status);
  },
)
```

#### Étape D3 : UI affiche "Abonnement actif"
```dart
// home_screen.dart ligne 55-80
Widget _buildStatusCard(BuildContext context, SubscriptionStatus status) {
  final color = status.hasAccess ? Colors.green : Colors.orange;
  // ...
  return Text(
    status.description, // "Abonnement actif"
    style: TextStyle(color: color, fontWeight: FontWeight.bold),
  );
}
```

### Résumé temporel du flux complet

| Étape | Temps | Total cumulé |
|-------|-------|--------------|
| Clic "S'abonner" | 0 ms | 0 ms |
| Création document Firestore | 200 ms | 200 ms |
| Trigger Cloud Function | 500 ms | 700 ms |
| Création session Stripe | 300 ms | 1000 ms |
| Écriture URL dans Firestore | 100 ms | 1100 ms |
| Détection URL par Flutter | 200 ms | 1300 ms |
| Ouverture navigateur | 500 ms | 1800 ms |
| **Paiement utilisateur** | **30-60 s** | **~60 s** |
| Webhook Stripe → Firebase | 1000 ms | +1 s après paiement |
| Écriture subscription Firestore | 200 ms | +1.2 s |
| Flutter détecte changement | 100 ms | +1.3 s |
| UI mise à jour | instantané | +1.3 s |

**Temps total perçu par l'utilisateur** : ~60 secondes (dont ~58 s de saisie)

## Flux 3 : Vérification du statut au démarrage

### Diagramme

```
App Start   AuthGate   HomeScreen   SubscriptionService   Firestore
    |          |            |                |                |
    |--Launch  |            |                |                |
    |          |            |                |                |
    |          |--Check auth                 |                |
    |          |            |                |                |
    |          |--Navigate->|                |                |
    |          |            |                |                |
    |          |            |--getSubscriptionStatus()------->|
    |          |            |                |                |
    |          |            |                |<--Stream-------|
    |          |            |                |  snapshots()   |
    |          |            |                |                |
    |          |            | <--Parse status|                |
    |          |            |                |                |
    | <--------UI displays status            |                |
```

### Détail des étapes

#### Étape 1 : Lancement de l'app
```dart
// main.dart ligne 12-16
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
```

#### Étape 2 : AuthGate vérifie l'authentification
```dart
// auth_gate.dart ligne 19
StreamBuilder<User?>(
  stream: authService.authStateChanges,
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return const HomeScreen();
    }
    return const LoginScreen();
  },
)
```

#### Étape 3 : HomeScreen se construit
```dart
// home_screen.dart ligne 24
StreamBuilder<SubscriptionStatus>(
  stream: subscriptionService.getSubscriptionStatus(),
  // ...
)
```

#### Étape 4 : Service lance le Stream
```dart
// subscription_service.dart ligne 31-48
Stream<SubscriptionStatus> getSubscriptionStatus() {
  return _firestore
    .collection('users')
    .doc(userId) // L'utilisateur connecté
    .collection('subscriptions')
    .snapshots(); // Écoute en temps réel
}
```

#### Étape 5 : Première émission du Stream
Firestore retourne immédiatement l'état actuel :
- Si pas d'abonnement : collection vide
- Si abonnement actif : documents avec `status: "active"`

#### Étape 6 : Parsing et affichage
```dart
// subscription_service.dart ligne 52-73
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

### Temps de chargement

- Initialisation Firebase : 50-100 ms
- Vérification auth : 10-50 ms
- Requête Firestore : 100-300 ms
- Parsing : instantané
- **Total : 160-450 ms**

## Points d'attention sur les flux

### 1. Latence réseau
Tous ces flux dépendent du réseau. En cas de connexion lente :
- Timeouts possibles
- Expérience utilisateur dégradée
- Nécessité d'indicateurs de chargement

### 2. Gestion des erreurs
À chaque étape, des erreurs peuvent survenir :
- Firebase indisponible
- Stripe API en erreur
- Webhook perdu
- Document Firestore non créé

### 3. Idempotence
Les webhooks Stripe peuvent être envoyés plusieurs fois.
L'extension gère cela en utilisant l'ID de l'événement.

### 4. Ordre des événements
Les webhooks ne sont pas toujours reçus dans l'ordre.
L'extension utilise les timestamps pour gérer cela.

## Prochaine étape

Maintenant que vous comprenez les flux de données, découvrez le modèle de données : [Modèle de données Firestore](11_MODELE_DONNEES.md)

