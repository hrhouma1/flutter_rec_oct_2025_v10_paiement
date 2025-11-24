# Application Flutter - Abonnements Stripe

Application pédagogique pour apprendre à intégrer des abonnements payants avec Stripe dans Flutter.

## Documentation

Suis les guides dans cet ordre :

### 01 - [Créer Firebase](01_CREER_FIREBASE.md)
Créer un projet Firebase, activer Authentication et Firestore (10 min)

### 02 - [Créer Stripe](02_CREER_STRIPE.md)
Créer un compte Stripe, créer un produit et récupérer les clés (10 min)

### 03 - [Installer l'extension](03_INSTALLER_EXTENSION.md)
Installer l'extension Firebase Stripe et tester l'app (15 min)

### [Guide rapide](GUIDE_RAPIDE.md)
Architecture, diagrammes et explications techniques

## Temps total

**35 minutes** pour avoir une app fonctionnelle avec abonnements Stripe.

## Architecture

```
Flutter App
    ↓
Firebase (Auth + Firestore)
    ↓
Extension Stripe
    ↓
Stripe (Paiements)
```

## Fonctionnalités

- Authentification par email/mot de passe
- Écran de vente (paywall)
- Paiement Stripe Checkout
- Synchronisation automatique des abonnements
- Accès conditionnel au contenu premium
- Gestion de l'abonnement via portail Stripe

## Carte de test Stripe

```
Numéro : 4242 4242 4242 4242
Date   : 12/34
CVC    : 123
```

## Support

En cas de problème, consulte la section "Problèmes courants" dans [03_INSTALLER_EXTENSION.md](03_INSTALLER_EXTENSION.md)
