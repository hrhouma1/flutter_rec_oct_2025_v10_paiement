# 03 - Concepts clés

## Concepts Firebase

### 1. Firebase Auth

**Qu'est-ce que c'est ?**
Un service d'authentification géré qui crée et maintient des comptes utilisateurs.

**Concepts importants** :

#### User ID (UID)
- Identifiant unique de chaque utilisateur
- Format : chaîne alphanümérique de 28 caractères
- Exemple : `kSd8f9JKldfjKL3j9sdkfj2Lksdf`
- Utilisé comme clé primaire dans Firestore

#### Token JWT
- Jeton d'authentification généré automatiquement
- Contient l'UID et les informations de l'utilisateur
- Expire après 1 heure (renouvelé automatiquement)
- Envoyé avec chaque requête Firestore pour validation

#### Auth State
- État de connexion de l'utilisateur
- Peut être : connecté, déconnecté, en cours de vérification
- Observable via un Stream

**Pourquoi c'est important ?**
Sans authentification, impossible de :
- Savoir qui est l'utilisateur
- Sécuriser les données dans Firestore
- Associer un abonnement à un utilisateur

### 2. Firestore (Base de données)

**Qu'est-ce que c'est ?**
Une base de données NoSQL en temps réel, structurée en collections et documents.

**Structure hiérarchique** :

```
Collection (ex: users)
  └─ Document (ex: user123)
      ├─ Champ: email = "user@example.com"
      ├─ Champ: createdAt = timestamp
      └─ Sous-collection (ex: subscriptions)
          └─ Document (ex: sub456)
              ├─ Champ: status = "active"
              └─ Champ: priceId = "price_xxx"
```

**Concepts importants** :

#### Collections
- Conteneurs de documents
- Équivalent des "tables" en SQL
- Nom : pluriel (users, products, subscriptions)

#### Documents
- Objet JSON avec des paires clé-valeur
- Identifié par un ID unique
- Taille max : 1 Mo

#### Sous-collections
- Collections imbriquées dans un document
- Permettent l'organisation hiérarchique
- Exemple : `users/{uid}/subscriptions/{subId}`

#### Timestamps
- Date et heure gérées par le serveur
- Toujours précises (pas de décalage client)
- Type : `Timestamp` Firestore

#### Streams
- Flux de données en temps réel
- Flutter écoute les changements
- Notification automatique des mises à jour

**Pourquoi c'est important ?**
Firestore est le point central de l'application :
- Stocke les données utilisateurs
- Stocke les abonnements synchronisés depuis Stripe
- Permet la réactivité en temps réel

### 3. Cloud Functions

**Qu'est-ce que c'est ?**
Du code JavaScript/TypeScript qui s'exécute sur les serveurs de Google en réponse à des événements.

**Déclencheurs (Triggers)** :

#### onCreate
```javascript
// S'exécute quand un document est créé
exports.onCheckoutCreated = functions.firestore
  .document('users/{uid}/checkout_sessions/{sessionId}')
  .onCreate((snapshot, context) => {
    // Créer une session Stripe Checkout
  });
```

#### onUpdate
```javascript
// S'exécute quand un document est modifié
exports.onSubscriptionUpdated = functions.firestore
  .document('users/{uid}/subscriptions/{subId}')
  .onUpdate((change, context) => {
    // Réagir au changement
  });
```

#### HTTP Trigger
```javascript
// S'exécute quand une requête HTTP arrive
exports.handleWebhook = functions.https.onRequest((req, res) => {
  // Traiter le webhook Stripe
});
```

**Dans notre application** :
L'extension Stripe génère automatiquement ces fonctions :
- `createCheckoutSession` : créer une session de paiement
- `handleWebhookEvents` : recevoir les webhooks Stripe
- `createPortalLink` : créer un lien vers le portail client

**Pourquoi c'est important ?**
Les Cloud Functions sont le seul endroit sûr pour :
- Stocker les clés secrètes Stripe
- Appeler l'API Stripe
- Traiter les webhooks

## Concepts Stripe

### 1. Produit (Product)

**Qu'est-ce que c'est ?**
Une offre que vous vendez.

**Exemple** :
- Nom : "Plan Premium"
- Description : "Accès illimité à toutes les fonctionnalités"

**Métadonnées** :
Informations personnalisées ajoutées au produit.
```json
{
  "firebaseRole": "premium",
  "features": "analytics,export,priority_support"
}
```

### 2. Prix (Price)

**Qu'est-ce que c'est ?**
Le montant et la récurrence d'un produit.

**Un produit peut avoir plusieurs prix** :
- Plan Premium - Mensuel : 19 €/mois
- Plan Premium - Annuel : 190 €/an (économie de 2 mois)

