# 11 - Modèle de données Firestore

## Structure complète

```
Firestore Database
│
├─ users (collection)
│  └─ {userId} (document)
│      ├─ email: string
│      ├─ createdAt: timestamp
│      ├─ stripeId: string (ajouté par l'extension)
│      │
│      ├─ checkout_sessions (sous-collection)
│      │  └─ {sessionId} (document)
│      │      ├─ price: string
│      │      ├─ mode: string
│      │      ├─ success_url: string
│      │      ├─ cancel_url: string
│      │      ├─ url: string (ajouté par l'extension)
│      │      ├─ sessionId: string (ajouté par l'extension)
│      │      └─ created: timestamp
│      │
│      ├─ subscriptions (sous-collection)
│      │  └─ {subscriptionId} (document)
│      │      ├─ status: string
│      │      ├─ current_period_start: number
│      │      ├─ current_period_end: number
│      │      ├─ cancel_at_period_end: boolean
│      │      ├─ items: array
│      │      ├─ created: timestamp
│      │      └─ metadata: map
│      │
│      └─ payments (sous-collection)
│          └─ {paymentId} (document)
│              ├─ amount: number
│              ├─ currency: string
│              ├─ status: string
│              ├─ created: timestamp
│              └─ invoiceId: string
│
└─ products (collection)
    └─ {productId} (document)
        ├─ name: string
        ├─ description: string
        ├─ active: boolean
        ├─ role: string
        ├─ images: array
        ├─ metadata: map
        │
        └─ prices (sous-collection)
            └─ {priceId} (document)
                ├─ active: boolean
                ├─ currency: string
                ├─ interval: string
                ├─ interval_count: number
                ├─ unit_amount: number
                ├─ type: string
                └─ product: reference
```

## Collection users

### Document utilisateur

**Chemin :** `users/{userId}`

**Exemple :**
```json
{
  "email": "user@example.com",
  "createdAt": Timestamp(2025-11-24 10:30:00),
  "stripeId": "cus_QrStUvWxYz1234"
}
```

**Champs :**
| Champ | Type | Créé par | Description |
|-------|------|----------|-------------|
| `email` | string | AuthService | Email de l'utilisateur |
| `createdAt` | timestamp | AuthService | Date de création du compte |
| `stripeId` | string | Extension | ID du client Stripe |

## Sous-collection checkout_sessions

### Document de session

**Chemin :** `users/{userId}/checkout_sessions/{sessionId}`

**Exemple (avant traitement) :**
```json
{
  "price": "price_1OAbCdEfGhIjKlMn",
  "mode": "subscription",
  "success_url": "https://votre-app.com/success",
  "cancel_url": "https://votre-app.com/cancel",
  "created": Timestamp(2025-11-24 10:35:00)
}
```

