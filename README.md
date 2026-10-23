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

Segui questi passaggi generali per avviare e testare l'applicazione mobile sul tuo computer:

### 1. Prerequisiti
Assicurati di aver installato correttamente il **Flutter SDK** sul tuo computer e di aver configurato la variabile d'ambiente `PATH` seguendo la guida ufficiale di Flutter per il tuo sistema operativo (macOS, Windows o Linux).

### 2. Sincronizzazione dei pacchetti
Prima del primo avvio, apri il terminale integrato di Android Studio (o la tua shell di sistema) posizionandoti nella cartella principale del progetto ed esegui il comando per scaricare tutte le librerie necessarie (Firebase, Provider, ecc.):
```sh
flutter pub get
```

### 3. Avviare l'Emulatore Android
1. In Android Studio, apri il **Device Manager** (cliccando sull'icona del dispositivo nella barra laterale destra o andando su `Tools` -> `Device Manager`).
2. Avvia il tuo emulatore Android preconfigurato (es. un qualsiasi dispositivo virtuale con API 33 o successive).
3. Se l'emulatore dovesse risultare bloccato o dare l'errore *FATAL*, clicca sui **tre puntini verticali** alla fine della riga del dispositivo nel Device Manager e seleziona **Cold Boot Now** per forzarne un riavvio pulito.

### 4. Selezione del Dispositivo ed Esecuzione
1. Nella barra superiore di Android Studio, individua il menu a tendina per la selezione dei dispositivi (accanto al pulsante Play verde).
2. Assicurati che sia selezionato l'**Emulatore Android** appena avviato (o il tuo smartphone fisico collegato tramite cavo USB con il Debug USB attivo). *Evita di selezionare piattaforme desktop come macOS o Windows se desideri testare solo l'interfaccia mobile*.
3. Apri il file `lib/main.dart`.
4. Clicca sul pulsante **Run (Triangolo Verde)** oppure premi la scorciatoia da tastiera (`Shift + F10` su Windows/Linux, `Control + R` su macOS) per compilare ed avviare l'applicazione mobile.

---

## 🏗️ Architettura e Struttura Completa del Progetto

### 1. Ruolo delle cartelle native e di compilazione (`android/`, `ios/`, `build/`)

Anche se l'app è sviluppata interamente in Flutter/Dart, per girare sui dispositivi fisici o emulatori necessita dei progetti "ospiti" nativi:

* **`android/`**: È un progetto nativo Android gestito da Gradle. Contiene il manifest (`AndroidManifest.xml`) per la gestione dei permessi (es. connessione Internet, fotocamera), le icone dell'applicazione, le configurazioni di compilazione e le risorse grafiche di caricamento iniziale (come `launch_background.xml`, che gestisce la splash screen nativa prima che il motore Flutter sia pronto). L'entry point nativo è `MainActivity.kt`.
* **`ios/`**: È il corrispondente progetto nativo iOS gestito tramite Xcode e CocoaPods. Contiene `Info.plist` (per i permessi di sicurezza iOS), le icone per i vari formati Apple e il file `AppDelegate.swift`.
* **`build/`**: È la directory generata automaticamente durante i processi di compilazione (`flutter run` o `flutter build`). Contiene i file binari compilati (.apk, bundle, ecc.), le cache dei plugin e i file intermedi. È esclusa dal controllo versione (`.gitignore`) e può essere rimossa o rigenerata in qualsiasi momento con il comando `flutter clean`.

---

### 2. Albero del codice sorgente (`lib/`)

```text
lib/
├── firebase_options.dart       # Parametri di configurazione e connessione a Firebase
├── main.dart                   # Entry point, inizializzazione e navigazione primaria
│
├── data/
│   └── models/                 # [MODEL] Strutture dati dell'applicazione
│       ├── app_user.dart       # Dati profilo utente
│       ├── user_role.dart      # Enum/classificazione ruoli (Client, Provider, Manager)
│       ├── business.dart       # Attività commerciale/negozio
│       ├── service.dart        # Servizi offerti (prezzo, durata, ecc.)
│       ├── booking.dart        # Prenotazioni degli utenti
│       ├── availability.dart   # Orari di disponibilità
│       └── review.dart         # Recensioni dei clienti
│
└── ui/
    ├── viewmodels/             # [VIEWMODEL] Logica di business e connessione a Firebase
    │   ├── auth_viewmodel.dart     # Registrazione, Login, Logout, stato sessione
    │   ├── client_viewmodel.dart   # Ricerca attività, prenotazioni lato cliente
    │   ├── provider_viewmodel.dart # Gestione appuntamenti del professionista dipendente
    │   └── manager_viewmodel.dart  # Configurazione negozio, orari, servizi, dipendenti
    │
    └── screens/                # [VIEW] Schermate utente (Widget UI)
        ├── auth/               # Login, Registrazione
        ├── client/             # Dashboard cliente, Dettaglio negozio e prenotazione
        ├── provider/           # Dashboard professionista dipendente
        ├── manager/            # Dashboard manager e setup iniziale attività
        └── profile/            # Profilo utente e logout
```

---

### 3. Come Funziona il Flusso dell'Applicazione

1. **Inizializzazione (`main.dart`)**:
   * All'avvio viene eseguita la funzione `main()`, che inizializza i binding di Flutter e configura la connessione ai servizi cloud tramite `firebase_options.dart`.
   * Viene registrato nel widget tree un `MultiProvider`, rendendo accessibili a tutte le schermate i 4 ViewModel (`AuthViewModel`, `ClientViewModel`, `ProviderViewModel`, `ManagerViewModel`).

2. **Controllo dell'Autenticazione e Routing per Ruolo (`MainNavigator`)**:
   * Il navigatore principale monitora lo stato della sessione tramite `AuthViewModel`:
     * **Utente non autenticato**: Mostra `LoginScreen` o `RegisterScreen`.
     * **Utente autenticato**: Recupera il ruolo associato al profilo da Cloud Firestore (`UserRole`) e carica l'interfaccia corretta:
       * **Cliente (`client`)**: Viene indirizzato su `ClientHomeScreen`.
       * **Professionista (`provider`)**: Viene indirizzato su `ProviderHomeScreen`.
       * **Manager (`manager`)**: Se l'attività commerciale non è ancora stata configurata apre `BusinessSetupScreen`, altrimenti reindirizza alla dashboard `ManagerHomeScreen`.

3. **Ciclo Reattivo dei Dati (MVVM + Provider + Firebase)**:
   * **View (Schermata)**: Raccoglie le interazioni dell'utente (es. prenotazione di un servizio, login, cambio orari) e delega l'azione al relativo **ViewModel**.
   * **ViewModel**: Gestisce la logica di business ed effettua le operazioni asincrone verso **Firebase** (Auth, Firestore, Storage). Al termine dell'operazione, notifica i cambiamenti con `notifyListeners()`.
   * **Reattività della UI**: Tutti i widget in ascolto tramite `Consumer` o `context.watch()` si ricostruiscono automaticamente per riflettere le modifiche in tempo reale.
