# Progetto-Programmazione-Mobile-Flutter

**EasyBook** - Sistema Integrato per la Gestione di Prenotazioni Professionali sviluppato in Flutter con backend Firebase.

---

## 📂 Struttura del Codice Principale (`lib/`)

Il codice principale dell'applicazione risiede interamente nella cartella `lib/` ed è suddiviso secondo il pattern architetturale **MVVM (Model-View-ViewModel)** accoppiato a **Provider** per la gestione dello stato:

*   **`main.dart`**: Il punto di ingresso ufficiale dell'applicazione. Inizializza i binding di Flutter, configura l'SDK Firebase e avvia l'app iniettando i ViewModel globali nel widget tree (`MultiProvider`). Gestisce inoltre la navigazione basata sui ruoli utente (`MainNavigator`).
*   **`firebase_options.dart`**: Contiene le chiavi e i parametri di configurazione generati automaticamente per mappare i servizi Firebase (Auth, Firestore, Storage) sulla piattaforma mobile.
*   **`data/`**
    *   **`models/`**: Contiene le classi di dati (es. `user_role.dart`) che definiscono le entità e le logiche dei dati dell'app (Clienti, Professionisti, Manager).
*   **`ui/`**
    *   **`viewmodels/`**: I componenti che gestiscono la logica di business e fanno da tramite tra Firebase e le schermate. Troviamo:
        *   `auth_viewmodel.dart` (Registrazione, Login, Logout)
        *   `client_viewmodel.dart` (Gestione lato cliente)
        *   `provider_viewmodel.dart` (Gestione lato dipendente/professionista)
        *   `manager_viewmodel.dart` (Gestione lato amministratore del business)
    *   **`screens/`**: Le interfacce utente divise per aree tematiche e ruoli:
        *   `auth/`: Schermate di autenticazione (`login_screen.dart`, `register_screen.dart`).
        *   `client/`: Dashboard per i clienti e visualizzazione dettagli attività (`client_home_screen.dart`, `business_detail_screen.dart`).
        *   `provider/`: Dashboard per i professionisti dipendenti (`provider_home_screen.dart`).
        *   `manager/`: Dashboard per i manager e setup iniziale dell'attività (`manager_home_screen.dart`, `business_setup_screen.dart`).
        *   `profile/`: Schermata di gestione del profilo e cancellazione account (`profile_screen.dart`).

---

## 🚀 Come avviare l'app su Android Studio

Segui questi passaggi per avviare e testare l'applicazione mobile sul tuo computer:

### 1. Prerequisiti
Assicurati che Flutter sia correttamente configurato sul tuo sistema:
```sh
export PATH="$PATH:/Users/ilariopolidori/development/flutter/bin"
```

### 2. Sincronizzazione dei pacchetti
Prima del primo avvio, apri il terminale di Android Studio o esegui il comando per scaricare tutte le librerie necessarie (Firebase, Provider, ecc.):
```sh
flutter pub get
```

### 3. Avviare l'Emulatore Android
1. In Android Studio, apri il **Device Manager** (cliccando sull'icona del telefono nella barra laterale destra o andando su `Tools` -> `Device Manager`).
2. Trova il tuo emulatore (es. `Medium Phone API 36.1`).
3. Se l'emulatore dovesse risultare bloccato o dare l'errore *FATAL*, clicca sui **tre puntini verticali** alla fine della riga e seleziona **Cold Boot Now** per forzarne il riavvio pulito.

### 4. Selezione del Dispositivo ed Esecuzione
1. Nella barra superiore di Android Studio, individua il menu a tendina dei dispositivi (accanto al pulsante Play verde).
2. Assicurati che sia selezionato l'**Emulatore Android appena avviato** (o il tuo smartphone fisico collegato via USB) e **NON** la voce *macOS (desktop)*.
3. Apri il file `lib/main.dart`.
4. Clicca sul pulsante **Run (Triangolo Verde)** oppure premi `Shift + F10` per compilare ed avviare l'applicazione mobile.