**Attributs d'un prix** :
- `amount` : montant en centimes (1900 = 19 €)
- `currency` : devise (eur, usd)
- `interval` : récurrence (month, year)
- `interval_count` : nombre d'intervalles (1 = chaque mois, 3 = tous les 3 mois)

**ID du prix** :
- Format : `price_xxxxxxxxxxxxx`
- Nécessaire pour créer un abonnement
- Copié dans le code Flutter

### 3. Client (Customer)

**Qu'est-ce que c'est ?**
Un compte Stripe représentant un utilisateur.

**Création** :
Automatique lors du premier paiement par l'extension Firebase.

**Contenu** :
- Email
- Nom (optionnel)
- Métadonnées (ex: `firebaseUID`)
- Moyens de paiement enregistrés
- Historique des paiements

**Lien avec Firebase** :
```
Firebase User (UID: kSd8f9JK...)
    ↕
Stripe Customer (ID: cus_abc123)
```

L'extension stocke le lien dans Firestore :
```json
{
  "stripeId": "cus_abc123"
}
```

### 4. Abonnement (Subscription)

**Qu'est-ce que c'est ?**
Un contrat de paiement récurrent entre un client et votre entreprise.

**Structure** :
```
Subscription
  ├─ Customer : cus_abc123
  ├─ Price : price_xxx
  ├─ Status : active
  ├─ Current period start : 1er novembre
  ├─ Current period end : 1er décembre
  └─ Cancel at period end : false
```

**Statuts possibles** :

| Statut | Signification | Accès premium ? |
|--------|---------------|-----------------|
| `active` | Abonnement actif, paiement réussi | Oui |
| `trialing` | Période d'essai | Oui |
| `past_due` | Paiement échoué, Stripe réessaie | Selon logique métier |
| `canceled` | Annulé, peut être actif jusqu'à la fin | Vérifier `current_period_end` |
| `incomplete` | Paiement initial non complété | Non |
| `incomplete_expired` | Paiement jamais complété | Non |
| `unpaid` | Tous les paiements ont échoué | Non |

### 5. Stripe Checkout

**Qu'est-ce que c'est ?**
Une page de paiement hébergée par Stripe.

**Avantages** :
- Sécurisée (PCI compliant)
- Optimisée pour la conversion
- Supporte tous les moyens de paiement
- Mobile-friendly
- Multilingue

**Flux** :
```
1. Application crée une session Checkout via API Stripe
2. Stripe retourne une URL unique
3. Application redirige vers cette URL
4. Utilisateur paie sur la page Stripe
5. Stripe redirige vers success_url ou cancel_url
```

**Modes** :
- `payment` : paiement unique
- `subscription` : abonnement récurrent (notre cas)
- `setup` : enregistrer un moyen de paiement sans payer

### 6. Webhooks

**Qu'est-ce que c'est ?**
Des notifications HTTP envoyées par Stripe quand un événement se produit.

**Événements importants** :

```
customer.created
└─ Quand un nouveau client est créé

customer.subscription.created
└─ Quand un abonnement est créé

customer.subscription.updated
└─ Quand un abonnement change (status, prix, etc.)

customer.subscription.deleted
└─ Quand un abonnement est supprimé

invoice.payment_succeeded
└─ Quand un paiement réussit

invoice.payment_failed
└─ Quand un paiement échoue
```

**Structure d'un webhook** :
```json
{
  "id": "evt_xxx",
  "type": "customer.subscription.updated",
  "data": {
    "object": {
      "id": "sub_xxx",
      "status": "active",
      "customer": "cus_xxx",
      ...
    }
  }
}
```

**Sécurité** :
- Signature dans le header `Stripe-Signature`
- Vérification côté serveur (Cloud Function)
- Empêche les webhooks falsifiés

**Pourquoi c'est important ?**
Sans webhooks, l'application ne saurait jamais :
- Qu'un paiement a réussi
- Qu'un abonnement a été annulé
- Qu'un paiement a échoué

### 7. Portail Client (Customer Portal)

**Qu'est-ce que c'est ?**
Une interface hébergée par Stripe où vos clients peuvent gérer leur abonnement.

**Fonctionnalités** :
- Voir l'abonnement actuel
- Annuler l'abonnement
- Changer de plan (upgrade/downgrade)
- Mettre à jour le moyen de paiement
- Voir l'historique de facturation
- Télécharger les factures

**Avantages** :
- Pas de code à écrire
- Interface professionnelle
- Sécurisée
- Personnalisable (logo, couleurs)

## Concepts Flutter

### 1. Streams

