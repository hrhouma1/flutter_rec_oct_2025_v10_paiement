# 07 - Structure du projet

## Arborescence complète

```
flutter_stripe_subscriptions_learning/
│
├── lib/                              ← Code source Flutter
│   ├── main.dart                     ← Point d'entrée de l'application
│   ├── firebase_options.dart         ← Configuration Firebase (généré)
│   │
│   ├── models/                       ← Modèles de données
│   │   └── subscription_status.dart  ← Énumération des statuts d'abonnement
│   │
│   ├── services/                     ← Logique métier
│   │   ├── auth_service.dart         ← Service d'authentification
│   │   └── subscription_service.dart ← Service de gestion des abonnements
│   │
│   └── screens/                      ← Interface utilisateur
│       ├── auth_gate.dart            ← Routeur d'authentification
│       ├── login_screen.dart         ← Écran de connexion/inscription
│       ├── home_screen.dart          ← Écran principal
│       ├── paywall_screen.dart       ← Écran de vente
│       └── premium_screen.dart       ← Écran des fonctionnalités premium
│
├── documentation/                    ← Documentation complète
│   ├── 00_SOMMAIRE.md
│   ├── 01_INTRODUCTION.md
│   └── ...
│
├── pubspec.yaml                      ← Dépendances du projet
├── README.md                         ← Guide principal
├── GUIDE_INSTALLATION.md             ← Guide d'installation détaillé
└── .gitignore                        ← Fichiers ignorés par Git
```

## Organisation par responsabilité

### Séparation en 3 couches

```
┌─────────────────────────────────────────┐
│           PRÉSENTATION                  │
│         (screens/)                      │
│  - Widgets                              │
│  - Navigation                           │
│  - Affichage                            │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│           LOGIQUE MÉTIER                │
│         (services/)                     │
│  - Appels API                           │
│  - Transformation de données            │
│  - Règles métier                        │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│           DONNÉES                       │
│         (models/)                       │
│  - Structures de données                │
│  - Énumérations                         │
│  - Classes de données                   │
└─────────────────────────────────────────┘
```

## Analyse fichier par fichier

### 1. main.dart (Point d'entrée)

**Rôle** : Initialise l'application et configure les providers

**Responsabilités** :
- Initialiser Firebase
- Configurer les services globaux avec Provider
- Définir le thème de l'application
- Définir l'écran initial

**Dépendances** :
- Firebase Core
- Provider
- Tous les services et écrans

**Flux d'exécution** :
```
1. main() est appelé
2. Firebase est initialisé
3. runApp() lance MyApp
4. MultiProvider injecte les services
5. MaterialApp crée l'application
6. AuthGate est affiché
```

**Code clé** :
```dart
// Ligne 12-16 : Initialisation Firebase
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);

// Ligne 28-35 : Injection des services
MultiProvider(
  providers: [
    Provider<AuthService>(create: (_) => AuthService()),
    Provider<SubscriptionService>(create: (_) => SubscriptionService()),
  ],
  child: MaterialApp(...),
)
```

### 2. firebase_options.dart (Configuration)

**Rôle** : Contient les clés de configuration Firebase

**Généré par** : FlutterFire CLI (`flutterfire configure`)

**Contenu** :
- API Keys (publiques, pas de problème de sécurité)
- Project ID
- App ID
- Configuration par plateforme (Web, Android, iOS)

**Important** :
- Ce fichier est ignoré par Git (dans `.gitignore`)
- Chaque développeur doit le générer
- Contient des valeurs différentes pour chaque projet

### 3. models/subscription_status.dart (Modèle)

**Rôle** : Définit les états possibles d'un abonnement

**Type** : Énumération (Enum)

**Valeurs** :
```dart
enum SubscriptionStatus {
  none,      // Pas d'abonnement
  active,    // Abonnement actif
  pastDue,   // Paiement en retard
  canceled,  // Annulé
}
```

