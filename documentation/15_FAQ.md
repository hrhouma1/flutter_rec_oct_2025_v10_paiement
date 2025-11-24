# 15 - FAQ et problèmes courants

## Questions générales

### Q1 : Puis-je utiliser ce code en production ?

**Réponse** : Oui, avec quelques adaptations :

1. **Obligatoire** :
   - Passer Stripe en mode live (clé `sk_live_...`)
   - Configurer des vraies URLs de retour
   - Activer les règles Firestore en production
   - Tester exhaustivement

2. **Recommandé** :
   - Ajouter des analytics
   - Implémenter un vrai contenu premium
   - Améliorer le design
   - Ajouter de la gestion d'erreurs avancée
   - Mettre en place du monitoring

3. **À considérer** :
   - Conditions générales de vente
   - Politique de remboursement
   - Gestion du support client
   - Conformité RGPD

### Q2 : Combien ça coûte en production ?

**Firebase** (pour 1000 utilisateurs actifs/mois) :
- Auth : Gratuit
- Firestore lectures : ~50 000/mois = ~0,09 €
- Functions : ~100 000 appels/mois = ~0,04 €
- **Total Firebase : ~0,15 € (négligeable)**

**Stripe** (pour 100 abonnés à 19 €/mois) :
- Revenu brut : 1 900 €
- Frais Stripe (1,4% + 0,25 €) : ~31 €
- **Net : ~1 869 €**

**Conclusion** : Les coûts Firebase sont négligeables. Stripe prend ~1,6% du revenu.

### Q3 : Dois-je utiliser l'extension ou coder mon backend ?

**Utilisez l'extension si** :
- Vous débutez avec Stripe
- Vous voulez un déploiement rapide
- Vous n'avez pas de logique métier complexe
- Vous voulez minimiser la maintenance

**Codez votre backend si** :
- Vous avez des besoins très spécifiques
- Vous voulez un contrôle total
- Vous avez déjà une infrastructure backend
- Vous voulez gérer des cas métier complexes

Pour 90% des cas, **l'extension suffit largement**.

### Q4 : L'extension est-elle maintenue ?

