# 🎮 STARTUP SIMULATOR

[![Engine: Godot 4.3](https://img.shields.io/badge/Engine-Godot_4.3-478cbf?logo=godotengine&logoColor=white)](https://godotengine.org)
[![Platform: Windows Desktop](https://img.shields.io/badge/Platform-Windows_x86__64-0078d7?logo=windows&logoColor=white)](https://github.com/MirkoVanzetto/startup-simulator/tree/main/build)
[![Version: v1.6.0 Miniera Alpina & Animations](https://img.shields.io/badge/Version-v1.6.0_Miniera_Alpina-success)](https://github.com/MirkoVanzetto/startup-simulator/blob/main/ROADMAP.md)

**Startup Simulator** è un simulatore gestionale in prima persona in 3D ambientato in una versione contemporanea e stilizzata di **Torino, Italia**.  
Interpreti un neo-laureato in Informatica con 110 e Lode che parte dal proprio garage con **120 €** fino a costruire una vera impresa tecnologica industriale.

---

## ⬇️ DOWNLOAD PLAYABLE DEMO (WINDOWS .EXE — v1.6.0)

Puoi scaricare l'eseguibile giocabile aggiornato direttamente da GitHub ai seguenti link:

- 📦 **[Scarica Archivio Completo ZIP (Consigliato - Windows x86_64)](https://github.com/MirkoVanzetto/startup-simulator/raw/main/build/StartupSimulator_Windows_x86_64.zip)**  
  *(Include `StartupSimulator.exe`, `StartupSimulator.pck` e `README_PLAYABLE.txt`)*

- ⚡ **[Scarica direttamente StartupSimulator.exe](https://github.com/MirkoVanzetto/startup-simulator/raw/main/build/StartupSimulator.exe)**  
  *(Richiede anche il file di risorse [StartupSimulator.pck](https://github.com/MirkoVanzetto/startup-simulator/raw/main/build/StartupSimulator.pck) nella stessa cartella)*

- 📁 **[Sfoglia la cartella build/ su GitHub](https://github.com/MirkoVanzetto/startup-simulator/tree/main/build)**

---

## 📸 SCREENSHOT & ANTEPRIMA GRAFICA 3D

| Scena Prologo & Laurea | Studio & Setup Iniziale | Miniera Alpina · Val di Susa | Lab Droni & Incubatore Torino | WebForge IDE & TO-OS 26.4 |
| :---: | :---: | :---: | :---: | :---: |
| Prologo narrativo interattivo | Scrivania, laptop, letto, frigo e server rack | Galleria 01, carrello su rotaia, Raffineria, Gru & Robot MK1/MK2 | Banco 3D 7 fasi TO-Drone MK1, Piazzola H e Terminale CEO | IDE visuale, Albero R&D 6 rami e gestione azienda |

---

## ⌨️ COMANDI DI GIOCO

| Tasto | Azione |
| :--- | :--- |
| **W, A, S, D** | Movimento del personaggio nello spazio 3D (potenziato con Bici Tech / Auto EV) |
| **Mouse** | Controllo orientamento telecamera |
| **E / Click Sinistro** | Interazione tattile (Laptop, NPC, Estrazione, Robot, Drone, Negozi, Fermate GTT) |
| **Spazio** | Salto |
| **Shift Sinistro** | Scatto / Corsa rapida |
| **TAB** | Zaino, Materiali Tecnologici & Mobilità Urbana |
| **CAPS LOCK / M** | Mappa Interattiva di Torino (20 POI · Tab Miniera) & Segnavia GPS 3D |
| **B** | Modalità Arredo libero in Studio |
| **ESC** | Menu di Pausa (Salva, Carica, Opzioni, Riprendi) / Chiudi TO-OS |

---

## 🚀 NOVITÀ v1.6.0 — MINIERA ALPINA VAL DI SUSA & ANIMAZIONI TORINO VIVA

1. **Nuova Area Dedicata — Miniera Alpina · Polo Estrattivo Val di Susa (Nord-Ovest oltre Parco Valentino):**
   - Raggiungibile dall'arco nord di Parco Valentino Ovest e dalla nuova 5ª fermata bus GTT (`BusStop_Miniera`): cava alpina circondata dalle Alpi, **Galleria Estrattiva 01** con carrello minerario animato su rotaie, **3 filoni cristallini** (`Rame`, `Silicio`, `Terre Rare`, ecc.), **Gru di cava rotante**, **Ufficio di cava**, **Raffineria** con ruota frantumatrice e fornace accesa, e `Capocava Ing. Dario Ferrero` (gilet alta visibilità + elmetto).
2. **Animazioni Complete su Pedoni, NPC, Veicoli, Macchinari & Droni (`v1.6.0`):**
   - **Pedoni 3D MakeHuman reali**: passo sincronizzato (`"Walk"`/`"Idle"`), contatto a terra (`Y = 0.0`) e rotazione verso il waypoint prima di muoversi (zero effetto slittamento).
   - **NPC, Veicoli & Macchinari Industriali**: animazioni `"Interact"` su NPC/commercianti, 4 ruote rotanti + curve fluide sui veicoli, animazioni continue `MineOpsAnimator` su `MineCart`, `ConveyorBelt`, `QuarryCrane`, `CrusherWheel`, trapani dei Mining Robot MK1/MK2 con scintille e volo autonomo del `TO-Drone MK1` con 4 rotori indipendenti.
3. **Albero R&D a 6 Rami, Droni, Fase 4 CEO & Dipendenti Autonomi (`v1.5.0+`):**
   - Ricerca Tecnologica a 6 rami con `🔬 Crediti di Ricerca (RC)`, assemblaggio fisico 3D in 7 fasi del `TO-Drone MK1` al Lab Droni di Borgo Po, Dipartimenti direzionali all'`Incubatore Startup Torino`, imprevisti dinamici, collaboratori autonomi su Freelance Hub, Mappa Interattiva estesa a **20 POI** (con filtro **Miniera**) e **5 Fermate Bus GTT**.

---

## 🛠️ ARCHITETTURA TECNICA & TEST

- **Test Automatizzati (945/945 PASS — 0 FAIL across 7 suites):**
  - `godot --headless scenes/v1_5_post_ogr_runner.tscn` (106/106 test Post-OGR, Miniera Alpina, Animazioni, Droni, Robot, R&D, CEO & UI)
  - `godot --headless scenes/v1_4_overhaul_runner.tscn` (179/179 test OGR Gate, PBR, Mappa 20 POI, TO-OS 4-Res & Knowledge)
  - `godot --headless scenes/v1_2_overhaul_runner.tscn` (167/167 test WebForge 5.0, Parco Valentino, Mercato Nord & UI)
  - `godot --headless scenes/v1_1_gameplay_runner.tscn` (184/184 test Footsteps, Zaino [TAB], Mappa [CAPS] 20 POI & HUD)
  - `godot --headless scenes/v1_expansion_runner.tscn` (131/131 test Borgo Valdocco & Officina Bellini)
  - `godot --headless scenes/needs_runner.tscn` (72/72 test Needs, Shops & Fame)
  - `godot --headless scenes/test_runner.tscn` (106/106 Core Foundation & End-to-End tests)

