# 05 - Guide Stripe

## Introduction à Stripe

Stripe est une plateforme de paiement en ligne qui permet aux entreprises d'accepter des paiements par carte bancaire, de gérer des abonnements récurrents et de facturer automatiquement les clients.

## Pourquoi Stripe ?

**Avantages :**
- Intégration simple et bien documentée
- Support de 135+ devises
- Conforme PCI DSS (sécurité des cartes bancaires)
- Gestion automatique des abonnements
- Webhooks fiables
- Mode test gratuit et illimité

**Tarification :**
- Europe : 1,4% + 0,25 € par transaction réussie
- Pas de frais mensuels fixes
- Pas de frais cachés

## Étape 1 : Créer un compte Stripe

### 1.1 Inscription

1. Aller sur https://dashboard.stripe.com/register
2. Remplir le formulaire :
   ```
   Email : votre.email@example.com
   Nom complet : Votre Nom
   Pays : France (ou votre pays)
   Mot de passe : (sécurisé)
   ```
3. Cliquer sur "Créer votre compte"

### 1.2 Vérification de l'email

1. Consulter votre boîte email
2. Cliquer sur le lien de vérification
3. Retourner sur Stripe Dashboard

### 1.3 Compléter le profil (optionnel pour le test)

Pour le moment, vous pouvez **ignorer** :
- Les informations bancaires
- Les documents légaux
- La vérification d'identité

Ces informations ne sont nécessaires que pour passer en **mode live** (production).

## Étape 2 : Activer le mode test

### 2.1 Vérifier le mode

En haut à droite du Stripe Dashboard, vous voyez un toggle :

```
[Test mode]  ◀─ Doit être activé
```

**Mode test :**
- Transactions fictives (pas d'argent réel)
- Cartes de test fonctionnent
- Parfait pour le développement

**Mode live :**
- Transactions réelles
- Cartes réelles uniquement
- Nécessite validation du compte

Pour ce projet : **Rester en mode test**.

## Étape 3 : Créer un produit

### 3.1 Accéder aux produits

1. Dans le menu de gauche, cliquer sur "Products"
2. Cliquer sur "Add product"

### 3.2 Configurer le produit

**Section 1 : Product information**
```
Name : Plan Premium
Description : Accès illimité à toutes les fonctionnalités premium
Image : (optionnel, vous pouvez ignorer)
```

**Section 2 : Pricing**
```
Pricing model : Standard pricing
Price : 19.00
Currency : EUR (ou votre devise)
Billing period : Monthly
```

**Section 3 : Additional options** (optionnel)
```
Tax behavior : (laisser par défaut)
Statement descriptor : (optionnel)
```

### 3.3 Créer le produit

1. Cliquer sur "Add product"
2. Le produit est créé et vous voyez sa page

## Étape 4 : Récupérer l'ID du prix

### 4.1 Trouver le Price ID

Sur la page du produit, section "Pricing", vous voyez :

```
Monthly - €19.00
Price ID : price_1234567890abcdefg    ◀─ Copier cet ID
```

Le Price ID a le format : `price_` suivi de 24 caractères alphanumériques.

### 4.2 Copier le Price ID

1. Cliquer sur le bouton de copie à côté du Price ID
2. **Garder cet ID précieusement** (vous en aurez besoin dans le code Flutter)

Exemple :
```
price_1OAbCdEfGhIjKlMn2OpQrStU
```

### 4.3 Mettre à jour le code Flutter

Ouvrir `lib/services/subscription_service.dart` et remplacer ligne 20 :

```dart
// AVANT
static const String monthlyPriceId = 'price_VOTRE_PRICE_ID_ICI';

// APRÈS
static const String monthlyPriceId = 'price_1OAbCdEfGhIjKlMn2OpQrStU';
```

## Étape 5 : Récupérer les clés API

### 5.1 Accéder aux clés

1. Dans le menu de gauche, cliquer sur "Developers"
2. Cliquer sur "API keys"

Vous voyez deux types de clés :

### 5.2 Clés publiques (Publishable key)

```
Publishable key : pk_test_xxxxxxxxxxxxxxxxxxxxxx
```

**Caractéristiques :**
- Commence par `pk_test_` (test) ou `pk_live_` (production)
- Peut être exposée publiquement
- Utilisée côté client (dans Flutter)
- Sécurité : faible (lecture seule)

**⚠️ Pour ce projet, on ne l'utilise PAS** (tout passe par l'extension Firebase).

