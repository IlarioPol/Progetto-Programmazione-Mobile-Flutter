# Specifiche di Test e Verifica Regressione (`test.MD`)


## 1. Storico Modifiche e Verifiche Preliminari

Di seguito sono riportati gli interventi richiesti/applicati al codice e i relativi esiti di implementazione, che costituiscono la baseline da validare:


| **MOD-01** | Area Cliente / Area Prenotazioni Provider | Sostituzione del font e miglioramento della visibilità nel **box delle prenotazioni**. | Il testo attuale (bianco) risulta poco leggibile. Deve essere applicato un font ad alta leggibilità, più visibile e confortevole per l'occhio umano (con adeguato peso tipografico e contrasto) sia nell'area Cliente che nell'area Prenotazioni del Provider. | **Implementato (Da validare)** |

| **MOD-02** | Area Cliente (Sezione Prenotazioni) | Sostituzione della stringa `"Recensisci"` con `"Lascia una recensione"`. | Sostituzione **esclusiva** per l'occorrenza esatta `"Recensisci"` all'interno della sezione Prenotazioni del Cliente. Altre occorrenze fuori ambito non devono essere alterate. | **Implementato (Da validare)** |

| **MOD-03** | Profilo / Area Manager | Revisione, correzione ortografica e riscrittura delle descrizioni dei Manager. | Il registro linguistico deve risultare rigorosamente formale e professionale in tutte le viste associate ai Manager. | **Implementato (Da validare)** |

| **MOD-04** | Core / Stato Applicazione (Prenotazioni) | Aggiornamento istantaneo (real-time / near real-time) dello status delle prenotazioni e introduzione del refresh automatico. | I cambi di stato devono propagarsi senza riavvio o intervento manuale, supportati da un meccanismo di auto-refresh affidabile. | **Implementato (Da validare)** |

---

## 3. TASK OPERATIVO: Esecuzione Suite di Test Completa

### Obiettivo
Eseguire tutti i test necessari per certificare che le modifiche sopra elencate (**MOD-01**, **MOD-02**, **MOD-03**, **MOD-04**) siano attive e correttamente applicate, garantendo al contempo **zero regressioni sulla logica di business preesistente** (prenotazione servizi lato Cliente, aggiunta Provider lato Manager, gestione servizi lato Provider).

### Strategia di Esecuzione (Da meno robusti a più invasivi)

#### Fase 1: Test Leggeri — Analisi Statica e Unit/Widget Test (Bassa Invasività)
1. **Verifica Stringhe e Selettori (MOD-02):** Controllare tramite Widget Test che nella sezione Prenotazioni dell'area Cliente compaia esattamente `"Lascia una recensione"` e che la vecchia stringa `"Recensisci"` non sia più presente in quel contesto, verificando che non si verifichino overflow di testo (`RenderFlex overflow`) sui pulsanti.
2. **Verifica Tipografica e Leggibilità Box Prenotazioni (MOD-01):** Ispezionare il `TextStyle` e le proprietà visive del **box delle prenotazioni** sia nell'albero dei widget del Cliente che in quello del Provider. Confermare la sostituzione del precedente testo bianco poco visibile con il nuovo font ad alta leggibilità, verificando che famiglia, spessore (`fontWeight`), dimensione e contrasto cromatico garantiscano una lettura chiara e riposante per l'occhio umano.
3. **Verifica Contenuti Statici/Dinamici Manager (MOD-03):** Validare i testi delle descrizioni dei Manager verificando l'assenza di refusi, placeholder o registri informali.

#### Fase 2: Test Funzionali e di Stato — Reattività e Auto-Refresh (Media Invasività)
1. **Propagazione Real-Time (MOD-04):** Simulare la mutazione dello stato di una prenotazione (es. da *In attesa* a *Confermata* o *Annullata*) e verificare l'aggiornamento immediato della UI dentro il box delle prenotazioni senza interazione manuale.
2. **Ciclo di Vita Auto-Refresh (MOD-04):** Verificare che i timer, gli stream o i listener di auto-refresh si attivino correttamente all'apertura della schermata e vengano correttamente distrutti (`dispose`) all'uscita, evitando memory leak o chiamate di rete duplicate.

#### Fase 3: Test di Integrazione, End-to-End e Stress Test (Alta Invasività)
1. **Regressione Flusso Manager -> Provider:** Testare l'aggiunta di un nuovo Provider da parte del Manager e verificare che il nuovo profilo sia immediatamente operativo e associabile ai servizi.
2. **Regressione Flusso Cliente <-> Provider:** Eseguire il ciclo completo di prenotazione di un servizio (legale, medico, ecc.) da parte del Cliente, verificando la corretta renderizzazione del nuovo font nel box prenotazioni per entrambe le entità, la gestione dello stato da parte del Provider in tempo reale e il successivo invio della recensione tramite il pulsante aggiornato `"Lascia una recensione"`.
3. **Stress & Concurrency Test (MOD-04):** Simulare aggiornamenti rapidi e consecutivi dello stato delle prenotazioni durante il ciclo di auto-refresh per verificare l'assenza di race condition, blocchi della UI (frame drop) o stati incoerenti tra Cliente e Provider.

---

## 4. Deliverable Richiesto: `latest_test.MD`

Al termine dell'esecuzione della suite di test, generare un nuovo file denominato **`latest_test.MD`** contenente il report dettagliato dei risultati, strutturato come segue:

1. **Riepilogo Esecutivo:** Totale test eseguiti, passati, falliti ed eventuali warning.
2. **Dettaglio Esiti per Livello (Fase 1, Fase 2, Fase 3):**
   * ID Test e descrizione.
   * Esito (`PASS` / `FAIL`).
   * Componenti o file Flutter coinvolti.
   * Log di errore o stack trace (in caso di `FAIL`).
3. **Verifica Integrità Logica Core:** Conferma esplicita del corretto funzionamento dei tre ruoli (*Cliente*, *Manager*, *Provider*).
4. **Eventuali Fix Applicati:** Elenco delle correzioni apportate al codice qualora un test avesse evidenziato anomalie o regressioni.