**Exemple (après traitement par l'extension) :**
```json
{
  "price": "price_1OAbCdEfGhIjKlMn",
  "mode": "subscription",
  "success_url": "https://votre-app.com/success",
  "cancel_url": "https://votre-app.com/cancel",
  "created": Timestamp(2025-11-24 10:35:00),
  "url": "https://checkout.stripe.com/c/pay/cs_test_abc123",
  "sessionId": "cs_test_abc123"
}
```

**Champs :**
| Champ | Type | Créé par | Description |
|-------|------|----------|-------------|
| `price` | string | Flutter | Price ID Stripe |
| `mode` | string | Flutter | "subscription" ou "payment" |
| `success_url` | string | Flutter | URL de retour succès |
| `cancel_url` | string | Flutter | URL de retour annulation |
| `url` | string | Extension | URL Checkout générée |
| `sessionId` | string | Extension | ID de la session Stripe |

## Sous-collection subscriptions

### Document d'abonnement

**Chemin :** `users/{userId}/subscriptions/{subscriptionId}`

**Exemple :**
```json
{
  "status": "active",
  "current_period_start": 1700000000,
  "current_period_end": 1702678400,
  "cancel_at_period_end": false,
  "items": [
    {
      "price": {
        "id": "price_1OAbCdEfGhIjKlMn",
        "unit_amount": 1900,
        "currency": "eur",
        "recurring": {
          "interval": "month",
          "interval_count": 1
        }
      },
      "quantity": 1
    }
  ],
  "created": Timestamp(2025-11-24 10:35:45),
  "metadata": {},
  "role": null,
  "stripeLink": "https://dashboard.stripe.com/subscriptions/sub_abc123"
}
```

**Champs principaux :**
| Champ | Type | Description | Valeurs possibles |
|-------|------|-------------|-------------------|
| `status` | string | État de l'abonnement | active, trialing, past_due, canceled, unpaid, incomplete |
| `current_period_start` | number | Début période (timestamp Unix) | Ex: 1700000000 |
| `current_period_end` | number | Fin période (timestamp Unix) | Ex: 1702678400 |
| `cancel_at_period_end` | boolean | Annulé en fin de période ? | true / false |
| `items` | array | Liste des prix facturés | Voir structure ci-dessous |
| `created` | timestamp | Date de création Firestore | Timestamp Firestore |
| `role` | string | Rôle attribué (optionnel) | "premium", null |
| `stripeLink` | string | Lien vers Stripe Dashboard | URL https:// |

**Structure items :**
```json
{
  "price": {
    "id": "price_xxx",
    "unit_amount": 1900,
    "currency": "eur",
    "recurring": {
      "interval": "month",
      "interval_count": 1
    }
  },
  "quantity": 1
}
```

## Sous-collection payments

### Document de paiement

**Chemin :** `users/{userId}/payments/{paymentId}`

**Exemple :**
```json
{
  "amount": 1900,
  "currency": "eur",
  "status": "succeeded",
  "created": Timestamp(2025-11-24 10:35:50),
  "invoiceId": "in_abc123",
  "stripeLink": "https://dashboard.stripe.com/payments/py_abc123"
}
```

**Champs :**
| Champ | Type | Description |
|-------|------|-------------|
| `amount` | number | Montant en centimes (1900 = 19 €) |
| `currency` | string | Devise (eur, usd, etc.) |
| `status` | string | État : succeeded, pending, failed |
| `created` | timestamp | Date du paiement |
| `invoiceId` | string | ID de la facture Stripe |

## Collection products

### Document produit

**Chemin :** `products/{productId}`

**Exemple :**
```json
{
  "name": "Plan Premium",
  "description": "Accès illimité aux fonctionnalités premium",
  "active": true,
  "role": "premium",
  "images": ["https://example.com/image.png"],
  "metadata": {
    "firebaseRole": "premium"
  }
}
```

## Sous-collection prices

### Document prix

**Chemin :** `products/{productId}/prices/{priceId}`

**Exemple :**
```json
{
  "active": true,
  "currency": "eur",
  "interval": "month",
  "interval_count": 1,
  "unit_amount": 1900,
  "type": "recurring",
  "product": "DocumentReference(products/prod_abc123)"
}
```

## Timestamps : Firestore vs Unix

### Timestamp Firestore

```dart
FieldValue.serverTimestamp()
```

Format : Objet Timestamp Firestore

Exemple lecture :
```dart
final createdAt = data['createdAt'] as Timestamp;
final dateTime = createdAt.toDate(); // Conversion en DateTime
```

### Timestamp Unix (secondes)

Format : Number (secondes depuis 1970-01-01)

Exemple lecture :
```dart
final periodEnd = data['current_period_end'] as int;
final dateTime = DateTime.fromMillisecondsSinceEpoch(periodEnd * 1000);
```

⚠️ **Attention :** Multiplier par 1000 (secondes → millisecondes)

## Règles de lecture/écriture

### Qui peut lire/écrire quoi ?

| Collection | Lecture | Écriture |
|------------|---------|----------|
| `users/{uid}` | Utilisateur propriétaire | Utilisateur propriétaire |
| `checkout_sessions` | Utilisateur propriétaire | Utilisateur (création) + Extension (mise à jour) |
| `subscriptions` | Utilisateur propriétaire | Extension uniquement |
| `payments` | Utilisateur propriétaire | Extension uniquement |
| `products` | Tous | Admin uniquement |
| `prices` | Tous | Admin uniquement |

## Exemples de requêtes

### Lire l'abonnement actif

```dart
final snapshot = await FirebaseFirestore.instance
  .collection('users/$userId/subscriptions')
  .where('status', isEqualTo: 'active')
  .limit(1)
  .get();

if (snapshot.docs.isNotEmpty) {
  final subscriptionData = snapshot.docs.first.data();
  print('Statut : ${subscriptionData['status']}');
}
```

### Écouter les changements d'abonnement

```dart
FirebaseFirestore.instance
  .collection('users/$userId/subscriptions')
  .snapshots()
  .listen((snapshot) {
    for (var doc in snapshot.docs) {
      print('Abonnement ${doc.id} : ${doc.data()['status']}');
    }
  });
```

### Lire tous les paiements

```dart
final snapshot = await FirebaseFirestore.instance
  .collection('users/$userId/payments')
  .orderBy('created', descending: true)
  .get();

for (var doc in snapshot.docs) {
  final data = doc.data();
  print('Paiement : ${data['amount']} ${data['currency']} - ${data['status']}');
}
```

## Prochaine étape

Comprendre la gestion des états : [Gestion des états d'abonnement](12_ETATS_ABONNEMENT.md)