### 5.3 Clés secrètes (Secret key)

```
Secret key : sk_test_xxxxxxxxxxxxxxxxxxxxxx
```

**Caractéristiques :**
- Commence par `sk_test_` (test) ou `sk_live_` (production)
- **NE JAMAIS exposer publiquement**
- Utilisée côté serveur uniquement
- Sécurité : élevée (accès total)

**Dans ce projet :**
Cette clé sera utilisée par l'extension Firebase (côté serveur).

### 5.4 Copier la Secret key

1. Cliquer sur "Reveal test key"
2. Copier la clé complète
3. **Garder précieusement** (vous en aurez besoin pour l'extension Firebase)

Exemple :
```
sk_test_51AbCdEfGhIjKlMnOpQrStUvWxYz1234567890abcdefghijklmnopqrstuvwxyz123
```

⚠️ **JAMAIS dans le code Flutter !** Uniquement dans Firebase (serveur).

## Étape 6 : Comprendre les produits et prix

### 6.1 Différence Product vs Price

**Product (Produit)**
```
Ce que vous vendez
Nom : "Plan Premium"
Description : "Accès illimité..."
```

**Price (Prix)**
```
Comment vous le vendez
Montant : 19 €
Récurrence : mensuelle
```

**Relation :**
```
1 Product peut avoir plusieurs Prices
Exemple :
  Product : "Plan Premium"
    ├─ Price 1 : 19 €/mois
    ├─ Price 2 : 190 €/an (économie de 2 mois)
    └─ Price 3 : 5 €/semaine
```

### 6.2 Créer un deuxième prix (optionnel)

Si vous voulez un plan annuel :

1. Sur la page du produit, cliquer sur "Add another price"
2. Configurer :
   ```
   Price : 190.00
   Currency : EUR
   Billing period : Yearly
   ```
3. Cliquer sur "Add price"

Vous avez maintenant deux Price IDs pour le même produit.

## Étape 7 : Configurer les webhooks (sera fait par l'extension)

Les webhooks permettent à Stripe de notifier votre application des événements (paiement réussi, abonnement annulé, etc.).

**Bonne nouvelle :** L'extension Firebase Stripe configure automatiquement les webhooks.

Vous n'avez rien à faire manuellement !

Après l'installation de l'extension, vous verrez un webhook dans :
```
Developers > Webhooks
Endpoint : https://us-central1-PROJET.cloudfunctions.net/ext-...
```

## Étape 8 : Comprendre Stripe Checkout

### 8.1 Qu'est-ce que Checkout ?

Stripe Checkout est une **page de paiement hébergée** par Stripe.

**Avantages :**
- Sécurisée (PCI compliant)
- Optimisée pour la conversion
- Multilingue
- Mobile-friendly
- Support de tous les moyens de paiement

**Flux :**
```
1. Votre app crée une "Session Checkout" via API Stripe
2. Stripe retourne une URL unique
3. Votre app redirige vers cette URL
4. L'utilisateur paie sur la page Stripe
5. Stripe redirige vers votre app (success_url ou cancel_url)
```

### 8.2 Exemple d'URL Checkout

```
https://checkout.stripe.com/c/pay/cs_test_a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0
```

Cette URL :
- Est unique pour chaque session
- Expire après 24 heures si non utilisée
- Contient toutes les informations du paiement

## Étape 9 : Cartes de test

### 9.1 Cartes de test principales

En mode test, utilisez ces numéros de carte :

**Paiement réussi :**
```
Numéro : 4242 4242 4242 4242
Date : n'importe quelle date future (ex: 12/34)
CVC : n'importe quel code à 3 chiffres (ex: 123)
Code postal : n'importe lequel
```

**Authentification 3D Secure requise :**
```
Numéro : 4000 0025 0000 3155
(Stripe affichera une modal de confirmation)
```

**Paiement refusé (fonds insuffisants) :**
```
Numéro : 4000 0000 0000 9995
```

**Paiement refusé (carte déclinée) :**
```
Numéro : 4000 0000 0000 0002
```

### 9.2 Utilisation dans l'app

Quand vous testez l'abonnement dans l'app :

1. Cliquer sur "Débloquer Premium"
2. Sur la page Stripe Checkout, saisir :
   ```
   Numéro de carte : 4242 4242 4242 4242
   MM/AA : 12/34
   CVC : 123
   Nom : Test User
   ```
3. Cliquer sur "Payer"

## Étape 10 : Comprendre le cycle de vie d'un abonnement

### 10.1 États possibles

```
incomplete → active → canceled
     ↓
incomplete_expired

     OU

incomplete → active → past_due → canceled
                          ↓
                      unpaid
```

### 10.2 Transitions d'état

| État | Signification | Cause |
|------|---------------|-------|
| `incomplete` | Paiement initial en cours | Carte nécessite 3D Secure |
| `active` | Abonnement actif | Paiement réussi |
| `past_due` | Paiement en retard | Renouvellement échoué |
| `canceled` | Annulé | Utilisateur ou admin annule |
| `unpaid` | Impayé (après plusieurs échecs) | Tous les paiements ont échoué |

### 10.3 Renouvellement automatique

Stripe gère automatiquement :
- Facturation mensuelle/annuelle
- Tentatives de paiement en cas d'échec
- Emails de notification
- Mise à jour de l'abonnement

Vous n'avez rien à faire !

## Étape 11 : Explorer le Dashboard Stripe

### 11.1 Sections importantes

**Payments**
```
Liste de tous les paiements
Filtre par statut, date, montant
```

**Customers**
```
Liste des clients
Un client = un utilisateur de votre app
```

**Subscriptions**
```
Liste des abonnements
Statut, prochaine facturation
```

**Invoices**
```
Factures générées automatiquement
Envoyées par email aux clients
```

**Logs**
```
Historique de toutes les requêtes API
Très utile pour déboguer
```

### 11.2 Tester les événements

Stripe Dashboard > Developers > Events

Vous verrez tous les événements :
```
customer.created
customer.subscription.created
invoice.payment_succeeded
charge.succeeded
...
```

Cliquer sur un événement pour voir les détails au format JSON.

## Étape 12 : Métadonnées (optionnel mais utile)

### 12.1 Ajouter des métadonnées au produit

Les métadonnées permettent d'associer des informations personnalisées.

1. Sur la page du produit, section "Metadata"
2. Cliquer sur "Add metadata"
3. Ajouter :
   ```
   Key : firebaseRole
   Value : premium
   ```
4. Sauvegarder

**Utilité :**
L'extension Firebase peut utiliser ces métadonnées pour définir des rôles dans Firestore.

## Checklist de validation

Avant de passer à l'extension Firebase, vérifier :

- [ ] Compte Stripe créé et email vérifié
- [ ] Mode test activé (toggle en haut à droite)
- [ ] Produit "Plan Premium" créé
- [ ] Prix mensuel configuré (19 €/mois)
- [ ] Price ID copié (commence par `price_`)
- [ ] Price ID mis à jour dans `subscription_service.dart`
- [ ] Secret key copiée (commence par `sk_test_`)
- [ ] Compris la différence Product vs Price
- [ ] Testé une carte de test manuellement (optionnel)

## Questions de révision

1. Quelle est la différence entre un Product et un Price dans Stripe ?
2. Pourquoi la Secret key ne doit jamais être dans le code Flutter ?
3. Qu'est-ce qu'un webhook et à quoi sert-il ?
4. Que se passe-t-il si un paiement de renouvellement échoue ?
5. Quelle carte de test utiliser pour simuler un paiement réussi ?

## Ressources utiles

**Documentation officielle :**
- Guide Stripe : https://stripe.com/docs
- API Reference : https://stripe.com/docs/api
- Checkout : https://stripe.com/docs/payments/checkout
- Subscriptions : https://stripe.com/docs/billing/subscriptions/overview

**Outils :**
- Stripe CLI : https://stripe.com/docs/stripe-cli
- Postman Collection : https://www.postman.com/stripedev

## Prochaine étape

Stripe est configuré ! Passez maintenant à l'installation de l'extension Firebase : [Extension Firebase Stripe](06_EXTENSION.md)

