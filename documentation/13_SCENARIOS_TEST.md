# 13 - Scénarios de test

## Scénario 1 : Inscription et connexion

### Test 1.1 : Inscription réussie

**Étapes :**
1. Lancer l'application
2. Cliquer sur "S'inscrire"
3. Saisir :
   - Email : `test1@example.com`
   - Mot de passe : `password123`
4. Cliquer sur "S'inscrire"

**Résultat attendu :**
- Navigation automatique vers HomeScreen
- Firebase Auth : utilisateur créé
- Firestore : document `users/{uid}` créé avec email et createdAt

### Test 1.2 : Email déjà utilisé

**Étapes :**
1. Essayer de créer un compte avec un email existant

**Résultat attendu :**
- Message d'erreur : "email-already-in-use"
- Pas de navigation
- SnackBar rouge avec message clair

### Test 1.3 : Mot de passe trop court

**Étapes :**
1. Saisir un mot de passe de moins de 6 caractères
2. Tenter de s'inscrire

**Résultat attendu :**
- Validation côté client : message sous le champ
- Pas d'appel à Firebase
- Bouton désactivé ou erreur affichée

### Test 1.4 : Connexion réussie

**Étapes :**
1. Se déconnecter si connecté
2. Cliquer sur "Se connecter"
3. Saisir identifiants valides
4. Cliquer sur "Se connecter"

**Résultat attendu :**
- Navigation vers HomeScreen
- Statut d'abonnement affiché

### Test 1.5 : Mauvais mot de passe

**Étapes :**
1. Saisir un email valide mais mauvais mot de passe
2. Tenter de se connecter

**Résultat attendu :**
- Message d'erreur : "wrong-password"
- Pas de navigation
- Utilisateur reste sur LoginScreen

## Scénario 2 : Abonnement - Paiement réussi

### Test 2.1 : Flux complet d'abonnement

**Étapes :**
1. Se connecter
2. Vérifier HomeScreen affiche "Aucun abonnement"
3. Cliquer sur "Débloquer Premium"
4. Vérifier affichage de PaywallScreen
5. Cliquer sur "S'abonner maintenant"
6. Attendre 2-5 secondes
7. Vérifier ouverture de Stripe Checkout
8. Sur Stripe Checkout, saisir :
   - Carte : `4242 4242 4242 4242`
   - Date : `12/34`
   - CVC : `123`
   - Email : (pré-rempli)
9. Cliquer sur "Payer"
10. Attendre redirection
11. Retourner dans l'app (manuel ou automatique)

**Résultat attendu :**
- Checkout s'ouvre dans le navigateur
- Paiement accepté par Stripe
- Stripe Dashboard : paiement visible
- Firestore : document `subscriptions/{subId}` créé
- HomeScreen : statut passe à "Abonnement actif"
- Bouton devient "Accéder aux fonctionnalités Premium"

**Vérifications Firestore :**
```
users/{uid}/checkout_sessions/{sessionId}
  ✓ url présente
  
users/{uid}/subscriptions/{subId}
  ✓ status: "active"
  ✓ current_period_end : timestamp futur
```

**Vérifications Stripe Dashboard :**
```
Customers
  ✓ Client créé avec bon email
  
Subscriptions
  ✓ Abonnement actif
  ✓ Prochain paiement : dans 1 mois
  
Payments
  ✓ Paiement de 19 € réussi
```

### Test 2.2 : Accès au contenu premium

**Étapes :**
1. Après abonnement réussi
2. Cliquer sur "Accéder aux fonctionnalités Premium"
3. Vérifier affichage de PremiumScreen

**Résultat attendu :**
- PremiumScreen s'affiche
- Badge premium visible
- 3 fonctionnalités listées
- Bouton "Gérer mon abonnement" visible

## Scénario 3 : Gestion de l'abonnement

### Test 3.1 : Ouvrir le portail client

**Étapes :**
1. Sur PremiumScreen
2. Cliquer sur "Gérer mon abonnement"
3. Attendre 2-5 secondes

**Résultat attendu :**
- Portail client Stripe s'ouvre dans le navigateur
- Affiche :
  - Abonnement actuel
  - Prochaine facturation
  - Moyen de paiement
  - Historique des factures

### Test 3.2 : Annuler l'abonnement (fin de période)

**Étapes :**
1. Dans le portail client
2. Cliquer sur "Annuler l'abonnement"
3. Sélectionner "À la fin de la période"
4. Confirmer
5. Retourner dans l'app

