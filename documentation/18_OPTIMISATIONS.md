# 18 - Optimisations

## Optimisation des coûts Firebase

### 1. Réduire les lectures Firestore

**Problème :** Chaque lecture Firestore est facturée.

**Solution 1 : Utiliser le cache**
```dart
// Lire depuis le cache en priorité
final snapshot = await FirebaseFirestore.instance
  .collection('users/$userId/subscriptions')
  .get(const GetOptions(source: Source.cache));

// Si vide, lire depuis le serveur
if (snapshot.docs.isEmpty) {
  final serverSnapshot = await FirebaseFirestore.instance
    .collection('users/$userId/subscriptions')
    .get();
}
```

**Solution 2 : Limiter les snapshots**
```dart
// ❌ Écoute tous les changements (coûteux)
.snapshots()

// ✅ Lire une seule fois
.get()

// ✅ Écouter seulement quand nécessaire
if (needsRealtime) {
  .snapshots()
} else {
  .get()
}
```

**Solution 3 : Limiter les documents**
```dart
// ❌ Lire tous les paiements
.collection('payments').get()

// ✅ Limiter aux 10 derniers
.collection('payments')
.orderBy('created', descending: true)
.limit(10)
.get()
```

### 2. Optimiser les Cloud Functions

**Temps d'exécution = coût**

**Problème :** Functions qui s'exécutent longtemps

**Solution 1 : Augmenter la mémoire**
```javascript
// firebase.json
{
  "functions": {
    "memory": "1GB",  // Plus de mémoire = plus rapide
    "timeout": 60
  }
}
```

**Solution 2 : Cacher les données**
```javascript
// Cacher les produits Stripe
let cachedProducts = null;
let cacheTime = 0;

exports.getProducts = functions.https.onRequest(async (req, res) => {
  const now = Date.now();
  
  // Cache valide 1 heure
  if (cachedProducts && (now - cacheTime) < 3600000) {
    return res.json(cachedProducts);
  }
  
  // Récupérer depuis Stripe
  const products = await stripe.products.list();
  cachedProducts = products;
  cacheTime = now;
  
  res.json(products);
});
```

### 3. Quotas gratuits Firebase

**Plan gratuit (Spark) :**
```
Firestore :
- 50 000 lectures/jour
- 20 000 écritures/jour
- 1 GB stockage

Functions :
- 2 000 000 invocations/mois
- 400 000 GB-sec/mois
```

**Optimisation pour rester gratuit :**
- Limiter les Streams (lectures continues)
- Cacher les données localement
- Paginer les résultats

## Optimisation des performances Flutter

### 1. Lazy loading

**Problème :** Charger toutes les données d'un coup

**Solution : Pagination**
```dart
class PaymentsHistory extends StatefulWidget {
  @override
  State<PaymentsHistory> createState() => _PaymentsHistoryState();
}

class _PaymentsHistoryState extends State<PaymentsHistory> {
  final List<DocumentSnapshot> _payments = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  
  final int _pageSize = 20;
  
  @override
  void initState() {
    super.initState();
    _loadMore();
  }
  
  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    
    setState(() => _isLoading = true);
    
    Query query = FirebaseFirestore.instance
      .collection('users/$userId/payments')
      .orderBy('created', descending: true)
      .limit(_pageSize);
    
    // Pagination
    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }
    
    final snapshot = await query.get();
    
    if (snapshot.docs.length < _pageSize) {
      _hasMore = false;
    }
    
    if (snapshot.docs.isNotEmpty) {
      _lastDocument = snapshot.docs.last;
    }
    
    setState(() {
      _payments.addAll(snapshot.docs);
      _isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _payments.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Charger plus quand on arrive à la fin
        if (index == _payments.length) {
          _loadMore();
          return const Center(child: CircularProgressIndicator());
        }
        
        return PaymentTile(payment: _payments[index]);
      },
    );
  }
}
```

### 2. Optimiser les rebuilds

**Problème :** Widgets qui se reconstruisent trop souvent

**Solution 1 : const constructors**
```dart
// ❌ Reconstruit à chaque fois
Widget build(BuildContext context) {
  return Text('Abonnement Premium');
}

// ✅ Constante, jamais reconstruit
Widget build(BuildContext context) {
  return const Text('Abonnement Premium');
}
```

**Solution 2 : Séparer les widgets**
```dart
// ❌ Tout se reconstruit quand status change
Widget build(BuildContext context) {
  return Column(
    children: [
      _buildHeader(),        // Se reconstruit
      _buildStatus(status),  // Se reconstruit (normal)
      _buildFooter(),        // Se reconstruit (inutile)
    ],
  );
}

// ✅ Seulement StatusWidget se reconstruit
Widget build(BuildContext context) {
  return Column(
    children: [
      const HeaderWidget(),
      StatusWidget(status: status),
      const FooterWidget(),
    ],
  );
}
```

**Solution 3 : Provider avec listen: false**
```dart
// ❌ Widget se reconstruit à chaque changement de authService
final authService = Provider.of<AuthService>(context);

// ✅ Widget ne se reconstruit pas
final authService = Provider.of<AuthService>(context, listen: false);
```

### 3. Caching des images