**Extension** :
```dart
extension SubscriptionStatusExtension on SubscriptionStatus {
  // Texte lisible pour l'UI
  String get description { ... }
  
  // Détermine si l'utilisateur a accès au premium
  bool get hasAccess { ... }
}
```

**Pourquoi une énumération ?**
- Type-safe : impossible d'avoir une valeur invalide
- Auto-complétion dans l'IDE
- Facile à maintenir
- Meilleur que des strings

### 4. services/auth_service.dart (Authentification)

**Rôle** : Gère toute la logique d'authentification

**Responsabilités** :
- Inscription (signUpWithEmail)
- Connexion (signInWithEmail)
- Déconnexion (signOut)
- Création du document utilisateur dans Firestore

**Dépendances** :
- firebase_auth
- cloud_firestore

**Méthodes publiques** :
```dart
Stream<User?> get authStateChanges   // Stream de l'état de connexion
User? get currentUser                 // Utilisateur actuel
Future signUpWithEmail(...)           // Inscription
Future signInWithEmail(...)           // Connexion
Future signOut()                      // Déconnexion
```

**Méthodes privées** :
```dart
Future _createUserDocument(User user) // Création document Firestore
```

**Pattern de conception** : Service singleton

**Points d'attention** :
- Gestion des erreurs avec try-catch
- Création automatique du document Firestore
- Pas de logique UI dans ce fichier

### 5. services/subscription_service.dart (Abonnements)

**Rôle** : Gère toute la logique des abonnements Stripe

**Responsabilités** :
- Lire le statut d'abonnement depuis Firestore
- Créer des sessions Stripe Checkout
- Ouvrir le portail client Stripe
- Parser les données d'abonnement

**Dépendances** :
- cloud_firestore
- firebase_auth
- url_launcher

**Configuration** :
```dart
// Ligne 20 : ID du prix Stripe (à configurer)
static const String monthlyPriceId = 'price_VOTRE_PRICE_ID_ICI';
```

**Méthodes publiques** :
```dart
Stream<SubscriptionStatus> getSubscriptionStatus()  // Statut en temps réel
Future createCheckoutSession()                       // Créer session paiement
Future createPortalSession()                         // Ouvrir portail client
```

**Méthodes privées** :
```dart
SubscriptionStatus _parseSubscriptionStatus(...)    // Parser statut
Future _waitForCheckoutUrl(...)                     // Attendre URL checkout
Future _launchCheckoutUrl(...)                      // Ouvrir URL
Future _waitForPortalUrl(...)                       // Attendre URL portail
```

**Pattern de conception** : Service singleton

**Logique complexe** :
- Attend que l'extension Firebase ajoute l'URL (polling via Stream)
- Gère les timeouts
- Parse les statuts Stripe en énumération locale

### 6. screens/auth_gate.dart (Routeur)

**Rôle** : Affiche LoginScreen ou HomeScreen selon l'état de connexion

**Type** : StatelessWidget

**Logique** :
```dart
StreamBuilder<User?>(
  stream: authService.authStateChanges,
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return HomeScreen();  // Utilisateur connecté
    }
    return LoginScreen();   // Utilisateur non connecté
  },
)
```

**Pourquoi ce pattern ?**
- Navigation automatique à la connexion/déconnexion
- Pas de gestion manuelle de routes
- Réactivité en temps réel

### 7. screens/login_screen.dart (Connexion)

**Rôle** : Interface de connexion et d'inscription

