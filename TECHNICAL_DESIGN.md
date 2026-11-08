# STARTUP SIMULATOR - TECHNICAL DESIGN DOCUMENT (TDD)
**Versione:** 1.0.0  
**Target Engine:** Godot Engine 4.3 (GL Compatibility / Forward+)  
**Linguaggio di Sviluppo:** GDScript (Tipizzato rigorosamente con static typing)  
**Target Architetturale:** Host-Client Autorevole, Multi-piattaforma (Windows / Linux)  

---

## 1. ARCHITETTURA DEL PROGETTO E MODULI

Il codice segue principi di modularità estrema: disaccoppiamento tramite pattern a segnali (Signals), State Machine componibili e Singleton Autoload centralizzati ma specializzati.

```
/home/antigravity/startup-simulator
├── project.godot
├── export_presets.cfg
├── assets/
│   ├── characters/          # Mesh .glb e texture NPC/giocatore
│   ├── environments/        # Edifici, strade, portici torinesi, interni
│   ├── props/               # Laptop, monitor, server, scrivanie, cavi
│   ├── materials/           # Materiali StandardMaterial3D (PBR / Stylized)
│   ├── textures/            # Texture compresse (VRAM/Basis Universal)
│   ├── audio/               # Effetti sfx (WAV) e colonne sonore (OGG)
│   └── fonts/               # Typography moderna e pulita
├── scenes/
│   ├── main.tscn            # Bootstrapper principale & Scena Master
│   ├── world/
│   │   ├── district_torino.tscn  # Quartiere esplorabile (esterni)
│   │   ├── studio.tscn           # Studio iniziale / garage
│   │   └── pizzeria.tscn         # Interno Pizzeria Da Mario
│   ├── player/
│   │   └── player_character.tscn # Controller prima persona con camera & raycast
│   ├── ui/
│   │   ├── main_menu.tscn        # Menu principale con flow Multiplayer/Settings
│   │   ├── hud.tscn              # Mirino, prompt d'interazione, notifiche, orologio
│   │   ├── computer_screen.tscn  # OS simulato (TO-OS) per laptop/desktop
│   │   └── minigames/
│   │       └── web_forge.tscn    # Minigioco sviluppo sito web
│   └── props/
│       ├── laptop_prop.tscn      # Oggetto fisico 3D laptop interattivo
│       ├── monitor_prop.tscn     # Monitor aggiuntivo montabile
│       └── furniture_base.tscn   # Sistema modulare arredo
├── scripts/
│   ├── core/
│   │   ├── game_manager.gd       # Macchina a stati globale di gioco
│   │   ├── event_bus.gd          # Bus di eventi globale disaccoppiato
│   │   └── save_manager.gd       # Serializzazione atomica JSON/Resource
│   ├── player/
│   │   ├── player_controller.gd  # Movimento fisica, camera, head-bob, sprint
│   │   └── interaction_ray.gd    # Rilevamento oggetti interattivi & highlight
│   ├── economy/
│   │   ├── economy_manager.gd    # Valuta, entrate, uscite, storico transazioni
│   │   └── shop_manager.gd       # Catalogo hardware/arredo e logica acquisti
│   ├── contracts/
│   │   ├── contract_manager.gd   # Generazione e tracciamento contratti
│   │   └── contract_data.gd      # Risorsa di definizione contratto
│   ├── minigames/
│   │   └── web_forge_controller.gd # Logica composizione blocchi e scoring
│   ├── hardware/
│   │   ├── server_node.gd        # Statistiche server (CPU, RAM, Temp, Fan RPM)
│   │   └── rack_manager.gd       # Gestione rack, alimentazione e switch
│   └── network/
│       ├── network_manager.gd    # Astrazione ENet / LAN / Direct IP / Steam
│       └── sync_registry.gd      # Tracciamento sincronizzazione host-client
├── tools/
│   ├── asset_generator.py        # Pipeline di generazione procedurale asset 3D (.glb)
│   └── audio_synthesizer.py      # Generatore audio e foley nativo (WAV)
└── tests/
    ├── test_runner.gd            # Runner automatico per test headless
    ├── unit/
    │   ├── test_economy.gd
    │   ├── test_contracts.gd
    │   └── test_save_system.gd
    └── integration/
        └── test_vertical_slice.gd
```

