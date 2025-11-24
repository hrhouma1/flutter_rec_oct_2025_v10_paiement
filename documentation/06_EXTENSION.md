# 06 - Extension Firebase Stripe

## Qu'est-ce qu'une extension Firebase ?

Une extension Firebase est un plugin prêt à l'emploi qui ajoute des fonctionnalités à votre projet Firebase. Les extensions :
- Sont développées par Firebase, Google ou des partenaires
- Génèrent automatiquement des Cloud Functions
- Configurent automatiquement les webhooks
- S'intègrent nativement avec Firestore

## Extension "Run Payments with Stripe"

C'est l'extension officielle développée par Stripe pour Firebase.

**Ce qu'elle fait :**
- Crée des clients Stripe automatiquement
- Génère des sessions Stripe Checkout
- Reçoit et traite les webhooks Stripe
- Synchronise les abonnements dans Firestore
- Crée des liens vers le portail client

**Ce qu'elle ne fait pas :**
- Elle ne gère pas l'interface utilisateur (c'est votre code Flutter)
- Elle ne décide pas de la logique métier (c'est vous)

## Étape 1 : Accéder aux extensions

### 1.1 Ouvrir la console Firebase

1. Aller sur https://console.firebase.google.com
2. Sélectionner votre projet
3. Dans le menu de gauche, cliquer sur "Extensions"

### 1.2 Explorer le catalogue

Vous voyez plusieurs extensions disponibles :
- Run Payments with Stripe
- Trigger Email
- Translate Text
- etc.

## Étape 2 : Installer l'extension Stripe

### 2.1 Trouver l'extension

1. Dans la barre de recherche, taper "Stripe"
2. Cliquer sur "Run Payments with Stripe"
3. Éditeur : Stripe
4. Cliquer sur "Install in console"

### 2.2 Activer les services requis

L'extension nécessite :
- Cloud Functions
- Firestore
- Secret Manager

Cliquer sur "Next" pour activer ces services (gratuit).

### 2.3 Accepter les conditions

1. Lire les conditions d'utilisation
2. Cocher "I accept..."
3. Cliquer sur "Next"

## Étape 3 : Configurer l'extension

### 3.1 Paramètres de base

**Stripe API key**
```
Description : Votre clé secrète Stripe
Valeur : sk_test_51AbCdE...
```

⚠️ Coller votre Secret key copiée depuis Stripe Dashboard > Developers > API keys

**Products and pricing plans collection**
```
Description : Collection Firestore pour les produits
Valeur par défaut : products
Recommandation : Laisser "products"
```

**Customer details and subscriptions collection**
```
Description : Collection Firestore pour les clients
Valeur par défaut : customers
Recommandation : Changer pour "users"
```

⚠️ **Important :** Mettre "users" car c'est le nom de notre collection utilisateurs.

### 3.2 Paramètres de synchronisation

**Sync new users to Stripe customers**
```
Options :
- Sync (recommandé) : Créer automatiquement un client Stripe pour chaque nouvel utilisateur Firebase
- Do not sync : Ne rien faire automatiquement
```

Choisir : **Sync**

**Delete Stripe customer objects**
```
Options :
- Delete : Supprimer le client Stripe quand l'utilisateur Firebase est supprimé
- Do not delete (recommandé) : Garder les données Stripe (pour l'historique)
```

Choisir : **Do not delete**

### 3.3 Paramètres de webhook

**Stripe webhook secret**
```
Description : Secret pour vérifier les webhooks Stripe
Valeur : Laisser vide pour l'instant
```

L'extension va créer un webhook automatiquement et vous pourrez ajouter le secret après.

### 3.4 Paramètres avancés (optionnel)

**Minimum instance count**
```
Valeur par défaut : 0
Recommandation : Laisser 0 (pour économiser)
```

**Maximum instance count**
```
Valeur par défaut : 1000
Recommandation : Laisser 1000
```

**Cloud Functions location**
```
Valeur : us-central1 (ou votre région)
Recommandation : Choisir la même région que Firestore
```

## Étape 4 : Installer l'extension

### 4.1 Révision finale

Vérifier que :
- Stripe API key est correcte (commence par `sk_test_`)
- Customer collection = "users"
- Sync new users = "Sync"

### 4.2 Lancer l'installation

1. Cliquer sur "Install extension"
2. Un message apparaît : "Installing extension..."
3. **Attendre 3-5 minutes**

Le processus :
```
1. Création des Cloud Functions
2. Configuration des triggers Firestore
3. Déploiement des fonctions
4. Configuration du webhook Stripe
```

### 4.3 Confirmation

Quand c'est terminé, vous voyez :
```
✓ Extension installed successfully
```

## Étape 5 : Vérifier l'installation

### 5.1 Vérifier les Cloud Functions

1. Firebase Console > Functions
2. Vous devriez voir plusieurs fonctions :

```
ext-firestore-stripe-payments-createPortalLink
ext-firestore-stripe-payments-onCustomerDataDeleted
ext-firestore-stripe-payments-onUserDeleted
ext-firestore-stripe-payments-createCheckoutSession
ext-firestore-stripe-payments-handleWebhookEvents
```

Si vous les voyez, l'extension est bien installée.

### 5.2 Vérifier le webhook Stripe

1. Stripe Dashboard > Developers > Webhooks
2. Vous devriez voir un endpoint :

```
Endpoint URL : https://us-central1-VOTRE_PROJET.cloudfunctions.net/ext-firestore-stripe-payments-handleWebhookEvents
Status : Active
Version : Latest
```

3. Cliquer sur l'endpoint
4. Vous voyez les événements écoutés :
   - customer.subscription.created
   - customer.subscription.updated
   - customer.subscription.deleted
   - invoice.payment_succeeded
   - invoice.payment_failed
   - etc.

### 5.3 Récupérer le webhook secret (optionnel mais recommandé)

1. Sur la page du webhook, cliquer sur "Reveal" dans la section "Signing secret"
2. Copier le secret (commence par `whsec_`)
3. Retourner dans Firebase Console > Extensions
4. Cliquer sur l'extension Stripe installée
5. Cliquer sur "Reconfigure"
6. Coller le webhook secret
7. Sauvegarder

Cela ajoute une couche de sécurité supplémentaire.

## Étape 6 : Comprendre les fonctions créées

### 6.1 createCheckoutSession

**Déclencheur :** Création d'un document dans `users/{uid}/checkout_sessions`

**Ce qu'elle fait :**
```
1. Lit le document créé (contient le Price ID)
2. Appelle l'API Stripe pour créer une session Checkout
3. Écrit l'URL de checkout dans le document
```

**Utilisée par :** `subscription_service.dart` ligne 70-79

### 6.2 handleWebhookEvents

**Déclencheur :** Requête HTTP POST depuis Stripe

**Ce qu'elle fait :**
```
1. Vérifie la signature du webhook
2. Parse l'événement Stripe
3. Selon le type d'événement :
   - customer.subscription.created : Crée un document subscription
   - customer.subscription.updated : Met à jour le document
   - invoice.payment_succeeded : Enregistre le paiement
   - etc.
```

**Utilisée par :** Stripe (automatiquement)

### 6.3 createPortalLink

**Déclencheur :** Création d'un document dans `users/{uid}/checkout_sessions` avec `returnUrl`

**Ce qu'elle fait :**
```
1. Crée une session de portail client Stripe
2. Écrit l'URL du portail dans le document
```

**Utilisée par :** `subscription_service.dart` ligne 125-135

### 6.4 onUserDeleted

**Déclencheur :** Suppression d'un utilisateur Firebase Auth

**Ce qu'elle fait :**
```
1. Trouve le client Stripe associé
2. Optionnellement, supprime le client Stripe
3. Nettoie les données Firestore
```

**Utilisée par :** Firebase Auth (automatiquement)

## Étape 7 : Synchroniser les produits Stripe

Pour que l'extension connaisse vos produits, deux options :

### Option A : Métadonnées Stripe (recommandé)

1. Stripe Dashboard > Products
2. Cliquer sur votre produit "Plan Premium"
3. Section "Metadata"
4. Ajouter :
   ```
   firebaseRole : premium
   ```
5. Sauvegarder

L'extension synchronise automatiquement les produits avec métadonnées dans Firestore.

### Option B : Création manuelle dans Firestore

1. Firebase Console > Firestore
2. Créer une collection `products`
3. Créer un document (ID automatique)
4. Ajouter les champs :
   ```json
   {
     "name": "Plan Premium",
     "description": "Accès illimité",
     "active": true,
     "role": "premium",
     "images": [],
     "metadata": {}
   }
   ```
5. Créer une sous-collection `prices`
6. Créer un document avec l'ID = votre Price ID Stripe
7. Ajouter les champs :
   ```json
   {
     "active": true,
     "currency": "eur",
     "interval": "month",
     "interval_count": 1,
     "product": "[REFERENCE au document product]",
     "type": "recurring",
     "unit_amount": 1900
   }
   ```

## Étape 8 : Tester l'extension

### 8.1 Créer un compte dans l'app

1. Lancer l'application Flutter
2. Créer un compte de test :
   ```
   Email : test-extension@example.com
   Mot de passe : password123
   ```

### 8.2 Vérifier la création du client Stripe

1. Firestore : vérifier que `users/{uid}` contient maintenant `stripeId`
2. Stripe Dashboard > Customers : vérifier qu'un client avec cet email existe

Si `stripeId` est présent, la synchronisation fonctionne !

### 8.3 Tester un paiement

1. Dans l'app, cliquer sur "Débloquer Premium"
2. Attendre 2-5 secondes
3. Une page Stripe Checkout devrait s'ouvrir

Si la page s'ouvre, `createCheckoutSession` fonctionne !

### 8.4 Effectuer le paiement

1. Sur Stripe Checkout, saisir :
   ```
   Carte : 4242 4242 4242 4242
   Date : 12/34
   CVC : 123
   ```
2. Cliquer sur "Payer"
3. Attendre 5-10 secondes
4. Retourner dans l'app

### 8.5 Vérifier la synchronisation

1. Firestore > `users/{uid}/subscriptions`
2. Un document devrait être créé avec :
   ```json
   {
     "status": "active",
     "current_period_start": ...,
     "current_period_end": ...,
     "items": [...]
   }
   ```

Si ce document existe, le webhook fonctionne !

## Étape 9 : Consulter les logs

### 9.1 Logs Firebase Functions

1. Firebase Console > Functions
2. Cliquer sur une fonction (ex: `handleWebhookEvents`)
3. Onglet "Logs"
4. Vous voyez l'historique des exécutions

**Exemple de log réussi :**
```
Function execution took 523 ms, finished with status: 'ok'
```

**Exemple de log en erreur :**
```
Error: No such customer: cus_xxxxx
Function execution took 234 ms, finished with status: 'error'
```

### 9.2 Logs Stripe

1. Stripe Dashboard > Developers > Events
2. Cliquer sur un événement récent
3. Section "Webhook deliveries"
4. Vous voyez si le webhook a été reçu avec succès

**Exemple réussi :**
```
Response code: 200
Response time: 1.2s
```

## Étape 10 : Mettre à jour l'extension (futur)

Les extensions reçoivent des mises à jour régulières.

Pour mettre à jour :

1. Firebase Console > Extensions
2. Cliquer sur l'extension Stripe
3. Si une mise à jour est disponible, un bouton "Update" apparaît
4. Cliquer sur "Update"
5. Réviser les changements
6. Confirmer

Les mises à jour peuvent inclure :
- Corrections de bugs
- Nouvelles fonctionnalités
- Amélioration des performances

## Checklist de validation

- [ ] Extension installée (3-5 minutes)
- [ ] Cloud Functions visibles dans Firebase Console
- [ ] Webhook créé dans Stripe Dashboard
- [ ] Webhook secret configuré (optionnel)
- [ ] Compte de test créé dans l'app
- [ ] `stripeId` visible dans Firestore
- [ ] Client créé dans Stripe Dashboard
- [ ] Session Checkout se crée (URL s'ouvre)
- [ ] Paiement test effectué
- [ ] Document `subscription` créé dans Firestore
- [ ] Logs Functions sans erreur

## Questions de révision

1. Que fait l'extension Firebase Stripe ?
2. Pourquoi mettre "users" au lieu de "customers" pour la collection ?
3. Quelle fonction est appelée quand on crée un document `checkout_sessions` ?
4. Comment Stripe notifie Firebase d'un paiement réussi ?
5. Où peut-on voir les logs des Cloud Functions ?

## Problèmes courants

### Problème : L'extension ne s'installe pas

**Cause :** Billing non activé sur le projet Firebase

**Solution :**
1. Firebase Console > Paramètres (roue crantée) > Usage and billing
2. Passer au plan "Blaze" (pay-as-you-go)
3. Ajouter une carte bancaire
4. Relancer l'installation

Note : En mode gratuit, l'utilisation reste gratuite (quotas généreux).

### Problème : Le webhook n'est pas créé

**Solution :**
1. Vérifier que l'extension est bien installée
2. Attendre 10 minutes après l'installation
3. Vérifier dans Stripe Dashboard > Webhooks
4. Si absent, désinstaller et réinstaller l'extension

### Problème : `stripeId` n'est pas créé

**Cause :** Paramètre "Sync new users" n'est pas activé

**Solution :**
1. Firebase Console > Extensions
2. Cliquer sur l'extension Stripe
3. "Reconfigure"
4. Mettre "Sync new users" à "Sync"
5. Créer un nouveau compte de test

## Ressources

**Documentation officielle :**
- Extension GitHub : https://github.com/stripe/stripe-firebase-extensions
- Guide d'installation : https://github.com/stripe/stripe-firebase-extensions/blob/master/firestore-stripe-payments/POSTINSTALL.md

**Support :**
- GitHub Issues : https://github.com/stripe/stripe-firebase-extensions/issues
- Stack Overflow : Tag `firebase-extensions` + `stripe`

## Prochaine étape

L'extension est installée et testée ! Explorez maintenant la structure du code : [Structure du projet](07_STRUCTURE_CODE.md)

