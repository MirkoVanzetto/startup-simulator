# 🎮 STARTUP SIMULATOR

[![Engine: Godot 4.3](https://img.shields.io/badge/Engine-Godot_4.3-478cbf?logo=godotengine&logoColor=white)](https://godotengine.org)
[![Platform: Windows Desktop](https://img.shields.io/badge/Platform-Windows_x86__64-0078d7?logo=windows&logoColor=white)](https://github.com/MirkoVanzetto/startup-simulator/tree/main/build)
[![Status: Milestones 1, 2, 3, 4 Complete](https://img.shields.io/badge/Milestones-1,_2,_3,_4_Complete-success)](https://github.com/MirkoVanzetto/startup-simulator/blob/main/ROADMAP.md)

**Startup Simulator** è un simulatore gestionale in prima persona in 3D ambientato in una versione contemporanea e stilizzata di **Torino, Italia**.  
Interpreti un neo-laureato in Informatica con 110 e Lode che, stanco di proposte di stage umilianti e non retribuite, decide di mettersi in proprio partendo dal garage di casa per costruire un impero tecnologico.

---

## ⬇️ DOWNLOAD PLAYABLE DEMO (WINDOWS .EXE)

Puoi scaricare l'eseguibile giocabile aggiornato direttamente da GitHub ai seguenti link:

- 📦 **[Scarica Archivio Completo ZIP (Consigliato - 40 MB)](https://github.com/MirkoVanzetto/startup-simulator/raw/main/build/StartupSimulator_Windows_x86_64.zip)**  
  *(Include `StartupSimulator.exe`, `StartupSimulator.pck` e `README_PLAYABLE.txt`)*

- ⚡ **[Scarica direttamente StartupSimulator.exe](https://github.com/MirkoVanzetto/startup-simulator/raw/main/build/StartupSimulator.exe)**  
  *(Richiede anche il file di risorse [StartupSimulator.pck](https://github.com/MirkoVanzetto/startup-simulator/raw/main/build/StartupSimulator.pck) nella stessa cartella)*

- 📁 **[Sfoglia la cartella build/ su GitHub](https://github.com/MirkoVanzetto/startup-simulator/tree/main/build)**

---

## 📸 SCREENSHOT & ANTEPRIMA GRAFICA 3D

| Scena Prologo & Laurea | Studio & Setup Iniziale | Quartiere Via Po & Auto | Pizzeria Da Mario | WebForge IDE |
| :---: | :---: | :---: | :---: | :---: |
| Prologo narrativo interattivo | Scrivania, laptop, diploma al muro e arredi | Palazzi torinesi, auto, lampioni e portici | Mario al bancone, forno a legna e tavoli | Simulatore browser e compilatore |

---

## ⌨️ COMANDI DI GIOCO

| Tasto | Azione |
| :--- | :--- |
| **W, A, S, D** | Movimento del personaggio nello spazio 3D |
| **Mouse** | Controllo orientamento telecamera |
| **E / Click Sinistro** | Interazione tattile (Laptop, NPC Mario, Arredi, Upgrade) |
| **Spazio** | Salto |
| **Shift Sinistro** | Scatto / Corsa rapida |
| **ESC** | **Menu di Pausa in-game** (Salva, Carica, Volume, Sensibilità mouse, Fullscreen, Menu Principale) / Chiudi Laptop |

---

## 🚀 NOVITÀ DELL'AGGIORNAMENTO (OVERHAUL GRAFICO & GAMEPLAY)

1. **Overhaul Grafico 3D Completo (Asset CC0 ad Alta Risoluzione):**
   - **Studio Garage:** Scrivania in legno massello, sedia da ufficio confortevole, libreria alta con libri tecnici, credenza, lampada da tavolo, pianta grassa, tappeto sabaudo e la pergamena di laurea (110 e Lode) incorniciata alla parete.
   - **Quartiere Via Po:** Palazzi torinesi dettagliati con tende parasole a righe, vetrine commerciali, marciapiedi, automobili parcheggiate (berlina e taxi), lampioni urbani caldi, panchine e idranti.
   - **Pizzeria Da Mario:** Bancone ristorante rifinito, forno a legna per pizza con fiamme calde e bagliore dinamico, tavoli da pranzo, sedie in legno, cassette di ingredienti freschi (pomodori San Marzano e formaggio), e il modello 3D animato di **Mario Esposito** che ti accoglie al bancone!
2. **Prologo Narrativo Interattivo:**
   - Nuova sequenza introduttiva alla prima partita: mostra la pergamena di Laurea Magistrale in Informatica con 110 e Lode, le email con offerte di stage ridicole (400€/mese con 8 anni di esperienza richiesta) e la scelta consapevole di aprire la propria startup indipendente.
3. **Pacing & Gating delle Azioni (Tutorial Guidato):**
   - **Porta d'uscita del garage sbloccata:** Risolto il blocco di collisione che impediva di uscire dallo studio. Ora il passaggio su Via Po è fluido e naturale.
   - **WebForge IDE bloccato all'inizio:** Non è più possibile fare il sito web a vuoto prima di accettare il lavoro. Il giocatore deve prima leggere l'email, uscire dal garage, percorrere Via Po, raggiungere la pizzeria e parlare di persona con Mario per definire i requisiti e stringere l'accordo.
   - **WebForge Potenziato:** Mostra l'intestazione della commissione attiva, il compenso concordato (€ 650,00) e la simulazione live del browser web con certificato SSL (`https://www.pizzeriadamario-torino.it`).
4. **Milestone 4 - Personalizzazione Studio & TorinoHardware:**
   - Nuovo elemento acquistabile: Pianta d'Arredamento Succulenta (€ 35,00) che appare fisicamente nello studio 3D.
   - Upgrade della Sedia Ergonomica Racing Pro (€ 220,00) e del Monitor 27" Ultrawide (€ 350,00).

---

## 🛠️ ARCHITETTURA TECNICA & TEST

- **Test Automatizzati:** 44/44 test superati al 100% (verifica economia, contratti, salvataggi, calendario, marketplace, collisioni e navigazione 3D porte/strada). Esegui con:  
  `godot --headless scenes/test_runner.tscn`
