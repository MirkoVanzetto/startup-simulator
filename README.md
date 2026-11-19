# 🎮 STARTUP SIMULATOR

[![Engine: Godot 4.3](https://img.shields.io/badge/Engine-Godot_4.3-478cbf?logo=godotengine&logoColor=white)](https://godotengine.org)
[![Platform: Windows Desktop](https://img.shields.io/badge/Platform-Windows_x86__64-0078d7?logo=windows&logoColor=white)](https://github.com/MirkoVanzetto/startup-simulator/tree/main/build)
[![Version: v1.7.0 Gameplay & Visual Overhaul](https://img.shields.io/badge/Version-v1.7.0_Gameplay_%26_Visuals-success)](https://github.com/MirkoVanzetto/startup-simulator/blob/main/ROADMAP.md)

**Startup Simulator** è un simulatore gestionale in prima persona in 3D ambientato in una versione contemporanea e stilizzata di **Torino, Italia**.  
Interpreti un neo-laureato in Informatica con 110 e Lode che parte dal proprio garage con **120 €** fino a costruire una vera impresa tecnologica industriale.

---

## ⬇️ DOWNLOAD PLAYABLE DEMO (WINDOWS .EXE — v1.7.0)

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
| **W, A, S, D** | Movimento in prima persona / Pedala, frena e sterza in sella alla **Bici Tech 3D** |
| **Mouse** | Controllo orientamento telecamera |
| **E / Click Sinistro** | Interazione tattile · Premi nella zona oro (`55%-88%`) durante l'estrazione per un **Colpo Critico** (`+1 Bonus`) |
| **F** | Scendi e parcheggia fisicamente la **Bicicletta Tech Elettrica** ovunque in città |
| **G** | Suona il campanello della bicicletta in sella |
| **Spazio** | Salto |
| **Shift Sinistro** | Scatto / Pedalata assistita |
| **TAB** | Zaino, Materiali Tecnologici & Mobilità Urbana |
| **CAPS LOCK / M** | Mappa Interattiva di Torino (20 POI · Tab Miniera) & Segnavia GPS 3D |
| **B** | Modalità Arredo libero in Studio |
| **ESC** | Menu di Pausa (Salva, Carica, Opzioni, Riprendi) / Chiudi TO-OS |

---

## 🚀 NOVITÀ v1.7.0 — ANIMAZIONI NATURA, MINIERA INTERATTIVA, BICI 3D & TORINO VIVA

1. **Estrazione Mineraria Temporizzata con Piccone 3D & Colpo Critico:**
   - Rimossi i vecchi segnali tondi/a terra; nuovi **filoni cristallini sfaccettati** con piccone 3D animato a 3 colpi, barra di progresso HUD, scintille e **finestra temporale critica `[E]`** (`+1` materiale bonus e audio sintetizzato).
2. **Bicicletta Tech Elettrica 3D Realmente Guidabile:**
   - Salendo in sella appare il **cockpit 3D in prima persona** (`BikeCockpit`) con manubrio sterzante, display LCD, forcella e ruota anteriore rotante, inerzia di pedalata/frenata, campanello `[G]` e parcheggio fisico `[F]` ovunque per Torino.
3. **Pedoni naturali, Custom Pizzaiolo Mario & Dettagli Torino:**
   - Camminata MakeHuman corretta senza andatura a papera né compenetrazioni maglietta/pantaloni; **Mario Esposito** utilizza ora il modello custom `mario compresso_edited.glb`.
   - **Coworking OGR**: scrivanie con tastiere meccaniche, mouse, tappetini, tazze e coworker animata `Sit_Typing` con le mani sopra i tasti.
   - **Torrefazione Po (Borgo Po)**: locale arredato con tostatrice storica in rame, barista `TorrefattoreNPC` e catalogo caffetteria portatile per recuperare energia.
   - **Fontana San Carlo, Fiume Po & Traffico:** shader acqua potenziato con getti parabolici e particelle spruzzo, traffico auto ristretto al **Lungo Po**, auto ridisegnate e piazzola ovest liberata dall'ingombro davanti a **Forno Bruno**.

---

## 🛠️ ARCHITETTURA TECNICA & TEST

- **Test Automatizzati Verificati (`821/821 PASS` — `0 FAIL` su 7 runner headless):**
  - `godot --headless scenes/v1_5_post_ogr_runner.tscn` (`118/118` test Post-OGR, Piccone, Bici 3D, Torrefazione, Droni, Robot & CEO)
  - `godot --headless scenes/v1_4_overhaul_runner.tscn` (`118/118` test OGR Gate, Custom Mario, PBR, Mappa 20 POI & TO-OS)
  - `godot --headless scenes/v1_2_overhaul_runner.tscn` (`124/124` test WebForge 5.0, Parco Valentino, Mercato Nord & UI)
  - `godot --headless scenes/v1_1_gameplay_runner.tscn` (`160/160` test Footsteps, Zaino [TAB], Mappa [CAPS] & HUD)
  - `godot --headless scenes/v1_expansion_runner.tscn` (`123/123` test Borgo Valdocco & Officina Bellini)
  - `godot --headless scenes/needs_runner.tscn` (`72/72` test Needs, Shops & Fame)
  - `godot --headless scenes/test_runner.tscn` (`106/106` Core Foundation & End-to-End tests)
