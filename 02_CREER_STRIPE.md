# 02 - Créer et configurer Stripe

## Durée : 10 minutes

## 1. Créer un compte Stripe

1. Va sur https://dashboard.stripe.com/register
2. Remplis le formulaire :
   - Email
   - Nom complet
   - Pays : **France** (ou ton pays)
   - Mot de passe
3. Clique sur **"Créer votre compte"**
4. Vérifie ton email et clique sur le lien de confirmation
5. Tu arrives sur le Dashboard Stripe

## 2. Activer le mode TEST

**IMPORTANT** : En haut à droite du Dashboard, vérifie que tu vois :

```
MODE TEST activé
```

Si tu vois "Mode en production", clique dessus pour passer en **mode Test**.

## 3. Créer un produit

1. Dans le menu de gauche, clique sur **"Products"**
2. Clique sur **"Add product"**
3. Remplis :
   - **Name** : `Plan Premium`
   - **Description** : `Accès illimité aux fonctionnalités premium`
   - **Pricing model** : Standard pricing
   - **Price** : `19.00`
   - **Currency** : `EUR`
   - **Billing period** : `Monthly`
4. Clique sur **"Add product"**

## 4. Récupérer le Price ID

1. Sur la page du produit, tu vois :
   ```
   Monthly - €19.00
   Price ID : price_1234567890abcdef
   ```
2. **Copie ce Price ID** (clique sur l'icône de copie)
3. **Garde-le précieusement**, tu en auras besoin à l'étape suivante

## 5. Récupérer la Secret Key

1. Dans le menu de gauche, clique sur **"Developers"**
2. Clique sur **"API keys"**
3. Tu vois deux clés :
   - Publishable key : `pk_test_...` (on n'en a pas besoin)
   - Secret key : `•••••••••••••` (c'est celle-ci)
4. Clique sur **"Reveal test key"**
5. **Copie cette clé** : `sk_test_51Abc...`
6. **Garde-la précieusement**

**IMPORTANT** : Cette clé est secrète, ne la partage JAMAIS publiquement !

## 6. Mettre à jour le code Flutter

Ouvre le fichier `lib/services/subscription_service.dart`

Ligne 20, remplace :
```dart
static const String monthlyPriceId = 'price_VOTRE_PRICE_ID_ICI';
```

Par (avec TON Price ID copié à l'étape 4) :
```dart
static const String monthlyPriceId = 'price_1234567890abcdef';
```

**Sauvegarde le fichier.**

## Vérification

- Tu as créé un compte Stripe
- Tu es en MODE TEST (vérifie en haut à droite)
- Tu as créé un produit "Plan Premium" à 19 €/mois
- Tu as copié le Price ID
- Tu as copié la Secret Key
- Tu as mis à jour `subscription_service.dart` avec ton Price ID

## Prochaine étape

**[03_INSTALLER_EXTENSION.md](03_INSTALLER_EXTENSION.md)** - Installer l'extension Firebase Stripe

