# 📦 Invory

**Invory** è un'app mobile Flutter progettata per la gestione di un piccolo magazzino. Permette di aggiungere, monitorare e ricevere notifiche sui prodotti in stock. L'app è pensata per essere semplice, veloce ed efficace, ideale per negozi, laboratori o piccole attività.

## 🚀 Funzionalità principali

- ✅ Aggiunta rapida dei prodotti con nome, quantità, soglia minima, descrizione.
- 📉 Visualizzazione prodotti esauriti o sotto soglia.
- 🔔 Notifiche locali automatiche sui prodotti critici.
- 🏠 Interfaccia divisa in 3 schermate principali: Home, Aggiungi, Prodotti.
- 📆 Data corrente mostrata nella home.
- 📱 UI moderna e intuitiva.
- 🔄 Aggiornamento in tempo reale dopo l'aggiunta o modifica dei prodotti.

## 📸 Screenshot

*(Inserisci qui gli screenshot delle tre schermate principali: Home, Aggiungi prodotto, Lista prodotti)*

## 📁 Struttura del progetto

lib/
├── main.dart
├── models/
│ └── product.dart
├── services/
│ └── notification_service.dart
├── screens/
│ ├── home_page.dart
│ ├── add_product_page.dart
│ └── product_list_page.dart
├── widgets/
│ └── product_card.dart
└── providers/
└── product_provider.dart

markdown
Copia
Modifica

## 🔔 Notifiche

Le notifiche push **locali** vengono attivate all'avvio dell'app (nel `initState` della `HomePage`) e avvisano l'utente in caso di:

- ❌ Prodotti esauriti (quantità = 0)
- ⚠️ Prodotti sotto soglia (quantità ≤ soglia minima)

Le notifiche usano la libreria [`flutter_local_notifications`](https://pub.dev/packages/flutter_local_notifications).

# Funzionalità Analitiche

L'app include una dashboard analitica che mostra:
- **Top 5 prodotti consumati** (grafico a barre)
- **Distribuzione per categoria** (grafico a torta)
- **Spesa mensile totale** (grafico a linee)

## Come vengono calcolate le metriche

- **Top 5 prodotti consumati**: vengono ordinati tutti i prodotti in base al campo `consumati` (totale quantità consumata) e vengono mostrati i primi 5.
- **Distribuzione per categoria**: per ogni categoria, si somma il campo `consumati` di tutti i prodotti appartenenti a quella categoria. Il risultato è la distribuzione percentuale dei consumi per categoria.
- **Spesa mensile totale**: per ogni prodotto, si calcola `consumati * prezzoUnitario` e si aggrega per mese (usando il campo `ultimaModifica` come riferimento temporale). Il risultato è la spesa totale per ogni mese.

I dati sono aggregati dal provider direttamente dalla collezione prodotti e visualizzati con grafici moderni tramite la libreria fl_chart. Le metriche si aggiornano in tempo reale ogni volta che i dati dei prodotti cambiano.

Queste funzioni permettono di monitorare rapidamente l'andamento del magazzino e ottimizzare gli acquisti.

🛠️ Come avviare l'app
Clona il repository:
git clone https://github.com/tuo-username/stockly.git

Installa le dipendenze:
flutter pub get

Avvia l'app:
flutter run

👨‍💻 Autore
Sviluppato con ❤️ da Roberto – Studente e sviluppatore Flutter junior.

Se ti piace il progetto, lascia una ⭐ su GitHub o contattami per collaborazioni!

# Changelog 2025

- Refactoring modello Product: aggiunti categoria, prezzoUnitario, consumati, ultimaModifica.
- Dashboard analitica: top 5 prodotti consumati, distribuzione per categoria, spesa mensile totale.
- Provider aggiornato per aggregazioni e performance.
- UI e form modernizzati e coerenti.
- Query Firestore ottimizzate e coerenti con il nuovo modello.
- Rimozione campo fornitore e metodi toJson/fromJson.
- Best practice di sviluppo e manutenzione documentate.

# Aggiornamenti 2025

- L'app si chiama ora **Stockly**.
- Refactoring completo del modello Product: aggiunti categoria, prezzoUnitario, consumati, ultimaModifica.
- Dashboard analitica con grafici moderni (fl_chart): top 5 prodotti consumati, distribuzione per categoria, spesa mensile totale.
- Provider aggiornato per aggregazioni e performance.
- UI e form modernizzati e coerenti.
- Query Firestore ottimizzate e coerenti con il nuovo modello.
- Tutti gli import ora sono `package:stockely/...`.

# Esempi di utilizzo funzioni

## Ottenere metriche dal provider

```dart
final provider = Provider.of<ProductProvider>(context);

// Top 5 prodotti consumati
final topProducts = provider.topConsumati();

// Distribuzione per categoria
final categoryDist = provider.distribuzionePerCategoria();

// Spesa mensile totale
final monthlyExpense = provider.spesaMensile();
```

## Modificare/estendere le funzioni

- Per cambiare la logica di aggregazione, modifica i metodi in `product_provider.dart`.
- Per aggiungere nuove metriche, crea nuovi metodi che aggregano i dati della lista `prodotti`.
- Per visualizzare nuove metriche nella dashboard, aggiungi una nuova Card e il relativo grafico in `dashboard_page.dart`.

Esempio: aggiungere una metrica "prodotti mai consumati":
```dart
List<Product> maiConsumati() {
  return prodotti.where((p) => p.consumati == 0).toList();
}
```

Integra la funzione nella dashboard come vuoi!

