# 01 - Introduction et objectifs

## Qu'est-ce que cette application ?

Cette application Flutter est un **outil pédagogique** conçu pour enseigner comment intégrer des **abonnements payants récurrents** dans une application mobile en utilisant :

- **Firebase** (authentification et base de données)
- **Stripe** (traitement des paiements)
- **Extension Firebase Stripe** (pont automatique entre Stripe et Firebase)

## Objectifs d'apprentissage

À la fin de ce cours, vous serez capable de :

### 1. Comprendre l'architecture SaaS
- Comment fonctionne un système d'abonnement moderne
- Pourquoi séparer l'authentification, les données et les paiements
- Comment ces systèmes communiquent entre eux

### 2. Maîtriser Firebase
- Configurer Firebase Auth pour gérer les utilisateurs
- Utiliser Firestore pour stocker et lire des données en temps réel
- Comprendre les règles de sécurité Firestore

### 3. Intégrer Stripe
- Créer des produits et des prix dans Stripe
- Générer des sessions de paiement (Checkout)
- Comprendre les webhooks et la synchronisation

### 4. Utiliser l'Extension Firebase
- Installer et configurer une extension Firebase
- Comprendre comment elle génère des Cloud Functions
- Lire les données synchronisées automatiquement

### 5. Développer en Flutter
- Structurer une application avec services et écrans
- Utiliser les Streams pour la réactivité en temps réel
- Implémenter un système de paywall conditionnel
- Gérer les états d'abonnement

## Pourquoi cette approche ?

### Avantages de Firebase + Stripe + Extension

1. **Pas de backend personnalisé à coder**
   - Pas de serveur Node.js, Python ou autre
   - Les Cloud Functions sont générées automatiquement
   - Maintenance minimale

2. **Sécurité robuste**
   - Les clés secrètes Stripe ne sont jamais dans le code client
   - Firebase gère l'authentification
   - Les webhooks sont sécurisés automatiquement

3. **Synchronisation automatique**
   - Stripe envoie les événements à Firebase
   - Firestore est mis à jour en temps réel
   - Flutter écoute les changements et réagit

4. **Scalabilité**
   - Firebase scale automatiquement
   - Stripe gère des millions de transactions
   - Pas de serveur à gérer

## Cas d'usage réels

Cette architecture est utilisée dans :

- Applications de méditation (Calm, Headspace)
- Plateformes d'apprentissage en ligne
- Applications de fitness avec coaching
- Services de streaming de contenu
- Outils SaaS mobiles

## Ce que cette application FAIT

1. Permet de créer un compte utilisateur
2. Affiche le statut d'abonnement en temps réel
3. Propose un écran de vente (paywall)
4. Redirige vers Stripe Checkout pour le paiement
5. Synchronise automatiquement le statut d'abonnement
6. Débloque l'accès aux fonctionnalités premium
7. Permet de gérer l'abonnement via le portail Stripe

## Ce que cette application NE FAIT PAS

Pour rester pédagogique et simple :

- Pas de design complexe ou d'animations
- Pas de gestion de plusieurs plans simultanés
- Pas de période d'essai gratuite (mais facile à ajouter)
- Pas d'analytics ou de suivi avancé
- Pas de fonctionnalités premium réelles (juste une démonstration)

## Prérequis techniques

### Connaissances requises

- **Flutter** : savoir créer des widgets, utiliser StatefulWidget
- **Dart** : comprendre async/await, Future, Stream
- **Git** : cloner un projet, faire des commits
- **Ligne de commande** : naviguer dans les dossiers, exécuter des commandes

### Connaissances utiles (mais pas obligatoires)

- Notions de bases de données NoSQL
- Compréhension basique des APIs REST
- Expérience avec Firebase (mais on explique tout)

## Durée estimée

- **Configuration** : 30-45 minutes
- **Compréhension du code** : 2-3 heures
- **Expérimentation** : 2-4 heures
- **Total** : 4-7 heures

## Coûts

### En mode développement/test

- **Firebase** : gratuit (plan Spark)
  - Auth : gratuit
  - Firestore : gratuit jusqu'à 50 000 lectures/jour
  - Functions : 2 millions d'appels/mois gratuits

- **Stripe** : gratuit en mode test
  - Transactions test illimitées
  - Pas de frais tant qu'on reste en mode test

### En production

- **Firebase** : 
  - Auth : gratuit
  - Firestore : 0.18 $ par 100 000 lectures
  - Functions : 0.40 $ par million d'appels

- **Stripe** :
  - 1.4% + 0.25 € par transaction réussie en Europe
  - Pas de frais mensuels fixes

Pour 100 abonnés à 19 €/mois :
- Revenu : 1 900 €
- Frais Stripe : ~30 €
- Frais Firebase : ~2 €
- Net : ~1 868 €

## Philosophie pédagogique

Cette application suit ces principes :

1. **Clarté avant performance**
   - Code simple et lisible
   - Commentaires explicatifs abondants
   - Pas d'optimisations prématurées

2. **Un concept à la fois**
   - Chaque fichier a une responsabilité claire
   - Pas de mélange authentification/paiements/UI

3. **Apprentissage progressif**
   - On commence simple
   - On peut complexifier après

4. **Pratique réelle**
   - Ce n'est pas du code "jouet"
   - C'est une vraie intégration Stripe/Firebase
   - Utilisable comme base pour un vrai projet

## Structure de la documentation

Cette documentation est organisée en modules progressifs :

- **Modules 1-6** : Comprendre et configurer
- **Modules 7-9** : Lire et comprendre le code
- **Modules 10-12** : Comprendre les flux de données
- **Modules 13-16** : Pratiquer et tester
- **Modules 17-19** : Approfondir et optimiser

## Comment tirer le meilleur parti de ce cours

### 1. Lire dans l'ordre
Ne sautez pas les étapes. Chaque module s'appuie sur le précédent.

### 2. Faire les configurations
Installez vraiment Firebase et Stripe. La théorie seule ne suffit pas.

### 3. Expérimenter
Modifiez le code, cassez des choses, réparez-les. C'est comme ça qu'on apprend.

### 4. Poser des questions
Si quelque chose n'est pas clair, cherchez, lisez la documentation officielle, testez.

### 5. Documenter votre apprentissage
Prenez des notes, faites des schémas, expliquez à quelqu'un d'autre.

## Prochaine étape

Passez au module suivant : [Architecture globale](02_ARCHITECTURE.md)

