# Diagrammes Mermaid - Architecture et Flux

## Diagramme 1 : Architecture globale

```mermaid
graph TB
    A[Utilisateur] -->|1. Crée compte| B[Flutter App]
    B -->|2. Authentifie| C[Firebase Auth]
    C -->|3. Token JWT| B
    B -->|4. Stocke profil| D[Firestore]
    B -->|5. Clic S'abonner| E[Extension Firebase Stripe]
    E -->|6. Crée session| F[Stripe API]
    F -->|7. Retourne URL| E
    E -->|8. Écrit URL| D
    B -->|9. Lit URL| D
    B -->|10. Ouvre| G[Stripe Checkout]
    A -->|11. Paie| G
    G -->|12. Webhook| E
    E -->|13. Crée subscription| D
    D -->|14. Stream| B
    B -->|15. Affiche actif| A

    style A fill:#e1f5ff
    style B fill:#fff4e6
    style C fill:#f3e5f5
    style D fill:#e8f5e9
    style E fill:#fff3e0
    style F fill:#fce4ec
    style G fill:#e0f2f1
```

## Diagramme 2 : Flux d'inscription

```mermaid
sequenceDiagram
    participant U as Utilisateur
    participant F as Flutter App
    participant FA as Firebase Auth
    participant FS as Firestore

    U->>F: Saisit email/password
    F->>F: Valide formulaire
    F->>FA: signUpWithEmail()
    FA->>FA: Crée compte + génère UID
    FA-->>F: UserCredential + UID
    F->>FS: Crée document users/{uid}
    FS-->>F: Confirmation
    F->>U: Navigation vers HomeScreen
```

## Diagramme 3 : Flux de paiement complet

```mermaid
sequenceDiagram
    participant U as Utilisateur
    participant FL as Flutter
    participant FS as Firestore
    participant EX as Extension Stripe
    participant ST as Stripe API
    participant BR as Navigateur

    Note over U,BR: PHASE 1: Création session Checkout
    U->>FL: Clic "S'abonner"
    FL->>FS: Crée checkout_sessions/{id}<br/>price: price_xxx<br/>mode: subscription
    FS-->>FL: Document créé
    
    Note over FS,ST: PHASE 2: Extension génère URL
    FS->>EX: Trigger onCreate
    EX->>ST: stripe.checkout.sessions.create()
    ST-->>EX: URL de checkout
    EX->>FS: Ajoute URL au document
    
    Note over FL,BR: PHASE 3: Paiement
    FL->>FS: Lit le document (polling)
    FS-->>FL: Document avec URL
    FL->>BR: Ouvre URL
    BR-->>U: Page Stripe Checkout
    U->>BR: Saisit carte 4242...
    BR->>ST: Soumet paiement
    ST->>ST: Traite paiement
    
    Note over ST,FL: PHASE 4: Synchronisation
    ST->>EX: Webhook subscription.created
    EX->>EX: Vérifie signature
    EX->>FS: Crée subscriptions/{subId}<br/>status: active
    FS->>FL: Stream émet changement
    FL->>U: Affiche "Abonnement actif"
```

## Diagramme 4 : Structure Firestore

```mermaid
graph TB
    A[Collection: users] -->|Document| B["{uid}"]
    B --> C[email: string]
    B --> D[createdAt: timestamp]
    B --> E[stripeId: string]
    
    B -->|Sous-collection| F[checkout_sessions]
    F -->|Document| G["{sessionId}"]
    G --> H[price: string]
    G --> I[url: string]
    G --> J[mode: subscription]
    
    B -->|Sous-collection| K[subscriptions]
    K -->|Document| L["{subscriptionId}"]
    L --> M[status: active]
    L --> N[current_period_end: int]
    L --> O[items: array]
    
    B -->|Sous-collection| P[payments]
    P -->|Document| Q["{paymentId}"]
    Q --> R[amount: int]
    Q --> S[currency: string]
    Q --> T[status: succeeded]

    style A fill:#e8f5e9
    style B fill:#c8e6c9
    style F fill:#fff9c4
    style K fill:#b2dfdb
    style P fill:#ffccbc
```