---

## 2. AUTOLOAD SINGLETONS (ARCHITETTURA REATTIVA)

1. **`EventBus` (`scripts/core/event_bus.gd`):**
   - Segnali globali privi di dipendenze incrociate (`contract_accepted`, `contract_completed`, `funds_changed`, `interaction_started`, `interaction_ended`, `item_purchased`).
2. **`GameManager` (`scripts/core/game_manager.gd`):**
   - Gestisce gli stati del gioco (`MAIN_MENU`, `FIRST_PERSON_WORLD`, `USING_COMPUTER`, `IN_MINIGAME`, `PAUSED`).
   - Gestisce la transizione dinamica del mouse mode (`MOUSE_MODE_CAPTURED` per prima persona, `MOUSE_MODE_VISIBLE` per computer e UI).
3. **`EconomyManager` (`scripts/economy/economy_manager.gd`):**
   - Validazione delle transazioni lato Host.
   - Bilanciamento entrate, pagamenti ricorrenti (affitti, licenze, server).
4. **`ContractManager` (`scripts/contracts/contract_manager.gd`):**
   - Gestione del contratto attivo del tutorial (Pizzeria Da Mario) e pipeline procedurale per i contratti successivi.
5. **`SaveManager` (`scripts/core/save_manager.gd`):**
   - Salvataggio transazionale in `user://saves/savegame.json` con backup `.bak` preventivo e hashing SHA-256 anti-corruzione.
6. **`NetworkManager` (`scripts/network/network_manager.gd`):**
   - Wrap di `ENetMultiplayerPeer` configurato su porta default `7777`.
   - Supporto nativo per connessioni LAN, IP diretto e predisposizione API Steamworks.

---

## 3. CONTROLLER DI PRIMA PERSONA E SISTEMA DI INTERAZIONE

### 3.1 Movimento Fisico
- `CharacterBody3D` con collision capsule (`radius = 0.4m`, `height = 1.8m`).
- Fisiche realistiche: accelerazione, decelerazione a terra con attrito configurabile, salto reattivo, gravità personalizzata.
- Telecamera in prima persona montata su pivot collo a `height = 1.65m` con attenuazione head-bob durante la camminata e la corsa.

### 3.2 Sistema di Interazione Raycast Tattile
- `RayCast3D` allineato al centro visivo della camera con portata massima di 2.5 metri.
- Ogni oggetto interagibile implementa la classe o interfaccia `Interactable3D` con:
  - `prompt_message: String` (es. "[E] Usa Laptop", "[E] Parla con Mario", "[E] Apri Porta").
  - `func interact(player: CharacterBody3D) -> void`
  - Feedback visivo: attivazione di materiale outline o shader rimlight dinamico all'hover.

---

## 4. IL SISTEMA COMPUTER E MINIGIOCO WEBFORGE

### 4.1 "TO-OS" (Desktop Environment Simulato)
- Quando il giocatore interagisce con il laptop, la visuale passa fluidamente alla schermata del laptop, oppure viene aperta l'interfaccia a schermo intero del sistema operativo "TO-OS".
- Desktop moderno con:
  - Taskbar con orologio di gioco e stato connessione Wi-Fi.
  - Icona **Posta / Mail** (comunicazioni, feedback clienti).
  - Icona **Freelance Hub** (contratti e richieste della città).
  - Icona **WebForge IDE** (minigioco di sviluppo web).
  - Icona **Shop Hardware** (acquisto upgrade, monitor, sedie, server).
  - Icona **Banca / Contabilità** (resoconto entrate/uscite).