**Type** : StatefulWidget (gère l'état du formulaire)

**État local** :
```dart
_emailController       // Contrôleur du champ email
_passwordController    // Contrôleur du champ mot de passe
_formKey              // Clé du formulaire pour validation
_isLoading            // Indicateur de chargement
_isSignUpMode         // Mode inscription ou connexion
```

**Validation** :
```dart
// Ligne 81-91 : Validation email
validator: (value) {
  if (value == null || value.isEmpty) {
    return 'Veuillez entrer votre email';
  }
  if (!value.contains('@')) {
    return 'Email invalide';
  }
  return null;
}
```

**Gestion des erreurs** :
```dart
// Ligne 37-45 : Affichage des erreurs avec SnackBar
catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Erreur : ${e.toString()}'),
      backgroundColor: Colors.red,
    ),
  );
}
```

**Bonnes pratiques appliquées** :
- Validation côté client avant envoi
- Indicateurs de chargement
- Messages d'erreur clairs
- Nettoyage des contrôleurs (dispose)

### 8. screens/home_screen.dart (Écran principal)

**Rôle** : Affiche le statut d'abonnement et permet la navigation

**Type** : StatelessWidget

**Structure** :
```dart
Scaffold
 └─ AppBar (avec bouton déconnexion)
 └─ Body
     └─ StreamBuilder<SubscriptionStatus>
         ├─ Carte de statut
         ├─ Carte d'explication
         ├─ Bouton Premium/Paywall
         └─ Informations utilisateur
```

**Logique conditionnelle** :
```dart
// Ligne 119-135 : Affichage conditionnel du bouton
if (status.hasAccess) {
  // Afficher "Accéder au Premium"
} else {
  // Afficher "Débloquer le Premium"
}
```

**Points pédagogiques** :
- Cartes explicatives qui enseignent le fonctionnement
- Statut affiché en temps réel
- Code commenté pour l'apprentissage

### 9. screens/paywall_screen.dart (Vente)

**Rôle** : Présenter l'offre et déclencher le paiement

**Type** : StatefulWidget (gère le chargement)

**État local** :
```dart
_isLoading  // Indicateur de chargement pendant la création de session
```

**Structure** :
```dart
Scaffold
 └─ AppBar
 └─ Body (ScrollView)
     ├─ Icône premium
     ├─ Titre
     ├─ Liste des avantages (3 cartes)
     ├─ Carte de prix
     ├─ Bouton "S'abonner"
     └─ Note pédagogique (carte de test)
```

**Gestion du clic** :
```dart
// Ligne 16-39 : Création de la session Checkout
Future<void> _handleSubscribe() async {
  setState(() => _isLoading = true);
  
  try {
    await subscriptionService.createCheckoutSession();
    // Succès : afficher message
  } catch (e) {
    // Erreur : afficher message d'erreur
  } finally {
    setState(() => _isLoading = false);
  }
}
```

**Note pédagogique** :
- Carte explicative sur les cartes de test Stripe
- Aide l'utilisateur à tester sans stress

### 10. screens/premium_screen.dart (Premium)

**Rôle** : Afficher les fonctionnalités premium (démonstration)

**Type** : StatelessWidget

**Contenu** :
- Badge premium
- 3 fonctionnalités fictives (avec icônes et descriptions)
- Carte pédagogique expliquant le flux de données
- Bouton pour ouvrir le portail client Stripe

**Fonctionnalité clé** :
```dart
// Ligne 119-142 : Ouverture du portail client
Future<void> _openCustomerPortal(BuildContext context) async {
  try {
    await subscriptionService.createPortalSession();
    // Le portail s'ouvre dans le navigateur
  } catch (e) {
    // Afficher erreur
  }
}
```

**Portail client Stripe** :
Permet à l'utilisateur de :
- Annuler l'abonnement
- Changer de carte bancaire
- Voir les factures
- Changer de plan

## Principes de conception appliqués

### 1. Séparation des préoccupations (SoC)

**Principe** : Chaque module a une responsabilité unique

**Application** :
- `services/` : Logique métier uniquement
- `screens/` : UI et interactions uniquement
- `models/` : Structures de données uniquement

**Avantage** :
- Code facile à tester
- Modifications isolées
- Réutilisabilité

### 2. Dependency Injection avec Provider

**Principe** : Les dépendances sont injectées, pas instanciées

**Application** :
```dart
// Injection au niveau racine
MultiProvider(
  providers: [
    Provider<AuthService>(create: (_) => AuthService()),
  ],
)

// Récupération n'importe où
final authService = Provider.of<AuthService>(context);
```

**Avantage** :
- Services partagés dans toute l'app
- Facile à mocker pour les tests
- Pas de singletons statiques

### 3. Composition sur héritage

**Principe** : Préférer la composition à l'héritage

**Application** :
```dart
// Pas d'héritage complexe
// Composition de widgets simples
Column(
  children: [
    _buildStatusCard(),
    _buildExplanationCard(),
    _buildPremiumButton(),
  ],
)
```

### 4. Immutabilité

**Principe** : Les widgets sont immutables

**Application** :
```dart
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});  // Constructeur const
  // Pas de champs mutables
}
```

**Avantage** :
- Prédictibilité
- Performance (Flutter peut optimiser)
- Pas de bugs liés aux mutations

### 5. Gestion explicite des erreurs

**Principe** : Toutes les erreurs sont gérées explicitement

**Application** :
```dart
try {
  await service.doSomething();
} catch (e) {
  // Afficher message utilisateur
  // Logger l'erreur
  // Ne jamais laisser l'exception non gérée
}
```

## Conventions de nommage

### Fichiers

| Type | Convention | Exemple |
|------|------------|---------|
| Écrans | `*_screen.dart` | `login_screen.dart` |
| Services | `*_service.dart` | `auth_service.dart` |
| Modèles | `*.dart` (nom du modèle) | `subscription_status.dart` |

### Classes

| Type | Convention | Exemple |
|------|------------|---------|
| Widgets | PascalCase + suffixe | `LoginScreen`, `HomeScreen` |
| Services | PascalCase + Service | `AuthService` |
| Modèles | PascalCase | `SubscriptionStatus` |

### Variables

| Type | Convention | Exemple |
|------|------------|---------|
| Privées | `_camelCase` | `_emailController` |
| Publiques | `camelCase` | `currentUser` |
| Constantes | `camelCase` | `monthlyPriceId` |

### Méthodes

| Type | Convention | Exemple |
|------|------------|---------|
| Privées | `_camelCase` | `_createUserDocument()` |
| Publiques | `camelCase` | `signInWithEmail()` |
| Build | `_build*` | `_buildStatusCard()` |
| Handle | `_handle*` | `_handleSubscribe()` |

## Gestion des dépendances (pubspec.yaml)

### Dépendances principales

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^3.6.0          # Core Firebase
  firebase_auth: ^5.3.1          # Authentification
  cloud_firestore: ^5.4.4        # Base de données
  
  # Utilitaires
  url_launcher: ^6.3.1           # Ouvrir URLs (Stripe)
  provider: ^6.1.2               # Gestion d'état
```

### Pourquoi ces packages ?

**firebase_core** : Obligatoire pour tout usage de Firebase

**firebase_auth** : Gère l'authentification sans code backend

**cloud_firestore** : Base de données temps réel NoSQL

**url_launcher** : Ouvre les URLs Stripe Checkout dans le navigateur

**provider** : Pattern simple pour partager des données entre widgets

### Packages NON utilisés (volontairement)

| Package | Pourquoi pas |
|---------|--------------|
| `flutter_stripe` | Pas besoin, tout passe par l'extension Firebase |
| `bloc/riverpod` | Provider suffit pour cette application simple |
| `dio/http` | Pas d'appels API directs depuis Flutter |
| `shared_preferences` | Firebase Auth gère la session |

## Taille du code

| Fichier | Lignes | Complexité |
|---------|--------|------------|
| main.dart | ~50 | Faible |
| firebase_options.dart | ~80 | Faible (généré) |
| subscription_status.dart | ~40 | Faible |
| auth_service.dart | ~70 | Moyenne |
| subscription_service.dart | ~150 | Élevée |
| auth_gate.dart | ~40 | Faible |
| login_screen.dart | ~150 | Moyenne |
| home_screen.dart | ~180 | Moyenne |
| paywall_screen.dart | ~160 | Moyenne |
| premium_screen.dart | ~160 | Moyenne |
| **Total** | **~1080** | **Gérable** |

## Prochaine étape

Maintenant que vous comprenez la structure du code, explorez les services en détail : [Services et logique métier](08_SERVICES.md)