## Diagramme 5 : États d'abonnement

```mermaid
stateDiagram-v2
    [*] --> incomplete: Paiement initial
    incomplete --> active: Paiement réussi
    incomplete --> incomplete_expired: Échec après 23h
    
    active --> past_due: Échec renouvellement
    active --> canceled: Annulation
    
    past_due --> active: Paiement réussi
    past_due --> unpaid: Tous paiements échouent
    
    unpaid --> canceled: Définitif
    canceled --> [*]
    incomplete_expired --> [*]
    
    note right of active
        Accès premium: OUI
    end note
    
    note right of past_due
        Accès premium: À définir
    end note
    
    note right of canceled
        Accès premium: NON
    end note
```

## Diagramme 6 : Composants Flutter

```mermaid
graph LR
    A[main.dart] --> B[AuthGate]
    B -->|Non connecté| C[LoginScreen]
    B -->|Connecté| D[HomeScreen]
    
    C --> E[AuthService]
    E --> F[Firebase Auth]
    
    D --> G[SubscriptionService]
    G --> H[Firestore]
    
    D -->|Pas abonné| I[PaywallScreen]
    D -->|Abonné| J[PremiumScreen]
    
    I --> G
    J --> G
    
    style A fill:#fff4e6
    style B fill:#e1f5ff
    style E fill:#f3e5f5
    style G fill:#e8f5e9
```

## Diagramme 7 : Vérification du statut

```mermaid
sequenceDiagram
    participant HS as HomeScreen
    participant SS as SubscriptionService
    participant FS as Firestore
    participant UI as Interface

    HS->>SS: getSubscriptionStatus()
    SS->>FS: Stream sur subscriptions
    
    loop Écoute temps réel
        FS-->>SS: Snapshot des documents
        SS->>SS: Parse status
        SS-->>HS: SubscriptionStatus enum
        HS->>UI: Affiche selon statut
    end
    
    Note over HS,UI: Mise à jour automatique<br/>quand Firestore change
```

## Diagramme 8 : Configuration complète

```mermaid
graph TB
    subgraph "1. Configuration Firebase"
    A1[Créer projet] --> A2[Activer Auth]
    A2 --> A3[Créer Firestore]
    A3 --> A4[Configurer règles]
    A4 --> A5[flutterfire configure]
    end
    
    subgraph "2. Configuration Stripe"
    B1[Créer compte] --> B2[Mode TEST]
    B2 --> B3[Créer produit]
    B3 --> B4[Copier Price ID]
    B4 --> B5[Copier Secret Key]
    B5 --> B6[Mettre à jour code]
    end
    
    subgraph "3. Extension Firebase"
    C1[Installer extension] --> C2[Configurer clés]
    C2 --> C3[Attendre 5 min]
    C3 --> C4[Vérifier Functions]
    C4 --> C5[Vérifier Webhooks]
    end
    
    A5 --> C1
    B6 --> C2
    C5 --> D[flutter run]
    
    style A1 fill:#e8f5e9
    style B1 fill:#fff3e0
    style C1 fill:#e1f5ff
    style D fill:#c8e6c9
```

## Comment lire ces diagrammes

### Diagramme 1 - Architecture
Montre la vue d'ensemble des composants et leur interaction.

### Diagramme 2 - Inscription
Séquence détaillée de création de compte.

### Diagramme 3 - Paiement
Le flux le plus important : de l'abonnement au paiement réussi.

### Diagramme 4 - Firestore
Structure des données dans la base de données.

### Diagramme 5 - États
Machine à états des abonnements Stripe.

### Diagramme 6 - Flutter
Architecture des composants Flutter de l'app.

### Diagramme 7 - Vérification
Comment l'app vérifie le statut en temps réel.

### Diagramme 8 - Configuration
Les 3 étapes de setup dans l'ordre.

