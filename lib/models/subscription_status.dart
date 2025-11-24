/// Énumération des différents statuts d'abonnement possibles
/// Simplifie la gestion des états côté UI
enum SubscriptionStatus {
  /// Aucun abonnement
  none,
  
  /// Abonnement actif
  active,
  
  /// Paiement en retard (Stripe essaie de récupérer le paiement)
  pastDue,
  
  /// Abonnement annulé
  canceled,
}

/// Extension pour obtenir une description lisible du statut
extension SubscriptionStatusExtension on SubscriptionStatus {
  String get description {
    switch (this) {
      case SubscriptionStatus.none:
        return 'Aucun abonnement';
      case SubscriptionStatus.active:
        return 'Abonnement actif';
      case SubscriptionStatus.pastDue:
        return 'Paiement en retard';
      case SubscriptionStatus.canceled:
        return 'Abonnement annulé';
    }
  }

  /// Indique si l'utilisateur a accès aux fonctionnalités premium
  bool get hasAccess {
    return this == SubscriptionStatus.active;
  }
}