### 4.2 Minigioco WebForge (Tutorial Pizzeria)
- Griglia visiva con layout a blocchi:
  - Slot 1: **Header & Logo** (Scelta: Logo Mario con Mole Antonelliana).
  - Slot 2: **Hero Banner** (Slogan accattivante della pizzeria).
  - Slot 3: **Menu Sezione** (Inserimento pizze classiche e speciali).
  - Slot 4: **Orari & Dove Siamo** (Indirizzo torinese, mappa stilizzata).
  - Slot 5: **Modulo Prenotazione / Chiama** (CTA per i clienti).
- Algoritmo di validazione:
  - Calcola Completezza (0-100%), Coerenza del Design, Rispetto delle Richieste del Cliente e Tempo Impiegato.
  - Genera punteggio finale (1-5 stelle) che modula direttamente la ricompensa in Denaro (€) e Reputazione.

---

## 5. MODELLO MULTIPLAYER HOST-CLIENT AUTOREVOLE

- **Autorità Host:** Solo l'Host può approvare contratti, detrarre fondi ed emettere pagamenti. I client inviano richieste RPC (`@rpc("any_peer", "reliable")`) che l'host convalida prima di propagare i cambiamenti (`@rpc("authority", "reliable")`).
- **Sincronizzazione Spaziale:**
  - Posizione e rotazione giocatori sincronizzate via `MultiplayerSynchronizer` a 20-30 Hz con interpolazione locale.
  - Oggetti posizionabili (monitor, sedie, server) sincronizzati tramite ID univoci nel `SyncRegistry`.

---

## 6. GENERAZIONE ASSET E PIPELINE AUTOMATIZZATA

Per garantire modelli 3D e audio coerenti, professionali e privi di cubi/capsule provvisori:
1. **Pipeline 3D (`tools/asset_generator.py`):**
   - Genera direttamente modelli `.glb` low-poly ottimizzati con mesh geometriche corrette, UV mapping e materiali PBR (albedo, roughness, metallic, emissive per schermi e LED server).
   - Generazione di:
     - Personaggio stilizzato (Corpo, testa, vestiti da laureato / camice da pizzaiolo con grembiule).
     - Modelli dello Studio (mura, pavimento in parquet, finestra torinese con vista, scrivania in legno/metallo, sedia ufficio).
     - Modelli della Pizzeria (bancone bar, forno a legna circolare in mattoni refrattari con fiamma emissiva, tavoli in legno, sedie, cartoni pizza).
     - Componenti Tech (Laptop da 15" aperto con schermo emissivo, mouse ottico, tazza caffè, monitor secondario da 27" su braccio orientabile).
     - Architettura di Torino (Facciata edificio sabaudo, portici in pietra, lampione storico, marciapiede con tombino in ghisa).
2. **Pipeline Audio (`tools/audio_synthesizer.py`):**
   - Generazione di file audio PCM WAV 44.1kHz a 16-bit:
     - Passi su parquet e ciottoli (`footstep_wood.wav`, `footstep_stone.wav`).
     - Feedback UI (`ui_click.wav`, `ui_success.wav`, `ui_notification.wav`).
     - Suoni del laptop e ambiente (`keyboard_typing.wav`, `laptop_fan.wav`, `door_open.wav`, `cash_register.wav`).

---

## 7. QA, TESTING E AUTOMATED VERIFICATION

- Test suite con `tests/test_runner.gd` eseguibile sia in modalità headless (`godot --headless -s tests/test_runner.gd`) sia con rendering grafico virtuale (`xvfb-run -a godot`).
- Criteri di accettazione automatizzati per la Milestone 1 e Milestone 2:
  - Inizializzazione pulita senza crash o errori nello standard error.
  - Validazione della logica dell'economia (nessun overflow o valore negativo non autorizzato).
  - Ciclo completo del contratto Pizzeria testato end-to-end.
  - Verifica della persistenza salvataggi su disco con controllo integrità.
