# Clean Architecture - Invory

Questo progetto è stato riorganizzato seguendo i principi della Clean Architecture per migliorare la manutenibilità, testabilità e scalabilità del codice.

## Struttura del Progetto

```
lib/
├── core/                          # Core dell'applicazione
│   └── di/                       # Dependency Injection
│       └── injection_container.dart
├── data/                         # Data Layer
│   ├── datasources/              # Fonti dati (Firebase, API, etc.)
│   │   ├── firebaseauth_service.dart
│   │   └── firestore_service.dart
│   ├── models/                   # Modelli di dati (estendono le entità)
│   │   ├── product_model.dart
│   │   ├── fornitore_model.dart
│   │   └── user_model.dart
│   └── repositories/             # Implementazioni dei repository
│       ├── auth_repository_impl.dart
│       ├── product_repository_impl.dart
│       └── fornitore_repository_impl.dart
├── domain/                       # Domain Layer
│   ├── entities/                 # Entità di business (logica pura)
│   │   ├── product.dart
│   │   ├── fornitore.dart
│   │   └── user.dart
│   ├── repositories/             # Interfacce dei repository
│   │   ├── auth_repository.dart
│   │   ├── product_repository.dart
│   │   └── fornitore_repository.dart
│   └── usecases/                 # Use Cases (logica di business)
│       ├── auth/
│       │   └── login_usecase.dart
│       ├── product/
│       │   ├── get_products_usecase.dart
│       │   ├── add_product_usecase.dart
│       │   ├── update_product_usecase.dart
│       │   └── delete_product_usecase.dart
│       └── fornitore/
│           ├── get_fornitori_usecase.dart
│           ├── add_fornitore_usecase.dart
│           ├── update_fornitore_usecase.dart
│           └── delete_fornitore_usecase.dart
└── presentation/                 # Presentation Layer
    ├── providers/                # State Management (Provider)
    │   ├── auth_provider.dart
    │   ├── product_provider.dart
    │   └── fornitore_provider.dart
    ├── screens/                  # Schermate dell'app
    │   ├── login_page.dart
    │   ├── home_page.dart
    │   ├── dashboard_page.dart
    │   ├── prodotti_page.dart
    │   ├── addproductform.dart
    │   ├── ordinerapido.dart
    │   └── splash_screen.dart
    └── widgets/                  # Widget riutilizzabili
        ├── floating_navbar.dart
        ├── main_button.dart
        ├── product_card.dart
        ├── info_box.dart
        └── fornitore_dialog.dart
```

## Principi della Clean Architecture

### 1. Dependency Rule
- Le dipendenze puntano sempre verso l'interno
- Il Domain Layer non dipende da nessun altro layer
- Il Data Layer dipende solo dal Domain Layer
- Il Presentation Layer dipende solo dal Domain Layer

### 2. Separation of Concerns
- **Domain Layer**: Contiene la logica di business pura
- **Data Layer**: Gestisce i dati e l'accesso alle fonti esterne
- **Presentation Layer**: Gestisce l'interfaccia utente e lo stato

### 3. Entities (Domain Layer)
Le entità rappresentano gli oggetti di business e contengono:
- Proprietà immutabili
- Logica di business pura
- Nessuna dipendenza da framework esterni

### 4. Use Cases (Domain Layer)
I use cases rappresentano le operazioni che l'applicazione può eseguire:
- Ogni use case ha una singola responsabilità
- Contengono la logica di business specifica
- Non dipendono da framework esterni

### 5. Repository Pattern
- Interfacce definite nel Domain Layer
- Implementazioni nel Data Layer
- Permette di cambiare facilmente le fonti dati

### 6. Models (Data Layer)
I modelli estendono le entità e aggiungono:
- Metodi di serializzazione
- Factory methods per creare istanze da dati esterni
- Logica specifica per la persistenza

## Vantaggi della Clean Architecture

1. **Testabilità**: Ogni layer può essere testato indipendentemente
2. **Manutenibilità**: Cambiamenti in un layer non influenzano gli altri
3. **Scalabilità**: Facile aggiungere nuove funzionalità
4. **Indipendenza da Framework**: La logica di business è indipendente da Flutter/Firebase
5. **Separazione delle Responsabilità**: Ogni componente ha una responsabilità specifica

## Flusso dei Dati

1. **UI** → **Provider** → **Use Case** → **Repository** → **Data Source**
2. **Data Source** → **Repository** → **Use Case** → **Provider** → **UI**

## Prossimi Passi

1. Aggiornare i provider per utilizzare i use cases
2. Implementare la dependency injection con GetIt
3. Aggiungere test unitari per ogni layer
4. Implementare error handling centralizzato
5. Aggiungere logging e monitoring 