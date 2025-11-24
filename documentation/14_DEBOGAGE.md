# 14 - Débogage et logs

## Outils de débogage

### 1. Firebase Console

**Accès :** https://console.firebase.google.com

**Sections utiles :**

**Authentication > Users**
- Liste des utilisateurs
- UID, email, date de création
- Dernier sign-in

**Firestore > Data**
- Explorer les collections
- Voir les documents en temps réel
- Modifier manuellement les données (pour tester)

**Functions > Logs**
- Logs de toutes les Cloud Functions
- Filtrer par fonction
- Erreurs en rouge

**Functions > Dashboard**
- Nombre d'invocations
- Erreurs
- Temps d'exécution

### 2. Stripe Dashboard

**Accès :** https://dashboard.stripe.com

**Sections utiles :**

**Payments**
- Tous les paiements
- Statut, montant, date
- Détails de chaque transaction

**Customers**
- Liste des clients
- Recherche par email
- Abonnements associés

**Subscriptions**
- Tous les abonnements
- Statut, prochain paiement

**Developers > Events**
- Tous les événements Stripe
- Filtrer par type
- Voir le JSON complet

**Developers > Webhooks**
- État des webhooks
- Logs de livraison
- Réessayer un webhook manuellement

**Developers > Logs**
- Toutes les requêtes API
- Succès et erreurs
- Détails techniques

## Activer les logs dans Flutter

### Logs console basiques

```dart
// Dans subscription_service.dart
Future<void> createCheckoutSession() async {
  print('🔵 Début création session checkout');
  print('User ID: $userId');
  print('Price ID: $monthlyPriceId');
  
  final docRef = await _firestore
      .collection('users/$userId/checkout_sessions')
      .add({...});
  
  print('📄 Document créé: ${docRef.id}');
  
  await _waitForCheckoutUrl(docRef);
  print('✅ Session créée avec succès');
}
```

### Logs détaillés Firestore

```dart
// Écouter tous les changements
docRef.snapshots().listen((snapshot) {
  print('📊 Document updated:');
  print(snapshot.data());
});
```

### Logs Firebase

```dart
import 'package:firebase_core/firebase_core.dart';

// Activer les logs Firebase
FirebaseFirestore.setLoggingEnabled(true);
```

## Problèmes courants et solutions

### Problème 1 : "URL de checkout ne se génère pas"

**Symptômes :**
- Timeout après 10 secondes
- Pas d'URL dans Firestore

**Débogage :**

1. **Vérifier que l'extension est installée**
```
Firebase Console > Extensions
```
Doit voir "firestore-stripe-payments"

2. **Vérifier les Cloud Functions**
```
Firebase Console > Functions
```
Doit voir `ext-firestore-stripe-payments-createCheckoutSession`

3. **Vérifier les logs Functions**
```
Firebase Console > Functions > Logs
```
Chercher des erreurs récentes

4. **Vérifier le document créé**
```dart
final doc = await docRef.get();
print('Document data: ${doc.data()}');
```

**Erreurs fréquentes :**

**"No such price"**
```
Error: No such price: 'price_VOTRE_PRICE_ID_ICI'
```
Solution : Remplacer le Price ID dans `subscription_service.dart`

**"Invalid API Key"**
```
Error: Invalid API Key provided
```
Solution : Vérifier la clé Stripe dans l'extension

### Problème 2 : "Abonnement payé mais pas synchronisé"

**Symptômes :**
- Paiement réussi dans Stripe
- Pas de document dans `subscriptions`

**Débogage :**

1. **Vérifier les webhooks Stripe**
```
Stripe Dashboard > Developers > Webhooks
```
Cliquer sur l'endpoint → onglet "Recent deliveries"

2. **Vérifier qu'un webhook a été envoyé**
```
Event : customer.subscription.created
Status : 200 (succès) ou 4xx/5xx (erreur)
```

3. **Si erreur 4xx/5xx, voir les logs Firebase Functions**
```
Firebase Console > Functions > handleWebhookEvents > Logs
```

4. **Vérifier le lien customer → user**
```
Firestore > users/{uid}
```
Doit contenir `stripeId: "cus_xxxxx"`

**Causes fréquentes :**

