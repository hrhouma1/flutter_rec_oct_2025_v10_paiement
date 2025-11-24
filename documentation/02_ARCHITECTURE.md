# 02 - Architecture globale

## Vue d'ensemble

L'application repose sur une architecture à **trois piliers** :

1. **Flutter** - Interface utilisateur (client)
2. **Firebase** - Backend (authentification, base de données, fonctions)
3. **Stripe** - Traitement des paiements

Ces trois systèmes communiquent de manière orchestrée pour créer une expérience fluide.

## Schéma architectural

```
┌─────────────────────────────────────────────────────────────────┐
│                         UTILISATEUR                              │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 │ Interactions
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                      APPLICATION FLUTTER                         │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │   Écrans     │  │   Services   │  │   Modèles    │         │
│  │ (UI/Widgets) │◄─┤  (Logique)   │◄─┤   (Données)  │         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
│         │                  │                                     │
└─────────┼──────────────────┼─────────────────────────────────────┘
          │                  │
          │ Auth             │ Lecture/Écriture
          │                  │
          ▼                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                        FIREBASE                                  │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │ Firebase Auth│  │  Firestore   │  │   Functions  │         │
│  │              │  │   (NoSQL)    │  │   (Cloud)    │         │
│  └──────────────┘  └──────┬───────┘  └───────┬──────┘         │
│                            │                   │                 │
│                            │    ┌──────────────┴──────────┐    │
│                            │    │  Extension Stripe        │    │
│                            │    │  (Synchronisation)       │    │
│                            │    └──────────────┬───────────┘    │
└────────────────────────────┼────────────────────┼────────────────┘
                             │                    │
                             │ Lecture            │ Webhooks
                             │ Écriture           │
                             │                    ▼
                             │          ┌────────────────────┐
                             └──────────┤     STRIPE         │
                                        │  (Paiements)       │
                                        └────────────────────┘
```

## Les trois piliers en détail

### 1. Flutter (Client)

**Rôle** : Interface utilisateur et expérience

**Responsabilités** :
- Afficher les écrans (login, accueil, paywall, premium)
- Récupérer les interactions utilisateur
- Lire les données dans Firestore
- Déclencher les actions (connexion, paiement)

**N'a PAS accès à** :
- Clés secrètes Stripe
- Logique de paiement côté serveur
- Manipulation directe des abonnements Stripe

**Technologies** :
- Dart + Flutter SDK
- Packages : firebase_auth, cloud_firestore, url_launcher, provider

### 2. Firebase (Backend)

**Rôle** : Backend sans serveur (BaaS - Backend as a Service)

**Composants utilisés** :

#### Firebase Auth
- Gère les comptes utilisateurs
- Authentification email/password
- Génère des tokens JWT pour sécuriser les requêtes

#### Firestore
- Base de données NoSQL en temps réel
- Stocke les informations utilisateurs
- Stocke les abonnements et paiements
- Mise à jour instantanée côté client

#### Cloud Functions
- Serveur sans serveur (serverless)
- Générées automatiquement par l'extension
- Gèrent les webhooks Stripe
- Sécurisent les opérations sensibles

#### Extension Stripe
- Plugin installé dans Firebase
- Crée automatiquement les Cloud Functions
- Synchronise Stripe ↔ Firestore
- Gère les webhooks automatiquement

### 3. Stripe (Paiements)

**Rôle** : Traitement des paiements et gestion des abonnements

**Composants** :

#### Stripe Dashboard
- Interface d'administration
- Création de produits et prix
- Consultation des paiements
- Configuration des webhooks

#### Stripe Checkout
- Page de paiement hébergée par Stripe
- Sécurisée et optimisée pour la conversion
- Gère le formulaire de carte bancaire
- Supporte 3D Secure et autres vérifications

#### Stripe API
- API RESTful pour les opérations
- Utilisée par l'extension Firebase
- Jamais appelée directement depuis Flutter

#### Webhooks Stripe
- Notifications d'événements
- Envoyées à Firebase Functions
- Déclenchent la synchronisation

## Flux de communication

### Flux 1 : Inscription utilisateur

```
1. Utilisateur saisit email/password dans Flutter
2. Flutter appelle AuthService.signUpWithEmail()
3. AuthService appelle Firebase Auth
4. Firebase Auth crée le compte
5. AuthService crée un document dans Firestore (users/{uid})
6. Flutter reçoit la confirmation
7. Utilisateur est connecté
```

### Flux 2 : Initiation d'un abonnement

```
1. Utilisateur clique "S'abonner" dans Flutter
2. Flutter appelle SubscriptionService.createCheckoutSession()
3. Service crée un document dans Firestore (checkout_sessions/{id})
4. Extension Firebase détecte le nouveau document (trigger)
5. Extension appelle l'API Stripe pour créer une session
6. Stripe retourne une URL de checkout
7. Extension écrit l'URL dans le document Firestore
8. Flutter lit l'URL depuis Firestore
9. Flutter ouvre l'URL dans le navigateur
10. Utilisateur paie sur la page Stripe
```

### Flux 3 : Synchronisation après paiement

```
1. Utilisateur valide le paiement sur Stripe Checkout
2. Stripe traite le paiement
3. Stripe crée l'abonnement
4. Stripe envoie un webhook à Firebase Functions
5. Extension reçoit le webhook
6. Extension crée/met à jour le document subscription dans Firestore
7. Flutter écoute Firestore via un Stream
8. Flutter détecte le changement
9. UI se met à jour automatiquement
10. Utilisateur voit "Abonnement actif"
```

