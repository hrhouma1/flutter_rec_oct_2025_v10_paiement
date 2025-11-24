# 12 - Gestion des états d'abonnement

## Cycle de vie d'un abonnement

```
                    ┌──────────────┐
                    │  Pas d'abo   │
                    └──────┬───────┘
                           │
                    Paiement initial
                           │
                    ┌──────▼───────┐
              ┌────►│ incomplete   │─────┐
              │     └──────┬───────┘     │ échec après 23h
              │            │             │
              │     Paiement réussi      │
              │            │             │
              │     ┌──────▼───────┐     │
              │     │   active     │     │
              │     └──────┬───────┘     │
              │            │             │
              │     ┌──────┴──────┐      │
              │     │             │      │
              │  Annulation   Échec paiement
              │     │             │      │
              │     │      ┌──────▼───────┐
              │     │      │  past_due    │───┐
              │     │      └──────┬───────┘   │ Tous les paiements échouent
              │     │             │           │
              │     │      Paiement réussi    │
              │     │             │           │
              │     │      ┌──────┴───────┐   │
              │     │      │   active     │   │
              │     │      └──────────────┘   │
              │     │                         │
              │     │                  ┌──────▼───────┐
              │     └─────────────────►│    unpaid    │
              │                        └──────────────┘
              │                               │
              └───────────────────────────────┘
                           │
                    ┌──────▼───────┐
                    │   canceled   │
                    └──────────────┘
```

## États Stripe

### active

**Signification :** Abonnement actif et payé

**Accès premium :** Oui

**Prochaine action :** Facturation automatique à `current_period_end`

**Exemple Firestore :**
```json
{
  "status": "active",
  "current_period_start": 1700000000,
  "current_period_end": 1702678400,
  "cancel_at_period_end": false
}
```

### trialing

**Signification :** Période d'essai gratuite

**Accès premium :** Oui (mais pas encore facturé)

**Prochaine action :** Première facturation à la fin de la période d'essai

**Exemple Firestore :**
```json
{
  "status": "trialing",
  "trial_start": 1700000000,
  "trial_end": 1702678400,
  "current_period_start": 1700000000,
  "current_period_end": 1702678400
}
```

### past_due

**Signification :** Le paiement de renouvellement a échoué

**Accès premium :** À définir (selon votre logique métier)

**Prochaine action :** Stripe réessaie automatiquement selon vos paramètres

**Tentatives de paiement :**
```
Échec initial
  ↓ +3 jours
Tentative 2
  ↓ +5 jours
Tentative 3
  ↓ +7 jours
Tentative 4
  ↓
Status "unpaid" ou "canceled"
```

**Exemple Firestore :**
```json
{
  "status": "past_due",
  "latest_invoice": "in_abc123"
}
```

### canceled

**Signification :** Abonnement annulé

**Cas 1 : Annulation immédiate**
```json
{
  "status": "canceled",
  "canceled_at": 1700000000,
  "ended_at": 1700000000
}
```
Accès premium : Non (immédiat)