**Oui**, l'extension "Run Payments with Stripe" est :
- Maintenue par Stripe (l'entreprise)
- Mise à jour régulièrement
- Utilisée en production par des milliers d'apps
- Open source (vous pouvez voir le code)

Lien : https://github.com/stripe/stripe-firebase-extensions

### Q5 : Puis-je avoir plusieurs plans tarifaires ?

**Oui**, c'est très simple :

1. Créer plusieurs prix dans Stripe :
   ```
   Plan Basic : price_basic_monthly
   Plan Pro : price_pro_monthly
   Plan Enterprise : price_enterprise_monthly
   ```

2. Dans Flutter, stocker les IDs :
   ```dart
   static const String basicPriceId = 'price_basic_monthly';
   static const String proPriceId = 'price_pro_monthly';
   static const String enterprisePriceId = 'price_enterprise_monthly';
   ```

3. Passer le bon ID lors de la création de session :
   ```dart
   await _firestore.collection('checkout_sessions').add({
     'price': selectedPriceId, // Celui choisi par l'utilisateur
     ...
   });
   ```

4. Adapter la logique de vérification :
   ```dart
   bool get hasBasicAccess => status == 'active' && priceId == basicPriceId;
   bool get hasProAccess => status == 'active' && priceId == proPriceId;
   ```

## Problèmes d'installation

### P1 : "Firebase not initialized"

**Erreur complète** :
```
[core/no-app] No Firebase App '[DEFAULT]' has been created
```

**Causes possibles** :
1. `Firebase.initializeApp()` n'a pas été appelé
2. `firebase_options.dart` n'existe pas
3. Problème d'initialisation asynchrone

**Solution** :
```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // ← Important !
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
```

**Vérifications** :
```bash
# Vérifier que le fichier existe
ls lib/firebase_options.dart

# Si absent, le générer
flutterfire configure
```

### P2 : "FlutterFire CLI not found"

**Erreur** :
```
'flutterfire' is not recognized as an internal or external command
```

**Solution** :
```bash
# Installer FlutterFire CLI
dart pub global activate flutterfire_cli

# Ajouter au PATH (si nécessaire)
# Windows : Ajouter %USERPROFILE%\AppData\Local\Pub\Cache\bin au PATH
# Mac/Linux : Ajouter $HOME/.pub-cache/bin au PATH

# Vérifier l'installation
flutterfire --version
```

### P3 : Erreurs de compilation après `flutter pub get`

**Erreur** :
```
Because firebase_core >=3.6.0 depends on firebase_core_platform_interface...
```

**Solution** :
```bash
# Nettoyer le projet
flutter clean

# Récupérer les dépendances à nouveau
flutter pub get

# Si le problème persiste, mettre à jour Flutter
flutter upgrade
```

### P4 : "Règles Firestore refusent l'accès"

**Erreur dans les logs** :
```
PERMISSION_DENIED: Missing or insufficient permissions
```

**Cause** : Les règles Firestore sont trop restrictives

**Solution** :
```javascript
// Firestore Rules (mode développement)
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      match /{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

**Attention** : En production, resserrez ces règles !

## Problèmes avec Stripe

### P5 : L'URL de checkout ne se génère pas

**Symptôme** : Le bouton "S'abonner" charge indéfiniment

**Causes possibles** :

1. **Extension non installée**
   - Vérifier dans Firebase Console > Extensions
   - Réinstaller si nécessaire

2. **Mauvais Price ID**
   ```dart
   // Vérifier dans subscription_service.dart ligne 20
   static const String monthlyPriceId = 'price_xxxxxxxxxxxxx';
   // Doit correspondre à un prix existant dans Stripe Dashboard
   ```

3. **Cloud Functions pas déployées**
   - Aller dans Firebase Console > Functions
   - Vérifier que les fonctions existent
   - Attendre 5 minutes après l'installation de l'extension

4. **Clé Stripe invalide**
   - Vérifier dans Firebase Console > Extensions > Configuration
   - La clé doit commencer par `sk_test_` (mode test) ou `sk_live_` (production)
   - Régénérer une clé si nécessaire dans Stripe Dashboard

**Débogage** :
```dart
// Dans subscription_service.dart, ajouter des logs
print('Creating checkout session for price: $monthlyPriceId');
print('User ID: $userId');

// Après création du document
print('Document created: ${docRef.id}');

// Dans _waitForCheckoutUrl
docRef.snapshots().listen((snapshot) {
  print('Document data: ${snapshot.data()}');
});
```

### P6 : Le paiement ne se synchronise pas dans Firestore

**Symptôme** : Paiement réussi sur Stripe, mais statut reste "Aucun abonnement" dans l'app

**Causes possibles** :

1. **Webhooks non configurés**
   - Aller dans Stripe Dashboard > Developers > Webhooks
   - Vérifier qu'un endpoint existe (créé par l'extension)
   - Format : `https://us-central1-PROJET.cloudfunctions.net/ext-*-handleWebhookEvents`

2. **Webhook échoue**
   - Dans Stripe Dashboard > Webhooks > Cliquer sur l'endpoint
   - Onglet "Logs" : vérifier s'il y a des erreurs
   - Code de réponse attendu : 200

3. **Lien Customer non fait**
   - L'extension doit créer un client Stripe
   - Vérifier dans Firestore : `users/{uid}` doit avoir un champ `stripeId`
   - Si absent, supprimer le document et recréer le compte

**Solution** :
```bash
# Réinstaller l'extension
# Firebase Console > Extensions > ... > Uninstall
# Puis réinstaller avec les bons paramètres

# Paramètre important : "Customer details collection" = "users"
```

### P7 : "No such price" dans les logs

**Erreur dans Cloud Functions** :
```
Error: No such price: 'price_VOTRE_PRICE_ID_ICI'
```

**Cause** : Le Price ID dans le code ne correspond pas à un prix existant dans Stripe

**Solution** :
1. Aller dans Stripe Dashboard > Products
2. Cliquer sur votre produit
3. Copier le Price ID (commence par `price_`)
4. Remplacer dans `lib/services/subscription_service.dart` ligne 20

**Vérification** :
```dart
// Le Price ID doit ressembler à :
static const String monthlyPriceId = 'price_1OAbCdEfGhIjKlMn';
// PAS : 'price_VOTRE_PRICE_ID_ICI' (c'est un placeholder)
```

### P8 : "Test cards not working"

**Symptôme** : La carte de test `4242 4242 4242 4242` est refusée

**Cause** : Stripe n'est pas en mode test

**Solution** :
1. Vérifier le toggle "Test mode" en haut à droite du Stripe Dashboard
2. Vérifier que la clé API commence par `sk_test_` (pas `sk_live_`)
3. Réinstaller l'extension avec la bonne clé si nécessaire

**Cartes de test Stripe** :
| Numéro | Résultat |
|--------|----------|
| `4242 4242 4242 4242` | Succès |
| `4000 0025 0000 3155` | Nécessite 3D Secure |
| `4000 0000 0000 9995` | Refusée (fonds insuffisants) |
| `4000 0000 0000 0002` | Refusée (carte déclinée) |

## Problèmes Flutter

### P9 : "Provider not found"

**Erreur** :
```
Error: Could not find the correct Provider<AuthService> above this Widget
```

**Cause** : Le widget essaie d'accéder au service avant qu'il soit fourni

**Solution** :
```dart
// Vérifier que MultiProvider est au-dessus dans l'arbre
void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
      ],
      child: MyApp(), // ← Tous les enfants ont accès au provider
    ),
  );
}

// Dans les widgets enfants, utiliser :
final authService = Provider.of<AuthService>(context, listen: false);
```

### P10 : "setState() called after dispose()"

**Erreur complète** :
```
setState() called after dispose(): _LoginScreenState#abc123
```

**Cause** : Un appel asynchrone se termine après que le widget soit détruit

**Solution** :
```dart
Future<void> _handleSubmit() async {
  // ...
  try {
    await authService.signIn(...);
  } finally {
    // Vérifier que le widget est toujours monté
    if (mounted) {  // ← Important
      setState(() => _isLoading = false);
    }
  }
}
```

### P11 : "url_launcher can't launch URL"

**Erreur** :
```
PlatformException: ACTIVITY_NOT_FOUND
```

**Cause** : Permissions manquantes ou URL mal formatée

**Solution Android** :
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest>
  <application>
    <!-- Ajouter ces lignes -->
    <queries>
      <intent>
        <action android:name="android.intent.action.VIEW" />
        <data android:scheme="https" />
      </intent>
    </queries>
  </application>
</manifest>
```

**Solution iOS** :
```xml
<!-- ios/Runner/Info.plist -->
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>https</string>
  <string>http</string>
</array>
```

**Vérifier l'URL** :
```dart
// L'URL doit être bien formée
final uri = Uri.parse(url); // Ne doit pas throw
print('URL: $url'); // Doit commencer par https://
```

## Problèmes de logique métier

### P12 : Le statut d'abonnement ne se met pas à jour

**Symptôme** : L'app affiche "Aucun abonnement" alors que l'abonnement existe dans Firestore

**Débogage** :

1. **Vérifier Firestore** :
   - Firebase Console > Firestore
   - Collection `users/{uid}/subscriptions`
   - Le document doit exister avec `status: "active"`

2. **Vérifier le Stream** :
   ```dart
   // Dans home_screen.dart, ajouter :
   StreamBuilder<SubscriptionStatus>(
     stream: subscriptionService.getSubscriptionStatus(),
     builder: (context, snapshot) {
       print('Stream state: ${snapshot.connectionState}');
       print('Has data: ${snapshot.hasData}');
       print('Data: ${snapshot.data}');
       // ...
     },
   )
   ```

3. **Vérifier le parsing** :
   ```dart
   // Dans subscription_service.dart
   SubscriptionStatus _parseSubscriptionStatus(Map<String, dynamic> data) {
     print('Parsing data: $data'); // ← Ajouter ce log
     final status = data['status'] as String?;
     print('Status: $status');
     // ...
   }
   ```

**Causes fréquentes** :
- Collection vide (pas d'abonnement créé)
- Champ `status` manquant ou mal orthographié
- Règles Firestore bloquent la lecture

### P13 : Plusieurs abonnements simultanés

**Symptôme** : L'utilisateur a plusieurs documents dans `subscriptions`

**Explication** : 
- Stripe permet plusieurs abonnements par client
- Notre code prend le premier document trouvé

**Solution 1 : Prendre le plus récent** :
```dart
Stream<SubscriptionStatus> getSubscriptionStatus() {
  return _firestore
    .collection('users/$userId/subscriptions')
    .orderBy('created', descending: true) // ← Tri par date
    .limit(1)                               // ← Prendre le plus récent
    .snapshots()
    .map((snapshot) {
      if (snapshot.docs.isEmpty) return SubscriptionStatus.none;
      return _parseSubscriptionStatus(snapshot.docs.first.data());
    });
}
```

**Solution 2 : Filtrer par statut actif** :
```dart
Stream<SubscriptionStatus> getSubscriptionStatus() {
  return _firestore
    .collection('users/$userId/subscriptions')
    .where('status', whereIn: ['active', 'trialing']) // ← Filtrer
    .snapshots()
    .map((snapshot) {
      if (snapshot.docs.isEmpty) return SubscriptionStatus.none;
      return _parseSubscriptionStatus(snapshot.docs.first.data());
    });
}
```

### P14 : Abonnement annulé mais toujours actif

**Symptôme** : L'abonnement a `status: "canceled"` mais l'utilisateur a encore accès

**Explication** : C'est normal !

Stripe a deux types d'annulation :

1. **Annulation immédiate** : `cancel_at_period_end: false` + `status: "canceled"`
   - L'abonnement s'arrête immédiatement
   - Pas de remboursement (sauf si configuré)

2. **Annulation en fin de période** : `cancel_at_period_end: true` + `status: "active"`
   - L'abonnement reste actif jusqu'à `current_period_end`
   - L'utilisateur utilise ce qu'il a payé

**Solution : Vérifier les deux conditions** :
```dart
bool get hasAccess {
  if (status != 'active' && status != 'trialing') {
    return false;
  }
  
  // Si annulé, vérifier la date de fin
  if (cancelAtPeriodEnd == true) {
    final endDate = DateTime.fromMillisecondsSinceEpoch(currentPeriodEnd * 1000);
    return DateTime.now().isBefore(endDate);
  }
  
  return true;
}
```

## Problèmes de performance

### P15 : L'app est lente au démarrage

**Cause** : Firebase s'initialise

**Solution** :
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Afficher un splash screen pendant l'init
  runApp(const SplashScreen());
  
  // Initialiser Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Lancer l'app
  runApp(const MyApp());
}
```

### P16 : Trop de lectures Firestore

**Symptôme** : Facture Firebase élevée

**Cause** : Les Streams lisent à chaque changement

**Solution : Limiter les lectures** :
```dart
// Utiliser des snapshots avec cache
_firestore
  .collection('users/$userId/subscriptions')
  .snapshots(includeMetadataChanges: false) // ← Pas de changements de cache
  .map(...);
```

**Optimisation : Désactiver les listeners inactifs** :
```dart
class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => false; // ← Nettoyer quand invisible
  
  // ...
}
```

## Questions de sécurité

### Q6 : Mes clés Firebase sont exposées, est-ce grave ?

**Réponse** : Non, c'est normal.

Les clés dans `firebase_options.dart` sont des **clés publiques**.
Elles sont censées être dans le code client.

**Sécurité assurée par** :
- Règles Firestore (qui peut lire/écrire quoi)
- Firebase Auth (authentification)
- Cloud Functions (logique côté serveur)

**DANGER** : Exposer la clé **secrète** Stripe (`sk_test_...` ou `sk_live_...`)
- Ne JAMAIS la mettre dans Flutter
- Toujours la garder côté serveur (Cloud Functions)

### Q7 : Peut-on contourner le paywall côté client ?

**Oui, techniquement**, un utilisateur avancé pourrait :
- Décompiler l'app Flutter
- Modifier le code local
- Faire croire qu'il a accès au premium

**MAIS** cela ne lui donnerait pas vraiment accès :
- Les données sensibles doivent être côté serveur
- Les APIs doivent vérifier le statut d'abonnement côté serveur
- Firestore doit avoir des règles strictes

**Bonne pratique** :
```javascript
// Firestore Rules
match /premium_content/{docId} {
  // Vérifier que l'utilisateur a un abonnement actif
  allow read: if request.auth != null &&
    exists(/databases/$(database)/documents/users/$(request.auth.uid)/subscriptions/$(subscription))
    && get(/databases/$(database)/documents/users/$(request.auth.uid)/subscriptions/$(subscription)).data.status == 'active';
}
```

## Obtenir de l'aide

### Ressources officielles

- **Flutter** : https://docs.flutter.dev
- **Firebase** : https://firebase.google.com/docs
- **Stripe** : https://stripe.com/docs
- **Extension Stripe** : https://github.com/stripe/stripe-firebase-extensions

### Communautés

- **Stack Overflow** : Tag `flutter` + `stripe` + `firebase`
- **Reddit** : r/FlutterDev
- **Discord** : Flutter Dev Community

### Logs utiles à partager

```dart
// Activer les logs Firebase
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);

// Logs détaillés
print('Firebase initialized');
print('User: ${FirebaseAuth.instance.currentUser?.uid}');
```

## Prochaine étape

Pour approfondir encore plus, consultez : [Exercices pratiques](16_EXERCICES.md)