**Qu'est-ce que c'est ?**
Un flux de données asynchrones qui émet des valeurs au fil du temps.

**Analogie** :
Comme un tuyau d'eau : l'eau (les données) coule en continu.

**Dans notre application** :
```dart
Stream<SubscriptionStatus> getSubscriptionStatus() {
  return firestore
    .collection('users/${userId}/subscriptions')
    .snapshots() // Stream de documents Firestore
    .map((snapshot) => parseStatus(snapshot)); // Transformation
}
```

**Écoute avec StreamBuilder** :
```dart
StreamBuilder<SubscriptionStatus>(
  stream: subscriptionService.getSubscriptionStatus(),
  builder: (context, snapshot) {
    // Se reconstruit automatiquement quand le stream émet
    if (snapshot.hasData) {
      return Text(snapshot.data.description);
    }
    return CircularProgressIndicator();
  },
)
```

**Pourquoi c'est important ?**
Permet la réactivité en temps réel sans polling.

### 2. Futures

**Qu'est-ce que c'est ?**
Une valeur qui sera disponible dans le futur (opération asynchrone unique).

**Différence avec Stream** :
- Future : 1 valeur, puis terminé
- Stream : 0, 1 ou plusieurs valeurs en continu

**Exemple** :
```dart
Future<void> createCheckoutSession() async {
  // Opération unique qui retourne quand c'est terminé
  await firestore.collection('checkout_sessions').add({...});
}
```

### 3. Provider

**Qu'est-ce que c'est ?**
Un système de gestion d'état qui permet de partager des données dans l'arbre de widgets.

**Dans notre application** :
```dart
// Fourniture au niveau racine
MultiProvider(
  providers: [
    Provider<AuthService>(create: (_) => AuthService()),
    Provider<SubscriptionService>(create: (_) => SubscriptionService()),
  ],
  child: MyApp(),
)

// Consommation n'importe où dans l'arbre
final authService = Provider.of<AuthService>(context);
```

**Pourquoi c'est important ?**
Évite de passer les services manuellement de widget en widget.

### 4. Séparation Services / UI

**Principe** :
La logique métier (services) est séparée de l'interface (widgets).

**Structure** :
```
lib/
├─ services/          ← Logique métier
│   ├─ auth_service.dart
│   └─ subscription_service.dart
├─ screens/           ← Interface utilisateur
│   ├─ login_screen.dart
│   └─ home_screen.dart
└─ models/            ← Structures de données
    └─ subscription_status.dart
```

**Avantages** :
- Code réutilisable
- Facile à tester
- Facile à maintenir
- Responsabilités claires

## Concepts de sécurité

### 1. Règles Firestore

**Qu'est-ce que c'est ?**
Un langage déclaratif pour définir qui peut lire/écrire quoi.

**Exemple** :
```javascript
match /users/{userId} {
  // Seul l'utilisateur peut lire/écrire son propre document
  allow read, write: if request.auth.uid == userId;
}
```

**Variables disponibles** :
- `request.auth.uid` : UID de l'utilisateur connecté
- `resource.data` : données actuelles du document
- `request.resource.data` : nouvelles données proposées

### 2. Principe de moindre privilège

**Définition** :
Chaque partie du système n'a accès qu'au minimum nécessaire.

**Dans notre application** :
- Flutter : peut lire les abonnements, pas les modifier
- Cloud Functions : peuvent tout faire (mais sont sécurisées côté serveur)
- Utilisateur : peut lire uniquement ses propres données

### 3. Jamais de clés secrètes côté client

**Règle d'or** :
Les clés API Stripe secrètes (`sk_...`) ne doivent JAMAIS être dans le code Flutter.

**Pourquoi ?**
- Le code Flutter est décompilable
- N'importe qui pourrait extraire la clé
- Accès total à votre compte Stripe

**Solution** :
Les clés sont stockées dans Firebase (Cloud Functions), côté serveur.

## Glossaire

| Terme | Définition |
|-------|------------|
| **UID** | User ID unique généré par Firebase Auth |
| **Token** | Jeton d'authentification JWT |
| **Collection** | Groupe de documents dans Firestore |
| **Document** | Objet JSON dans Firestore |
| **Stream** | Flux de données asynchrones continu |
| **Future** | Valeur asynchrone unique |
| **Webhook** | Notification HTTP automatique |
| **Checkout** | Page de paiement Stripe |
| **Price ID** | Identifiant d'un prix Stripe |
| **Subscription** | Abonnement récurrent |
| **Extension** | Plugin Firebase qui ajoute des fonctionnalités |

## Prochaine étape

Maintenant que vous comprenez les concepts, passez à la configuration : [Guide Firebase](04_FIREBASE.md)