**Cas 2 : Annulation en fin de période**
```json
{
  "status": "canceled",
  "cancel_at_period_end": true,
  "current_period_end": 1702678400,
  "canceled_at": 1700000000
}
```
Accès premium : Oui (jusqu'à `current_period_end`)

### incomplete

**Signification :** Paiement initial en cours (3D Secure, etc.)

**Accès premium :** Non

**Prochaine action :** 
- Si paiement réussi → `active`
- Si échec après 23h → `incomplete_expired`

**Exemple Firestore :**
```json
{
  "status": "incomplete",
  "latest_invoice": "in_abc123"
}
```

### incomplete_expired

**Signification :** Paiement initial non complété dans les 23h

**Accès premium :** Non

**Prochaine action :** Aucune (abonnement mort)

### unpaid

**Signification :** Tous les paiements de renouvellement ont échoué

**Accès premium :** Non

**Prochaine action :** Généralement, annulation définitive

## Mapping dans l'application

### Enum SubscriptionStatus

```dart
enum SubscriptionStatus {
  none,      // Pas d'abonnement
  active,    // Abonnement actif
  pastDue,   // Paiement en retard
  canceled,  // Annulé
}
```

### Logique de mapping

```dart
SubscriptionStatus _parseSubscriptionStatus(Map<String, dynamic> data) {
  final status = data['status'] as String?;
  
  switch (status) {
    case 'active':
    case 'trialing':
      return SubscriptionStatus.active;
      
    case 'past_due':
      return SubscriptionStatus.pastDue;
      
    case 'canceled':
      return SubscriptionStatus.canceled;
      
    default:
      return SubscriptionStatus.none;
  }
}
```

### Déterminer l'accès premium

**Option 1 : Simple**
```dart
bool get hasAccess {
  return status == SubscriptionStatus.active;
}
```

**Option 2 : Complète (avec canceled)**
```dart
bool get hasAccess {
  // Vérifier le statut de base
  if (status != SubscriptionStatus.active && 
      status != SubscriptionStatus.canceled) {
    return false;
  }
  
  // Si canceled, vérifier la date de fin
  if (status == SubscriptionStatus.canceled) {
    if (cancelAtPeriodEnd) {
      final endDate = DateTime.fromMillisecondsSinceEpoch(
        currentPeriodEnd * 1000
      );
      return DateTime.now().isBefore(endDate);
    }
    return false;
  }
  
  return true;
}
```

## Transitions d'état

### Création d'abonnement

```
1. Utilisateur clique "S'abonner"
2. Flutter crée checkout_sessions
3. Extension crée session Stripe
4. Utilisateur paie

Si paiement immédiat :
5. Webhook subscription.created, status: "active"
6. Extension écrit dans Firestore

Si 3D Secure requis :
5. Webhook subscription.created, status: "incomplete"
6. Extension écrit dans Firestore
7. Utilisateur valide 3D Secure
8. Webhook subscription.updated, status: "active"
9. Extension met à jour Firestore
```

### Renouvellement réussi

```
1. Stripe facture automatiquement à current_period_end
2. Paiement réussi
3. Webhook invoice.payment_succeeded
4. Webhook subscription.updated (nouvelles dates)
5. Extension met à jour Firestore
```

### Renouvellement échoué

```
1. Stripe facture automatiquement
2. Paiement échoue
3. Webhook invoice.payment_failed
4. Webhook subscription.updated, status: "past_due"
5. Extension met à jour Firestore
6. Stripe réessaie selon vos paramètres
```

### Annulation utilisateur

**Via le portail client :**
```
1. Utilisateur ouvre le portail
2. Clique "Annuler l'abonnement"
3. Choisit "À la fin de la période" ou "Immédiatement"

Si fin de période :
4. Webhook subscription.updated, cancel_at_period_end: true
5. Extension met à jour Firestore
6. À current_period_end → webhook subscription.deleted

Si immédiat :
4. Webhook subscription.deleted, status: "canceled"
5. Extension met à jour Firestore
```

## Gestion côté Flutter

### Écouter les changements

```dart
StreamBuilder<SubscriptionStatus>(
  stream: subscriptionService.getSubscriptionStatus(),
  builder: (context, snapshot) {
    final status = snapshot.data ?? SubscriptionStatus.none;
    
    switch (status) {
      case SubscriptionStatus.none:
        return PaywallScreen();
        
      case SubscriptionStatus.active:
        return PremiumContent();
        
      case SubscriptionStatus.pastDue:
        return UpdatePaymentScreen();
        
      case SubscriptionStatus.canceled:
        return CanceledScreen();
    }
  },
)
```

### Afficher le statut

```dart
String getStatusMessage(SubscriptionStatus status) {
  switch (status) {
    case SubscriptionStatus.none:
      return 'Aucun abonnement actif';
      
    case SubscriptionStatus.active:
      return 'Abonnement actif';
      
    case SubscriptionStatus.pastDue:
      return 'Paiement en retard - Veuillez mettre à jour votre carte';
      
    case SubscriptionStatus.canceled:
      return 'Abonnement annulé';
  }
}
```

### Afficher la date de renouvellement

```dart
Widget buildRenewalDate(Map<String, dynamic> subscriptionData) {
  final periodEnd = subscriptionData['current_period_end'] as int;
  final renewalDate = DateTime.fromMillisecondsSinceEpoch(periodEnd * 1000);
  
  return Text(
    'Prochain renouvellement : ${DateFormat('dd/MM/yyyy').format(renewalDate)}'
  );
}
```

## Bonnes pratiques

### 1. Toujours vérifier l'accès côté serveur

Ne jamais se fier uniquement à l'état côté client.

**Règles Firestore :**
```javascript
match /premium_content/{docId} {
  allow read: if request.auth != null &&
    hasActiveSubscription(request.auth.uid);
}

function hasActiveSubscription(uid) {
  let subscription = get(/databases/$(database)/documents/users/$(uid)/subscriptions/$(sub));
  return subscription.data.status == 'active';
}
```

### 2. Gérer les états transitoires

```dart
if (snapshot.connectionState == ConnectionState.waiting) {
  return CircularProgressIndicator();
}
```

### 3. Afficher des messages clairs

```dart
case SubscriptionStatus.pastDue:
  return AlertDialog(
    title: Text('Problème de paiement'),
    content: Text(
      'Votre dernier paiement a échoué. '
      'Veuillez mettre à jour votre moyen de paiement.'
    ),
    actions: [
      TextButton(
        onPressed: () => openCustomerPortal(),
        child: Text('Mettre à jour'),
      ),
    ],
  );
```

### 4. Prévoir les cas limites

```dart
// Que faire si l'abonnement est en past_due ?
// Option A : Bloquer l'accès immédiatement
// Option B : Laisser une période de grâce (ex: 7 jours)
// Option C : Dégrader progressivement les fonctionnalités

bool get hasAccess {
  if (status == SubscriptionStatus.pastDue) {
    // Option B : Grace period
    final daysPastDue = DateTime.now().difference(lastPaymentAttempt).inDays;
    return daysPastDue < 7;
  }
  return status == SubscriptionStatus.active;
}
```

## Prochaine étape

Tester l'application : [Scénarios de test](13_SCENARIOS_TEST.md)