**Résultat attendu :**
- Firestore : `cancel_at_period_end: true`
- HomeScreen : message "Abonnement sera annulé le [date]"
- Accès premium : encore actif jusqu'à la date
- Stripe Dashboard : abonnement marqué "cancel at period end"

### Test 3.3 : Mettre à jour la carte bancaire

**Étapes :**
1. Dans le portail client
2. Cliquer sur "Mettre à jour le moyen de paiement"
3. Saisir nouvelle carte test : `4000 0027 6000 3184`
4. Sauvegarder

**Résultat attendu :**
- Stripe Dashboard : nouvelle carte enregistrée
- Prochain paiement utilisera la nouvelle carte

## Scénario 4 : Paiements échoués

### Test 4.1 : Première souscription avec carte déclinée

**Étapes :**
1. Flux d'abonnement standard
2. Sur Stripe Checkout, utiliser carte : `4000 0000 0000 0002`
3. Tenter de payer

**Résultat attendu :**
- Stripe affiche "Votre carte a été déclinée"
- Pas de création d'abonnement
- Pas de document dans Firestore subscriptions
- Utilisateur reste sur Checkout (peut réessayer)

### Test 4.2 : Simuler renouvellement échoué

**Note :** Difficile à tester en temps réel (nécessite d'attendre 1 mois)

**Alternative : Test avec Stripe CLI**
```bash
stripe trigger invoice.payment_failed
```

**Résultat attendu :**
- Firestore : `status: "past_due"`
- HomeScreen : affiche "Paiement en retard"
- Email envoyé par Stripe à l'utilisateur

## Scénario 5 : États transitoires

### Test 5.1 : 3D Secure

**Étapes :**
1. Flux d'abonnement standard
2. Utiliser carte : `4000 0025 0000 3155`
3. Stripe affiche modal d'authentification
4. Cliquer sur "Autoriser"

**Résultat attendu :**
- Modal 3D Secure apparaît
- Après autorisation : paiement réussi
- Abonnement créé normalement

### Test 5.2 : Annulation pendant Checkout

**Étapes :**
1. Flux d'abonnement standard
2. Sur Stripe Checkout, cliquer sur "← Retour"
3. Ou fermer l'onglet

**Résultat attendu :**
- Pas d'abonnement créé
- Pas de paiement
- Firestore : pas de document subscription
- Utilisateur peut réessayer

## Scénario 6 : Déconnexion et reconnexion

### Test 6.1 : Persistance de l'abonnement

**Étapes :**
1. S'abonner (abonnement actif)
2. Se déconnecter
3. Se reconnecter avec le même compte

**Résultat attendu :**
- HomeScreen affiche immédiatement "Abonnement actif"
- Accès premium toujours disponible
- Données synchronisées depuis Firestore

### Test 6.2 : Multi-appareil

**Étapes :**
1. S'abonner sur appareil A
2. Se connecter avec le même compte sur appareil B

**Résultat attendu :**
- Appareil B voit immédiatement l'abonnement actif
- Firestore synchronise en temps réel

## Scénario 7 : Tests de performance

### Test 7.1 : Temps de création session Checkout

**Mesure :**
- Du clic "S'abonner" à l'ouverture de Checkout

**Résultat attendu :**
- < 5 secondes
- Indicateur de chargement visible

### Test 7.2 : Temps de synchronisation après paiement

**Mesure :**
- Du clic "Payer" sur Stripe à la mise à jour de l'UI

**Résultat attendu :**
- < 10 secondes
- StreamBuilder met à jour automatiquement

## Checklist de tests

Avant de déployer en production :

**Authentification**
- [ ] Inscription avec email valide
- [ ] Inscription avec email invalide (erreur)
- [ ] Connexion avec bons identifiants
- [ ] Connexion avec mauvais identifiants (erreur)
- [ ] Déconnexion

**Abonnement**
- [ ] Création session Checkout
- [ ] Paiement avec carte test réussie
- [ ] Paiement avec carte déclinée (erreur)
- [ ] Synchronisation statut dans Firestore
- [ ] Mise à jour UI automatique

**Gestion**
- [ ] Ouverture portail client
- [ ] Annulation fin de période
- [ ] Annulation immédiate
- [ ] Mise à jour carte bancaire

**États**
- [ ] Aucun abonnement → Paywall
- [ ] Abonnement actif → Premium
- [ ] Abonnement annulé → Paywall

**Persistance**
- [ ] Déconnexion / reconnexion
- [ ] Fermeture / réouverture app
- [ ] Multi-appareil

## Prochaine étape

Apprendre à déboguer : [Débogage et logs](14_DEBOGAGE.md)

