# 09 - Interface utilisateur

## Architecture des écrans

L'application comporte 5 écrans principaux organisés hiérarchiquement :

```
AuthGate (Routeur)
├── LoginScreen (si non connecté)
└── HomeScreen (si connecté)
    ├── PaywallScreen (modal)
    └── PremiumScreen (navigation)
```

## Pattern utilisé : Composition de widgets

Chaque écran est composé de petits widgets réutilisables :

```dart
HomeScreen
├─ AppBar
├─ StreamBuilder
│  └─ Column
│     ├─ _buildStatusCard()
│     ├─ _buildExplanationCard()
│     ├─ _buildPremiumButton()
│     └─ _buildUserInfo()
```

## AuthGate - Routeur d'authentification

### Fichier : `lib/screens/auth_gate.dart`

### Rôle

Afficher l'écran approprié selon l'état de connexion.

### Type

StatelessWidget (pas d'état local)

### Code complet

```dart
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // En attente
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Connecté → HomeScreen
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        // Non connecté → LoginScreen
        return const LoginScreen();
      },
    );
  }
}
```

### Navigation automatique

**Avantage :** Pas besoin de `Navigator.push()` manuel.

**Flux :**
```
1. Utilisateur se connecte
2. authStateChanges émet un User
3. StreamBuilder se reconstruit
4. HomeScreen s'affiche automatiquement
```

## LoginScreen - Connexion et inscription

### Fichier : `lib/screens/login_screen.dart`

### Type

StatefulWidget (gère l'état du formulaire)

### État local

```dart
_emailController      // Contrôleur du champ email
_passwordController   // Contrôleur du champ mot de passe
_formKey             // Clé du formulaire (validation)
_isLoading           // Indicateur de chargement
_isSignUpMode        // Mode inscription ou connexion
```

### Structure visuelle

```
Scaffold
└─ AppBar ("Authentification")
└─ Body (SingleChildScrollView)
   └─ Form
      ├─ Icon (lock)
      ├─ Titre
      ├─ TextFormField (email)
      ├─ TextFormField (password)
      ├─ ElevatedButton (submit)
      └─ TextButton (toggle mode)
```

### Validation du formulaire

```dart
// Validation email
validator: (value) {
  if (value == null || value.isEmpty) {
    return 'Veuillez entrer votre email';
  }
  if (!value.contains('@')) {
    return 'Email invalide';
  }
  return null;
}

// Validation password
validator: (value) {
  if (value == null || value.isEmpty) {
    return 'Veuillez entrer votre mot de passe';
  }
  if (value.length < 6) {
    return 'Le mot de passe doit contenir au moins 6 caractères';
  }
  return null;
}
```

### Gestion de la soumission

```dart
Future<void> _handleSubmit() async {
  // Valider le formulaire
  if (!_formKey.currentState!.validate()) {
    return;
  }

  // Afficher le chargement
  setState(() => _isLoading = true);

  try {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    if (_isSignUpMode) {
      await authService.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } else {
      await authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }
  } catch (e) {
    // Afficher l'erreur
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    // Masquer le chargement
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
```

### Nettoyage des ressources

```dart
@override
void dispose() {
  _emailController.dispose();
  _passwordController.dispose();
  super.dispose();
}
```

⚠️ **Important :** Toujours disposer les contrôleurs pour éviter les fuites mémoire.

## HomeScreen - Écran principal

### Fichier : `lib/screens/home_screen.dart`

### Type

StatelessWidget

### Cœur : StreamBuilder sur le statut d'abonnement

```dart
StreamBuilder<SubscriptionStatus>(
  stream: subscriptionService.getSubscriptionStatus(),
  builder: (context, snapshot) {
    // Chargement
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    // Erreur
    if (snapshot.hasError) {
      return Center(child: Text('Erreur : ${snapshot.error}'));
    }

    // Données
    final status = snapshot.data ?? SubscriptionStatus.none;
    return _buildContent(context, status);
  },
)
```

### Widgets composant l'écran

#### 1. Carte de statut

```dart
Widget _buildStatusCard(BuildContext context, SubscriptionStatus status) {
  final color = status.hasAccess ? Colors.green : Colors.orange;
  final icon = status.hasAccess ? Icons.check_circle : Icons.info;

  return Card(
    color: color.withOpacity(0.1),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Statut d\'abonnement'),
                Text(
                  status.description,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
```

#### 2. Carte d'explication pédagogique

Affiche des explications différentes selon le statut :

```dart
Widget _buildExplanationCard(BuildContext context, SubscriptionStatus status) {
  String explanation;
  
  switch (status) {
    case SubscriptionStatus.none:
      explanation = 'Vous n\'avez pas d\'abonnement actif...';
      break;
    case SubscriptionStatus.active:
      explanation = 'Votre abonnement est actif !...';
      break;
    // ... autres cas
  }

  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.amber),
              Text('Comprendre'),
            ],
          ),
          Text(explanation),
        ],
      ),
    ),
  );
}
```

#### 3. Bouton conditionnel

Affiche un bouton différent selon le statut :

```dart
Widget _buildPremiumButton(BuildContext context, SubscriptionStatus status) {
  if (status.hasAccess) {
    // Utilisateur premium → Accéder aux fonctionnalités
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PremiumScreen()),
        );
      },
      icon: const Icon(Icons.star),
      label: const Text('Accéder aux fonctionnalités Premium'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }

  // Utilisateur gratuit → Débloquer
  return ElevatedButton.icon(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      );
    },
    icon: const Icon(Icons.lock),
    label: const Text('Débloquer les fonctionnalités Premium'),
  );
}
```

## PaywallScreen - Écran de vente

### Fichier : `lib/screens/paywall_screen.dart`

### Type

StatefulWidget (gère le chargement)

### Structure visuelle

```
Scaffold
└─ AppBar ("Passer à Premium")
└─ Body (ScrollView)
   ├─ Icon workspace_premium (100px)
   ├─ Titre "Devenez Premium"
   ├─ Liste des avantages (3 cartes)
   │  ├─ Accès illimité
   │  ├─ Support prioritaire
   │  └─ Mises à jour anticipées
   ├─ Carte de prix (19 €/mois)
   ├─ Bouton "S'abonner maintenant"
   └─ Note pédagogique (carte de test)
```

### Gestion du clic S'abonner

```dart
Future<void> _handleSubscribe() async {
  setState(() => _isLoading = true);

  try {
    final subscriptionService = Provider.of<SubscriptionService>(
      context, 
      listen: false
    );
    
    // Créer la session Checkout
    await subscriptionService.createCheckoutSession();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Redirection vers le paiement...'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
```

### Note pédagogique

Une carte qui aide l'utilisateur à tester :

```dart
Card(
  color: Colors.amber.shade50,
  child: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      children: [
        Row(
          children: [
            Icon(Icons.info_outline, color: Colors.amber),
            Text('Note de développement'),
          ],
        ),
        const Text(
          'En mode test Stripe, utilisez la carte :\n'
          '• Numéro : 4242 4242 4242 4242\n'
          '• Date : n\'importe quelle date future\n'
          '• CVC : n\'importe quel code à 3 chiffres',
        ),
      ],
    ),
  ),
)
```

## PremiumScreen - Écran premium

### Fichier : `lib/screens/premium_screen.dart`

### Type

StatelessWidget

### Structure

```
Scaffold
└─ AppBar ("Espace Premium", couleur: amber)
└─ Body (ScrollView)
   ├─ Badge premium (icône 80px)
   ├─ Titre "Bienvenue dans l'espace Premium"
   ├─ 3 fonctionnalités fictives
   │  ├─ Analyses avancées
   │  ├─ Stockage illimité
   │  └─ Performances accrues
   ├─ Carte pédagogique (explique le flux)
   └─ Bouton "Gérer mon abonnement"
```

### Bouton portail client

```dart
OutlinedButton.icon(
  onPressed: () => _openCustomerPortal(context),
  icon: const Icon(Icons.settings),
  label: const Text('Gérer mon abonnement'),
)

Future<void> _openCustomerPortal(BuildContext context) async {
  try {
    final subscriptionService = Provider.of<SubscriptionService>(
      context, 
      listen: false
    );
    
    await subscriptionService.createPortalSession();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ouverture du portail de gestion...'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

## Bonnes pratiques d'UI appliquées

### 1. Indicateurs de chargement

Toujours afficher un `CircularProgressIndicator` pendant les opérations asynchrones.

```dart
_isLoading
  ? const CircularProgressIndicator()
  : Text('Bouton')
```

### 2. Vérification du contexte monté

Avant d'utiliser `context` après un `await`, vérifier `mounted` :

```dart
await someAsyncOperation();
if (mounted) {  // ← Important
  setState(() => ...);
}
```

### 3. Messages utilisateur clairs

```dart
// BON
SnackBar(content: Text('Erreur : ${e.toString()}'))

// MAUVAIS
SnackBar(content: Text('Erreur'))
```

### 4. Désactivation des boutons pendant le chargement

```dart
ElevatedButton(
  onPressed: _isLoading ? null : _handleSubmit,  // null = désactivé
  child: _isLoading
    ? CircularProgressIndicator()
    : Text('Soumettre'),
)
```

### 5. Feedback visuel immédiat

Changer l'état avant l'opération :

```dart
setState(() => _isLoading = true);  // ← Immédiat
await longOperation();
setState(() => _isLoading = false);
```

## Navigation

L'application utilise deux types de navigation :

### Navigation automatique (AuthGate)

```dart
StreamBuilder gère automatiquement la navigation selon l'état d'auth
```

### Navigation manuelle

```dart
// Push (ajouter une route)
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const PremiumScreen()),
);

// Pop (retour arrière)
Navigator.pop(context);
```

## Thème

Défini dans `main.dart` :

```dart
MaterialApp(
  theme: ThemeData(
    primarySwatch: Colors.blue,
    useMaterial3: true,
  ),
)
```

Les écrans utilisent les couleurs du thème :

```dart
Theme.of(context).textTheme.headlineMedium
Theme.of(context).colorScheme.primary
```

## Prochaine étape

Maintenant que vous comprenez l'interface, explorez les flux de données : [Flux de données complet](10_FLUX_DONNEES.md)