Si vous affichez des images produits :

```dart
// ❌ Recharge l'image à chaque fois
Image.network(productImageUrl)

// ✅ Cache l'image
CachedNetworkImage(
  imageUrl: productImageUrl,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
)
```

### 4. Débouncing des recherches

Si vous ajoutez une recherche :

```dart
Timer? _debounce;

void _onSearchChanged(String query) {
  // Annuler le timer précédent
  if (_debounce?.isActive ?? false) _debounce!.cancel();
  
  // Attendre 500ms après la dernière frappe
  _debounce = Timer(const Duration(milliseconds: 500), () {
    _performSearch(query);
  });
}

@override
void dispose() {
  _debounce?.cancel();
  super.dispose();
}
```

## Optimisation Stripe

### 1. Utiliser les métadonnées

**Éviter les allers-retours entre Stripe et Firebase**

```dart
// Stocker des infos dans les métadonnées Stripe
await _firestore
  .collection('users/$userId/checkout_sessions')
  .add({
    'price': priceId,
    'metadata': {
      'userId': userId,
      'source': 'mobile_app',
      'version': '1.0.0',
    },
  });
```

Ces métadonnées seront disponibles dans tous les webhooks.

### 2. Webhooks optimisés

**Activer seulement les événements nécessaires**

Dans Stripe Dashboard > Webhooks :
```
✅ customer.subscription.created
✅ customer.subscription.updated
✅ customer.subscription.deleted
✅ invoice.payment_succeeded
✅ invoice.payment_failed

❌ customer.created (géré par l'extension)
❌ charge.* (non utilisés)
```

Moins d'événements = moins de Cloud Functions invoquées = coûts réduits.

### 3. Stripe Checkout optimisé

**Pré-remplir les données client**

```dart
await _firestore
  .collection('users/$userId/checkout_sessions')
  .add({
    'price': priceId,
    'customer_email': user.email,  // ← Pré-rempli
    'mode': 'subscription',
  });
```

Améliore l'UX et réduit les abandons.

## Optimisation de la taille de l'app

### 1. Supprimer les imports inutilisés

```bash
# Analyser le projet
flutter analyze

# Nettoyer
dart fix --apply
```

### 2. Compiler en mode release

```bash
# Mode debug (gros, lent)
flutter run

# Mode release (optimisé)
flutter run --release
```

### 3. Compresser les assets

Si vous avez des images :
- PNG : utiliser TinyPNG
- JPEG : qualité 85%
- Format WebP (plus léger)

### 4. Supprimer les packages inutilisés

```yaml
# Vérifier les dépendances réellement utilisées
flutter pub deps
```

## Monitoring et alertes

### 1. Firebase Performance Monitoring

```dart
// Ajouter le package
firebase_performance: ^0.10.0

// Tracer une opération
final trace = FirebasePerformance.instance.newTrace('subscription_flow');
await trace.start();

try {
  await subscriptionService.createCheckoutSession();
  trace.setMetric('success', 1);
} catch (e) {
  trace.setMetric('success', 0);
} finally {
  await trace.stop();
}
```

### 2. Alertes Stripe

Dans Stripe Dashboard > Developers > Webhooks :
- Activer les alertes par email
- Webhook qui échoue : alerte après 5 échecs

### 3. Alertes Firebase

Firebase Console > Alertes :
- Nombre d'erreurs Functions > 10/heure
- Latence Functions > 10 secondes
- Quotas Firestore > 80% utilisés

## Checklist d'optimisation

Avant de passer en production :

**Performance**
- [ ] const constructors partout où possible
- [ ] Streams limités au strict nécessaire
- [ ] Images cachées
- [ ] Pagination implémentée
- [ ] Debouncing sur les recherches

**Coûts**
- [ ] Lectures Firestore minimisées
- [ ] Cache activé
- [ ] Webhooks filtrés
- [ ] Functions optimisées

**UX**
- [ ] Indicateurs de chargement
- [ ] Messages d'erreur clairs
- [ ] Offline support (cache)
- [ ] Temps de réponse < 2s

**Monitoring**
- [ ] Performance Monitoring activé
- [ ] Alertes configurées
- [ ] Logs structurés
- [ ] Dashboard de suivi

## Benchmarks

### Temps cibles

| Action | Temps acceptable | Temps idéal |
|--------|------------------|-------------|
| Login | < 2s | < 1s |
| Affichage statut | < 1s | < 500ms |
| Création Checkout | < 5s | < 3s |
| Synchronisation paiement | < 10s | < 5s |

### Coûts estimés

Pour 1000 utilisateurs actifs/mois :

```
Firebase :
- Firestore : ~50 000 lectures/mois = 0,09 €
- Functions : ~100 000 invocations/mois = 0,04 €
Total Firebase : ~0,15 €

Stripe :
- 50 abonnements à 19 €/mois
- Revenu : 950 €
- Frais Stripe (1,4% + 0,25 €) : ~26 €
Net : ~924 €

Coûts totaux : ~26 € (2,7% du revenu)
```

## Prochaine étape

Découvrir les fonctionnalités avancées : [Aller plus loin](19_ALLER_PLUS_LOIN.md)