### Flux 4 : Vérification du statut

```
1. Utilisateur ouvre l'application
2. Flutter appelle SubscriptionService.getSubscriptionStatus()
3. Service retourne un Stream sur Firestore
4. Flutter écoute users/{uid}/subscriptions
5. Firestore retourne les documents d'abonnement
6. Service parse le statut (active, canceled, etc.)
7. UI affiche le statut
8. UI débloque/bloque les fonctionnalités selon le statut
```

## Séparation des responsabilités

### Ce que fait Flutter

- Affichage de l'interface
- Interactions utilisateur
- Lecture des données Firestore
- Navigation entre écrans
- Gestion de l'état local

### Ce que fait Firebase

- Authentification des utilisateurs
- Stockage des données
- Règles de sécurité
- Hébergement des Cloud Functions
- Synchronisation temps réel

### Ce que fait Stripe

- Traitement des paiements
- Gestion des abonnements
- Facturation récurrente
- Gestion des cartes bancaires
- Envoi des webhooks

### Ce que fait l'Extension

- Pont entre Stripe et Firebase
- Génération des Cloud Functions
- Gestion des webhooks Stripe
- Synchronisation automatique
- Création des clients Stripe

## Avantages de cette architecture

### 1. Sécurité maximale
- Les clés secrètes restent côté serveur
- Firebase gère l'authentification
- Stripe gère le PCI compliance
- Aucune donnée sensible côté client

### 2. Pas de backend personnalisé
- Pas de serveur à maintenir
- Pas de code backend à écrire
- Scaling automatique
- Coûts optimisés

### 3. Temps réel
- Firestore pousse les changements
- Pas de polling nécessaire
- UI réactive instantanément
- Meilleure expérience utilisateur

### 4. Fiabilité
- Firebase : SLA 99.95%
- Stripe : SLA 99.99%
- Infrastructure gérée par des experts
- Redondance automatique

### 5. Évolutivité
- Supporte des millions d'utilisateurs
- Pas de goulot d'étranglement
- Coûts proportionnels à l'usage
- Pas de limite artificielle

## Limites de cette architecture

### 1. Coûts variables
- Firebase facture au nombre d'opérations
- Peut devenir cher avec beaucoup d'utilisateurs
- Nécessite de surveiller l'usage

### 2. Dépendance aux services tiers
- Si Firebase ou Stripe tombe, l'app ne fonctionne pas
- Impossible de migrer facilement
- Lock-in technologique

### 3. Personnalisation limitée
- L'extension a ses propres contraintes
- Difficile d'ajouter de la logique métier complexe
- Structure de données imposée

### 4. Débogage complexe
- Plusieurs systèmes imbriqués
- Logs dispersés entre Firebase et Stripe
- Temps de latence entre les systèmes

## Comparaison avec d'autres approches

### Approche 1 : Backend personnalisé (Node.js, Django, etc.)

**Avantages** :
- Contrôle total
- Logique métier complexe possible
- Personnalisation infinie

**Inconvénients** :
- Beaucoup de code à écrire
- Serveur à maintenir
- Scaling manuel
- Coûts d'hébergement

### Approche 2 : Intégration Stripe directe dans Flutter

**Avantages** :
- Simplicité apparente
- Moins de dépendances

**Inconvénients** :
- DANGEREUX : exposition des clés secrètes
- Non conforme PCI DSS
- Pas de synchronisation automatique
- Pas de webhooks sécurisés

### Approche 3 : Firebase + Extension (notre choix)

**Avantages** :
- Équilibre entre simplicité et sécurité
- Pas de backend à coder
- Synchronisation automatique
- Sécurité robuste

**Inconvénients** :
- Moins flexible qu'un backend personnalisé
- Dépendance à l'extension
- Coûts variables

## Bonnes pratiques architecturales appliquées

### 1. Séparation des préoccupations
- UI séparée de la logique métier
- Services dédiés par domaine
- Modèles de données isolés

### 2. Principe de moindre privilège
- Flutter ne peut pas modifier les abonnements Stripe
- Utilisateurs ne peuvent lire que leurs propres données
- Règles Firestore restrictives

### 3. Défense en profondeur
- Authentification Firebase
- Règles Firestore
- Validation côté serveur (Cloud Functions)
- Validation Stripe

### 4. Fail-safe
- Erreurs gérées à chaque niveau
- Messages d'erreur clairs
- Pas de crash si un service est indisponible

## Schéma de décision : qui fait quoi ?

```
Action demandée : Créer un compte
├─ Qui ? Flutter
└─ Comment ? Appel Firebase Auth

Action demandée : Stocker les données utilisateur
├─ Qui ? Firebase Firestore
└─ Comment ? Document dans collection users

Action demandée : Créer une session de paiement
├─ Qui ? Extension Firebase
└─ Comment ? Cloud Function appelant Stripe API

Action demandée : Traiter le paiement
├─ Qui ? Stripe
└─ Comment ? Stripe Checkout

Action demandée : Notifier le paiement réussi
├─ Qui ? Stripe
└─ Comment ? Webhook vers Firebase

Action demandée : Enregistrer l'abonnement
├─ Qui ? Extension Firebase
└─ Comment ? Écriture dans Firestore

Action demandée : Afficher le statut
├─ Qui ? Flutter
└─ Comment ? Lecture Firestore + Stream
```

## Prochaine étape

Maintenant que vous comprenez l'architecture globale, passez aux concepts clés : [Concepts clés](03_CONCEPTS.md)

