# 03 - Installer l'extension Firebase Stripe

## Durée : 10 minutes (+ 5 minutes d'attente)

## 1. Accéder aux extensions Firebase

1. Retourne sur https://console.firebase.google.com
2. Sélectionne ton projet
3. Dans le menu de gauche, clique sur **"Extensions"**
4. Clique sur **"Explorer les extensions"**

## 2. Trouver l'extension Stripe

1. Dans la barre de recherche, tape : **"stripe"**
2. Trouve l'extension **"Run Payments with Stripe"**
   - Éditeur : Stripe
   - Icône : logo Stripe
3. Clique sur **"Install in console"**

## 3. Activer la facturation (si demandé)

Si tu vois un message sur la facturation :
1. Clique sur **"Upgrade project"**
2. Sélectionne le plan **"Blaze (Pay as you go)"**
3. Ajoute une carte bancaire
4. **Rassure-toi** : Tu ne seras pas facturé (quotas gratuits largement suffisants)

## 4. Configurer l'extension

### Écran 1 : Review billing
Clique sur **"Next"**

### Écran 2 : Review APIs
Clique sur **"Next"**

### Écran 3 : Configure extension

Remplis les champs suivants :

**Stripe API key with restricted access**
```
Colle ta Secret Key de l'étape 02 : sk_test_51Abc...
```

**Products and pricing plans collection**
```
Laisse : products
```

**Customer details and subscriptions collection**
```
Change en : users
```
**IMPORTANT** : Bien mettre `users` et pas `customers` !

**Sync new users to Stripe customers**
```
Sélectionne : Sync
```

**Delete Stripe customer objects**
```
Sélectionne : Do not delete
```

**Stripe webhook secret**
```
Laisse vide pour l'instant
```

Laisse tous les autres paramètres par défaut.

## 5. Installer l'extension

1. Clique sur **"Install extension"**
2. Un message apparaît : **"Installing extension..."**
3. **ATTENDS 5 MINUTES** (c'est important, ne fais rien d'autre)

L'extension va :
- Créer des Cloud Functions
- Configurer les webhooks Stripe
- Déployer le tout

## 6. Vérifier l'installation

### Dans Firebase Console

1. Menu gauche, clique sur **"Functions"**
2. Tu dois voir plusieurs fonctions qui commencent par `ext-firestore-stripe-payments-` :
   - `createCheckoutSession`
   - `handleWebhookEvents`
   - `createPortalLink`
   - etc.

### Dans Stripe Dashboard

1. Va sur https://dashboard.stripe.com
2. Menu "Developers" > "Webhooks"
3. Tu dois voir un endpoint qui commence par :
   ```
   https://us-central1-TON_PROJET.cloudfunctions.net/ext-firestore-stripe-payments-handleWebhookEvents
   ```
4. Status : **Active**

## 7. Lancer l'application

Dans ton terminal :

```bash
# Installer les dépendances
flutter pub get

# Lancer l'app
flutter run
```

Sélectionne ton device (navigateur Chrome, émulateur Android, etc.)

## 8. Tester le flux complet

### Créer un compte
1. Dans l'app, clique sur **"S'inscrire"**
2. Email : `test@example.com`
3. Mot de passe : `password123`
4. Tu arrives sur HomeScreen
5. Tu vois : **"Aucun abonnement"**

### S'abonner
1. Clique sur **"Débloquer Premium"**
2. Tu arrives sur l'écran Paywall
3. Clique sur **"S'abonner maintenant"**
4. Attends 2-5 secondes
5. Une page Stripe Checkout s'ouvre dans ton navigateur

### Payer avec une carte de test
1. Sur la page Stripe, remplis :
   - **Numéro de carte** : `4242 4242 4242 4242`
   - **Date** : `12/34` (n'importe quelle date future)
   - **CVC** : `123` (n'importe quel code)
   - **Nom** : `Test User`
2. Clique sur **"Payer"**
3. Attends quelques secondes
4. Tu es redirigé

### Vérifier l'abonnement
1. Retourne dans l'app
2. Le statut doit passer à **"Abonnement actif"**
3. Le bouton change en **"Accéder aux fonctionnalités Premium"**
4. Clique dessus pour voir l'écran Premium

## 9. Vérifier dans les dashboards

### Firebase Firestore
1. Firebase Console > Firestore Database
2. Tu dois voir :
   ```
   users/
     └─ [ton_uid]/
         ├─ email: "test@example.com"
         ├─ stripeId: "cus_xxxxx"
         └─ subscriptions/
             └─ [sub_id]/
                 ├─ status: "active"
                 └─ current_period_end: ...
   ```

### Stripe Dashboard
1. Stripe Dashboard > Customers
2. Tu vois ton client avec l'email `test@example.com`
3. Stripe Dashboard > Subscriptions
4. Tu vois ton abonnement actif
5. Stripe Dashboard > Payments
6. Tu vois le paiement de 19 €

## Problèmes courants

### La page Stripe ne s'ouvre pas
- Vérifie que tu as bien attendu 5 minutes après l'installation
- Vérifie que le Price ID dans `subscription_service.dart` est correct
- Regarde les logs : Firebase Console > Functions > Logs

### Le statut ne passe pas à "actif"
- Vérifie que le webhook existe dans Stripe Dashboard > Developers > Webhooks
- Vérifie les logs Firebase Functions
- Attends 10-30 secondes après le paiement

### "Permission denied"
- Vérifie que les règles Firestore sont bien publiées (étape 01)
- Vérifie que tu es connecté dans l'app

## Félicitations

Tu as maintenant une application Flutter fonctionnelle avec :
- Authentification Firebase
- Abonnements Stripe
- Synchronisation automatique
- Paywall conditionnel

## Pour aller plus loin

Consulte **GUIDE_RAPIDE.md** pour :
- Comprendre l'architecture
- Voir les flux de données
- Optimiser l'application

