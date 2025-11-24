# Documentation complète - Application Flutter Stripe Abonnements

## Bienvenue

Cette documentation explique en détail le fonctionnement d'une application Flutter intégrant des abonnements payants via Stripe et Firebase.

## Par où commencer ?

### Vous êtes débutant avec Stripe/Firebase ?

Lisez dans cet ordre :
1. [Introduction et objectifs](01_INTRODUCTION.md) - Comprendre le projet
2. [Architecture globale](02_ARCHITECTURE.md) - Vue d'ensemble du système
3. [Concepts clés](03_CONCEPTS.md) - Vocabulaire et principes

Ensuite, suivez les guides de configuration :
4. [Guide Firebase](04_FIREBASE.md) - Configuration complète
5. [Guide Stripe](05_STRIPE.md) - Configuration des paiements
6. [Extension Firebase Stripe](06_EXTENSION.md) - Installation et configuration

### Vous voulez comprendre le code ?

Commencez ici :
1. [Structure du projet](07_STRUCTURE_CODE.md) - Organisation des fichiers
2. [Services et logique métier](08_SERVICES.md) - Code métier détaillé
3. [Interface utilisateur](09_INTERFACE.md) - Widgets et écrans

### Vous voulez comprendre le fonctionnement ?

Explorez :
1. [Flux de données complet](10_FLUX_DONNEES.md) - Comment circulent les données
2. [Modèle de données Firestore](11_MODELE_DONNEES.md) - Structure des documents
3. [Gestion des états d'abonnement](12_ETATS_ABONNEMENT.md) - Statuts et transitions

### Vous avez un problème ?

Consultez :
1. [Débogage et logs](14_DEBOGAGE.md) - Techniques de débogage
2. [FAQ et problèmes courants](15_FAQ.md) - Solutions aux erreurs fréquentes

### Vous voulez aller plus loin ?

Lisez :
1. [Scénarios de test](13_SCENARIOS_TEST.md) - Tests à effectuer
2. [Exercices pratiques](16_EXERCICES.md) - Exercices pour progresser
3. [Sécurité et bonnes pratiques](17_SECURITE.md) - Production-ready
4. [Optimisations](18_OPTIMISATIONS.md) - Performance et coûts
5. [Aller plus loin](19_ALLER_PLUS_LOIN.md) - Fonctionnalités avancées

## Consultation rapide

### Vue rapide de l'architecture

```
┌─────────────────────────────────────┐
│      Application Flutter             │
│  (Interface utilisateur)             │
└──────────────┬──────────────────────┘
               │
               │ Authentification + Lecture données
               ▼
┌─────────────────────────────────────┐
│          Firebase                    │
│  - Auth (utilisateurs)               │
│  - Firestore (base de données)       │
│  - Functions (logique serveur)       │
│  - Extension Stripe                  │
└──────────────┬──────────────────────┘
               │
               │ Webhooks + API
               ▼
┌─────────────────────────────────────┐
│          Stripe                      │
│  (Traitement des paiements)          │
└─────────────────────────────────────┘
```

### Flux principal : Paiement d'un abonnement

```
1. Utilisateur clique "S'abonner"
2. Flutter crée un document dans Firestore
3. Extension Firebase détecte le document
4. Extension appelle Stripe pour créer une session Checkout
5. Extension écrit l'URL de paiement dans Firestore
6. Flutter ouvre l'URL dans le navigateur
7. Utilisateur paie sur Stripe
8. Stripe envoie un webhook à Firebase
9. Extension met à jour Firestore avec l'abonnement
10. Flutter détecte le changement et met à jour l'UI
```

### Structure du code Flutter

```
lib/
├── main.dart                     # Point d'entrée
├── firebase_options.dart         # Config Firebase
│
├── models/                       # Modèles de données
│   └── subscription_status.dart  # États d'abonnement
│
├── services/                     # Logique métier
│   ├── auth_service.dart         # Authentification
│   └── subscription_service.dart # Abonnements
│
└── screens/                      # Interface
    ├── auth_gate.dart            # Routeur auth
    ├── login_screen.dart         # Connexion
    ├── home_screen.dart          # Accueil
    ├── paywall_screen.dart       # Vente
    └── premium_screen.dart       # Premium
```

### Données dans Firestore

```
users/{userId}
├── email: "user@example.com"
├── createdAt: timestamp
├── stripeId: "cus_xxxxx"           ← Ajouté par l'extension
│
└── subscriptions/                  ← Sous-collection
    └── {subscriptionId}
        ├── status: "active"
        ├── current_period_end: timestamp
        └── items: [...]
```

### Statuts d'abonnement Stripe

| Statut | Signification | Accès premium ? |
|--------|---------------|-----------------|
| `active` | Actif et payé | Oui |
| `trialing` | Période d'essai | Oui |
| `past_due` | Paiement en retard | À définir |
| `canceled` | Annulé | Non (sauf fin période) |
| `incomplete` | Paiement initial échoué | Non |

## Temps estimés

| Activité | Durée |
|----------|-------|
| Lire la documentation complète | 4-6 heures |
| Configuration Firebase + Stripe | 1-2 heures |
| Comprendre le code source | 2-3 heures |
| Expérimentation et tests | 2-4 heures |
| **Total** | **9-15 heures** |

## Prérequis

### Connaissances

- Bases de Flutter (widgets, state)
- Programmation asynchrone (async/await, Future, Stream)
- Notions de bases de données
- Utilisation de la ligne de commande

### Outils

- Flutter SDK 3.0+
- Éditeur de code (VS Code, Android Studio)
- Git
- Compte Firebase (gratuit)
- Compte Stripe (gratuit en mode test)

### Installation

```bash
# Vérifier Flutter
flutter doctor

# Installer FlutterFire CLI
dart pub global activate flutterfire_cli

# Cloner le projet (si applicable)
git clone [URL_DU_PROJET]
cd flutter_stripe_subscriptions_learning

# Installer les dépendances
flutter pub get

# Configurer Firebase
flutterfire configure

# Lancer l'application
flutter run
```

## Concepts clés à maîtriser

### Firebase

- **UID** : Identifiant unique de chaque utilisateur
- **Firestore** : Base de données NoSQL en temps réel
- **Collection** : Groupe de documents (équivalent d'une table SQL)
- **Document** : Objet JSON avec des paires clé-valeur
- **Stream** : Flux de données en temps réel
- **Cloud Functions** : Code exécuté côté serveur

### Stripe

- **Product** : Ce que vous vendez (ex: Plan Premium)
- **Price** : Montant et récurrence (ex: 19 €/mois)
- **Customer** : Un utilisateur qui paie
- **Subscription** : Abonnement récurrent
- **Checkout** : Page de paiement hébergée par Stripe
- **Webhook** : Notification HTTP d'événements

### Flutter

- **Provider** : Partage de données entre widgets
- **StreamBuilder** : Widget qui écoute un Stream
- **Service** : Classe contenant la logique métier
- **Screen** : Widget représentant un écran complet

## Points d'attention importants

### Sécurité

1. Les clés publiques Firebase dans le code sont normales
2. JAMAIS de clé secrète Stripe (`sk_...`) côté client
3. Toute logique sensible doit être côté serveur
4. Les règles Firestore sont votre première ligne de défense

### Coûts

En mode développement (test) : **Gratuit**

En production pour 100 abonnés à 19 €/mois :
- Revenu : 1 900 €
- Frais Stripe : ~31 € (1,6%)
- Frais Firebase : ~2 € (négligeable)
- **Net : ~1 867 €**

### Temps de latence

- Création de session Checkout : 1-2 secondes
- Paiement utilisateur : 30-60 secondes
- Synchronisation webhook : 1-3 secondes
- **Total perçu : ~1 minute**

## Support et ressources

### Documentation officielle

- Flutter : https://docs.flutter.dev
- Firebase : https://firebase.google.com/docs
- Stripe : https://stripe.com/docs
- Extension Stripe : https://github.com/stripe/stripe-firebase-extensions

### Communautés

- Stack Overflow : Tags `flutter`, `firebase`, `stripe`
- Reddit : r/FlutterDev
- Discord : Flutter Dev Community

### En cas de problème

1. Consulter la [FAQ](15_FAQ.md)
2. Vérifier les logs Firebase Functions
3. Vérifier les webhooks dans Stripe Dashboard
4. Activer les logs de débogage dans le code

## Structure de la documentation

La documentation est organisée en 19 modules numérotés :

**01-03** : Introduction et concepts  
**04-06** : Configuration des services  
**07-09** : Compréhension du code  
**10-12** : Fonctionnement interne  
**13-16** : Pratique et tests  
**17-19** : Avancé et optimisation

Chaque module est conçu pour être lu en 15-30 minutes.

## Objectif final

À la fin de ce parcours, vous serez capable de :

1. Configurer Firebase Auth et Firestore
2. Créer des produits et prix dans Stripe
3. Installer et configurer l'extension Firebase Stripe
4. Comprendre le flux complet d'un paiement
5. Lire et modifier le code de l'application
6. Gérer les différents états d'abonnement
7. Déboguer les problèmes courants
8. Déployer une version production-ready

## Licence et utilisation

Ce code est fourni à des fins pédagogiques.
Vous êtes libre de l'utiliser, le modifier et le distribuer.

## Contribuer

Pour améliorer cette documentation :
- Signaler les erreurs ou imprécisions
- Proposer des clarifications
- Ajouter des exemples
- Partager vos retours d'expérience

## Commencer maintenant

Prêt à apprendre ? Commencez par :

**[01 - Introduction et objectifs →](01_INTRODUCTION.md)**

Bon apprentissage !