**stripeId manquant**
```
users/{uid} n'a pas de champ stripeId
```
Solution : Supprimer le compte et recréer (l'extension créera stripeId)

**Webhook désactivé**
```
Stripe Dashboard > Webhooks > [endpoint]
Status : Disabled
```
Solution : Cliquer "Enable"

### Problème 3 : "Permission denied Firestore"

**Symptômes :**
```
FirebaseError: Missing or insufficient permissions
```

**Débogage :**

1. **Vérifier les règles Firestore**
```
Firebase Console > Firestore > Rules
```

2. **Vérifier que l'utilisateur est connecté**
```dart
print('Current user: ${FirebaseAuth.instance.currentUser?.uid}');
```

3. **Tester les règles**
```
Firebase Console > Firestore > Rules > Simulator
```
Simuler une lecture avec l'UID de l'utilisateur

**Solution :** Voir module 04 pour les bonnes règles

### Problème 4 : "setState called after dispose"

**Symptômes :**
```
setState() called after dispose(): _PaywallScreenState#abc123
```

**Cause :** Appel asynchrone qui se termine après destruction du widget

**Solution :**
```dart
Future<void> _handleSubscribe() async {
  // ...
  await subscriptionService.createCheckoutSession();
  
  // Vérifier que le widget est toujours monté
  if (mounted) {
    setState(() => _isLoading = false);
  }
}
```

## Inspecter les données Firestore

### Depuis Firebase Console

1. Firebase Console > Firestore
2. Naviguer dans les collections
3. Cliquer sur un document pour voir ses données
4. Modifier manuellement (pour tester)

### Depuis Flutter (pour déboguer)

```dart
// Lire et afficher toutes les subscriptions
final snapshot = await FirebaseFirestore.instance
  .collection('users/$userId/subscriptions')
  .get();

for (var doc in snapshot.docs) {
  print('Subscription ${doc.id}:');
  print(doc.data());
}
```

## Inspecter les événements Stripe

### Stripe Dashboard

1. Developers > Events
2. Filtrer par type : `customer.subscription.*`
3. Cliquer sur un événement
4. Onglet "API request" : voir la requête
5. Onglet "Webhook deliveries" : voir l'envoi

### Resend un webhook manuellement

1. Stripe Dashboard > Developers > Events
2. Cliquer sur un événement
3. Section "Webhook deliveries"
4. Cliquer sur "..." > "Resend event"

Utile si un webhook a été perdu.

## Stripe CLI (avancé)

### Installation

```bash
# Mac
brew install stripe/stripe-cli/stripe

# Windows
scoop install stripe

# Linux
# Voir https://stripe.com/docs/stripe-cli
```

### Écouter les webhooks localement

```bash
# Se connecter
stripe login

# Forward webhooks vers une URL locale
stripe listen --forward-to https://us-central1-PROJET.cloudfunctions.net/ext-firestore-stripe-payments-handleWebhookEvents
```

### Déclencher des événements manuellement

```bash
# Simuler un paiement réussi
stripe trigger invoice.payment_succeeded

# Simuler un paiement échoué
stripe trigger invoice.payment_failed

# Simuler une annulation
stripe trigger customer.subscription.deleted
```

## Logs structurés

Pour des logs plus propres :

```dart
class Logger {
  static const _tag = '🔥 Flutter';
  
  static void info(String message) {
    print('$_tag ℹ️ $message');
  }
  
  static void error(String message, [dynamic error]) {
    print('$_tag ❌ $message');
    if (error != null) print('   Error: $error');
  }
  
  static void success(String message) {
    print('$_tag ✅ $message');
  }
}

// Utilisation
Logger.info('Création session checkout');
Logger.success('Session créée: $url');
Logger.error('Échec création session', e);
```

## Checklist de débogage

Quand quelque chose ne fonctionne pas :

**Étape 1 : Localiser le problème**
- [ ] Le problème est-il dans Flutter ?
- [ ] Le problème est-il dans Firebase ?
- [ ] Le problème est-il dans Stripe ?

**Étape 2 : Consulter les logs**
- [ ] Logs Flutter (console)
- [ ] Logs Firebase Functions
- [ ] Logs Stripe Events
- [ ] Logs Stripe Webhooks

**Étape 3 : Vérifier les données**
- [ ] Firestore : données présentes ?
- [ ] Stripe Dashboard : paiement visible ?
- [ ] Firebase Auth : utilisateur connecté ?

**Étape 4 : Vérifier la configuration**
- [ ] Price ID correct ?
- [ ] Clé Stripe correcte ?
- [ ] Extension installée ?
- [ ] Règles Firestore correctes ?

**Étape 5 : Isoler le problème**
- [ ] Tester avec un nouveau compte
- [ ] Tester avec une carte différente
- [ ] Réinstaller l'extension
- [ ] Nettoyer et reconstruire l'app

## Prochaine étape

Consulter les questions fréquentes : [FAQ et problèmes courants](15_FAQ.md)

