# STARTUP SIMULATOR - MASTER ROADMAP & MILESTONES

Questo documento definisce il piano di produzione dettagliato per **Startup Simulator**, con i relativi criteri di accettazione per ciascuna milestone.

---

## PANORAMICA DELLE 10 MILESTONE

```
[M1: Foundation] ➔ [M2: Tutorial Pizzeria] ➔ [M3: Core Sim] ➔ [M4: Office & Hardware]
      │
      ▼
[M5: Servers & Rack] ➔ [M6: Employees 3D] ➔ [M7: AI & SaaS] ➔ [M8: Co-op Multiplayer]
      │
      ▼
[M9: Steam Integration] ➔ [M10: Polish & Master Release]
```

---

## MILESTONE 1: FOUNDATION (IN CORSO)
**Obiettivo:** Creare il core del motore, il controller in prima persona, l'ambiente dello studio iniziale, il laptop interattivo e il sistema di salvataggio.
- [x] Configurazione repository Git (`startup-simulator`) e toolchain Godot 4.3.
- [x] Documentazione di ingegneria: `GAME_DESIGN_DOCUMENT.md`, `TECHNICAL_DESIGN.md`, `ROADMAP.md`.
- [ ] Pipeline di generazione asset 3D procedurale (`tools/asset_generator.py`) per produrre modelli `.glb` reali:
  - Studio iniziale (pareti, pavimento, finestra, porta).
  - Mobili (scrivania, sedia, scaffale).
  - Hardware (laptop 15" modellato con schermo e tastiera, mouse).
- [ ] Pipeline di sintesi audio (`tools/audio_synthesizer.py`) per suoni foley e UI (passi, click, tastiera, notifiche).
- [ ] Controller prima persona (`CharacterBody3D`) con telecamera, fisica, collisioni e raycast interattivo.
- [ ] Scena Studio 3D con illuminazione e skybox torinese.
- [ ] Interazione fisica col Laptop: seduta alla scrivania o apertura interfaccia OS ("TO-OS").
- [ ] HUD di gioco in prima persona (mirino reattivo, prompt di interazione contestuale, notifiche).
- [ ] Sistema di salvataggio atomico su file (`save_manager.gd`).

**Criteri di Accettazione M1:**
- Il giocatore avvia la scena, si muove fluidamente a 60 FPS nello studio, si avvicina al laptop, preme [E], vede il prompt interattivo e accede al sistema operativo TO-OS.

---

## MILESTONE 2: TUTORIAL VERTICAL SLICE (LA PIZZERIA TORINESE)
**Obiettivo:** Completare la prima esperienza giocabile end-to-end richiesta dal Game Director.
- [ ] Ambiente esterno: strada e quartiere torinese che collega lo Studio alla Pizzeria Da Mario (ciottoli, marciapiedi, facciate, lampioni).
- [ ] Ambiente interno: Pizzeria Da Mario (forno a legna, bancone, tavoli, profumo visivo, atmosfera calda).
- [ ] NPC Mario: personaggio 3D stilizzato con grembiule da pizzaiolo, animazione idle e sistema di dialogo interattivo.
- [ ] Sistema di contratti e briefing: Mario illustra la necessità di digitalizzare la sua pizzeria con un sito web.
- [ ] Minigioco WebForge: applicazione interattiva su laptop dove il giocatore assembla logo, menu delle pizze, orari, indirizzo torinese e pulsante di prenotazione.
- [ ] Sistema di valutazione: rating a stelle, calcolo qualità del lavoro e compenso economico (+ reputazione).
- [ ] Negozio e Reinvestimento: acquisto del secondo monitor o sedia ergonomica con consegna e collocazione fisica nello studio 3D.
- [ ] Menu principale professionale (Nuova Partita, Continua, Multiplayer, Impostazioni, Crediti, Esci).

**Criteri di Accettazione M2:**
- Il loop completo "Avvio -> Studio -> Laptop -> Strada -> Pizzeria -> Dialogo -> Ritorno Studio -> Minigioco Sito -> Consegna & Pagamento -> Acquisto Upgrade nello Studio" è giocabile e testato.

---

## MILESTONE 3: CORE SIMULATION & MARKETPLACE
- Marketplace freelance procedurale con decine di contratti diversificati.
- Ciclo giorno/notte e calendario con scadenze contrattuali e penalità per ritardo.
- Sistema economico esteso con spese fisse (affitto, bollette, internet).
- Eventi imprevisti di inizio carriera (richieste clienti frettolosi, piccoli blackout, bug da risolvere).

---

## MILESTONE 4: ARREDO UFFICIO ED ESPANSIONE HARDWARE
- Sistema di arredo libero "grid/free-placement" stile House Flipper.
- Assemblaggio PC modulare: case, alimentatore, scheda madre, CPU, banchi RAM, schede video GPU.
- Gestione cavi di alimentazione e monitor multipli funzionanti.

---

## MILESTONE 5: INFRASTRUTTURA & SERVER ROOM
- Modelli 3D e logica per Rack 19", server 1U/2U/4U, switch di rete, gruppi di continuità (UPS).
- Simulazione fisica termica ed energetica: monitoraggio calore, flussi d'aria e ventole RPM.
- Gestione guasti fisici (disco rotto, surriscaldamento, saturazione banda, ripristino backup).

---

## MILESTONE 6: DIPENDENTI E RUOLI OPERATIVI 3D
- NPC dipendenti autonomi con pathfinding e animazioni di lavoro, pausa caffè e socializzazione.
- Interfaccia di reclutamento (CV, colloqui, negoziazione stipendio).
- Assegnazione mansioni (Frontend, Backend, SysAdmin, Sales, QA) con produttività basata sul morale e sull'arredo dell'ufficio.

---

## MILESTONE 7: INTELLIGENZA ARTIFICIALE, AUTOMAZIONE & SAAS
- Strumenti IA operativi: AI Code Generator, AI Website Builder, AI Customer Bot.
- Gestione economica dei token e server GPU locali vs Cloud API.
- Creazione e lancio di prodotti proprietari (SaaS, software ristorazione PizzaCloud) con entrate ricorrenti da abbonamenti.

---

## MILESTONE 8: MULTIPLAYER CO-OP (1-4 GIOCATORI)
- Backend Host-Client con convalida autorevole lato host.
- Sincronizzazione fisica di posizioni, interazioni, arredi e terminali.
- Supporto connessione LAN locale con discovery automatica e connessione IP diretto / VPN.

---

## MILESTONE 9: INTEGRAZIONE STEAM & LOBBY
- Integrazione con Steamworks (richiede app ID dedicato).
- Steam P2P Networking, inviti amici della lista Steam e lobby private.

---

## MILESTONE 10: POLISH, BENCHMARK & DISTRIBUZIONE
- Profiling prestazionale (CPU frame time, VRAM, RAM footprint < 2.5GB).
- Localizzazione bilingue completa (Italiano & Inglese).
- Build desktop Windows (e Linux nativo) pronta per la distribuzione.
