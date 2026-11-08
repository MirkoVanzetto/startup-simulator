# 🎮 STARTUP SIMULATOR

[![Engine: Godot 4.3](https://img.shields.io/badge/Engine-Godot_4.3-478cbf?logo=godotengine&logoColor=white)](https://godotengine.org)
[![Platform: Windows Desktop](https://img.shields.io/badge/Platform-Windows_x86__64-0078d7?logo=windows&logoColor=white)](https://github.com/MirkoVanzetto/startup-simulator/tree/main/build)
[![Status: Milestone 1, 2, 3 Complete](https://img.shields.io/badge/Milestones-1,_2,_3_Complete-success)](https://github.com/MirkoVanzetto/startup-simulator/blob/main/ROADMAP.md)

**Startup Simulator** è un simulatore gestionale in prima persona in 3D ambientato in una versione contemporanea e stilizzata di **Torino, Italia**.  
Interpreti un neo-laureato in Informatica che parte da un modesto studio/garage e scala progressivamente la propria azienda tecnologica attraverso attività fisiche, hardware, minigiochi tecnici, contratti con clienti locali e reinvestimento strategico dei profitti.

---

## ⬇️ DOWNLOAD PLAYABLE DEMO (WINDOWS .EXE)

Puoi scaricare l'eseguibile giocabile direttamente da GitHub ai seguenti link:

- 📦 **[Scarica Archivio Completo ZIP (Consigliato - 30 MB)](https://github.com/MirkoVanzetto/startup-simulator/raw/main/build/StartupSimulator_Windows_x86_64.zip)**  
  *(Include `StartupSimulator.exe`, `StartupSimulator.pck` e `README_PLAYABLE.txt`)*

- ⚡ **[Scarica direttamente StartupSimulator.exe](https://github.com/MirkoVanzetto/startup-simulator/raw/main/build/StartupSimulator.exe)**  
  *(Richiede anche il file di risorse [StartupSimulator.pck](https://github.com/MirkoVanzetto/startup-simulator/raw/main/build/StartupSimulator.pck) nella stessa cartella)*

- 📁 **[Sfoglia la cartella build/ su GitHub](https://github.com/MirkoVanzetto/startup-simulator/tree/main/build)**

---

## ⌨️ COMANDI DI GIOCO

| Tasto | Azione |
| :--- | :--- |
| **W, A, S, D** | Movimento del personaggio nello spazio 3D |
| **Mouse** | Controllo orientamento telecamera |
| **E / Click Sinistro** | Interazione tattile (Laptop, NPC Mario, Porte, Upgrade) |
| **Spazio** | Salto |
| **Shift Sinistro** | Scatto / Corsa rapida |
| **ESC** | **Menu di Pausa in-game** (Salvataggio, Caricamento, Regolazione Volume, Sensibilità mouse, Fullscreen, Torna al Menu Principale) |

---

## 🎯 CONTENUTI INCLUSI NELLA DEMO (MILESTONE 1, 2 E 3)

1. **Menu di Avvio Completo:** Nuova Partita, Continua, Multiplayer Co-op (1-4), Impostazioni e Crediti.
2. **Esplorazione 3D in Prima Persona:** Studio iniziale arredato a Torino con fisica realistica, attenuazione head-bob, foley differenziato (passi su parquet e ciottoli).
3. **Laptop & Sistema Operativo TO-OS 26.4:**
   - App **Posta:** Comunicazioni con clienti e offerte.
   - App **Freelance Hub:** Missione Mario Esposito e Marketplace B2B procedurale di Torino.
   - App **WebForge IDE:** Minigioco visivo per comporre e compilare siti web in tempo reale.
   - App **TorinoHardware:** Negozio e-commerce per acquistare il secondo monitor e la sedia ergonomica da gaming (appaiono fisicamente nello studio 3D).
   - App **Banca Piemonte:** Estratto conto e gestione della liquidità.
4. **Quartiere di Torino & Pizzeria Da Mario:** Esci dallo studio, cammina lungo i portici sabaudi in Via Po, entra nella pizzeria e parla con Mario davanti al forno a legna.
5. **Simulazione Calendario & Costi Fissi:** Orologio dinamico in tempo reale e addebito automatico a mezzanotte delle spese d'ufficio (€ 38/giorno).
6. **Menu di Pausa [ESC] in-game:** Salvataggio istantaneo, caricamento e regolazione impostazioni in tempo reale.

---

## 🛠️ ARCHITETTURA TECNICA & DOCUMENTAZIONE

- [`GAME_DESIGN_DOCUMENT.md`](GAME_DESIGN_DOCUMENT.md): Game design dettagliato, progressione da freelance a tech enterprise, intelligenza artificiale, infrastruttura server e multiplayer co-op.
- [`TECHNICAL_DESIGN.md`](TECHNICAL_DESIGN.md): Architettura software in Godot 4.3, GDScript tipizzato, signal bus disaccoppiato (`EventBus`), sistema di salvataggio atomico.
- [`ROADMAP.md`](ROADMAP.md): Le 10 milestone di produzione.
- Test automatizzati (35/35 test passati al 100%): esegui con `godot --headless scenes/test_runner.tscn`.
