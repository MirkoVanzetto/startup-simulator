# STARTUP SIMULATOR - GAME DESIGN DOCUMENT (GDD)
**Versione:** 1.0.0  
**Stato:** Approvato per Produzione  
**Engine:** Godot 4.3 (Forward+ / GL Compatibility)  
**Piattaforme di Riferimento:** PC (Windows, Linux), Steam Deck  
**Genere:** First-Person 3D Management & Life Simulator  
**Setting:** Torino contemporanea (Italia), quartiere tech/storico stilizzato  

---

## 1. VISIONE GENERALE E FILOSOFIA DI DESIGN

### 1.1 Premessa
In *Startup Simulator*, il giocatore vive fisicamente l'ascesa di un giovane neo-laureato in Informatica a Torino che, stanco di stage sottopagati e mansioni poco stimolanti, decide di fondare una propria azienda tecnologica partendo da un piccolo studio/garage.

L'esperienza fonde:
1. **Fisicità e Immersione in Prima Persona:** Ispirato a capisaldi del genere come *Supermarket Simulator*, *Gas Station Simulator*, *Computer Repair Shop Simulator* e *House Flipper*. Non si naviga solo tra fogli Excel e menu astratti: il giocatore cammina fisicamente nel mondo, apre il proprio laptop, va dai clienti nelle botteghe storiche torinesi, installa banchi di RAM e server nei rack, posiziona scrivanie e parla con i dipendenti.
2. **Ciclo Economico e Progressione Tangibile:**
   `LAVORO -> RICAVO -> REINVESTIMENTO -> MIGLIORAMENTO AMBIENTALE ED ESPANSIONE`
3. **Approccio Accessibile e Ludico all'Informatica:** Nessun gergo impenetrabile o compiti noiosi. Lo sviluppo software, la gestione database, le reti e l'IA sono tradotti in minigiochi tattili, intuitivi, stimolanti e divertenti per qualsiasi tipologia di videogiocatore.
4. **Co-op Multiplayer Fluido (1-4 Giocatori):** Un'unica azienda cooperativa su modello host-client con economia, inventario, contratti, uffici e server condivisi.

---

## 2. PILASTRI DI GAME DESIGN (NON NEGOZIABILI)

1. **Autonomia Totale Single-Player:** Il gioco è godibile al 100% in solitaria; il multiplayer arricchisce l'esperienza collaborativa ma non impone restrizioni al giocatore singolo.
2. **Rappresentazione Fisica di Ogni Entità:** I dipendenti camminano, si siedono e lavorano nello spazio 3D; i server riscaldano la stanza e possono guastarsi fisicamente; i computer si assemblano collegando cavi e componenti.
3. **Ambientazione Autentica Torinese:** Architettura tipica (portici, strade in ciottoli, facciate sabaude, insegne caratteristiche), con la prima pizzeria "Da Mario" come cliente formativo del tutorial.
4. **L'IA come Strumento e Leva Economica Contemporanea:** L'automazione non è magica né istantanea; richiede abbonamenti, hardware GPU dedicato, monitoraggio e bilanciamento dei costi operativi.
5. **Zero Falso Progresso:** Nessun moltiplicatore finto o contatore privo di logica sottostante. Ogni euro guadagnato o speso riflette attività e asset reali.

---

## 3. CORE GAMEPLAY LOOP

```
       ┌────────────────────────────────────────────────────────┐
       │               ESPLORAZIONE & OPPORTUNITÀ               │
       │  (Laptop, email, marketplace freelance, negozi fisici) │
       └───────────────────────────┬────────────────────────────┘
                                   │
                                   ▼
       ┌────────────────────────────────────────────────────────┐
       │              REQUISITI & NEGOZIAZIONE                  │
       │      (Incontro col cliente, accordo sul compenso)      │
       └───────────────────────────┬────────────────────────────┘
                                   │
                                   ▼
       ┌────────────────────────────────────────────────────────┐
       │                 ATTIVITÀ TECNICHE                      │
       │   (Minigiochi di Web Dev, Code Logic, Hardware, Rete)  │
       └───────────────────────────┬────────────────────────────┘
                                   │
                                   ▼
       ┌────────────────────────────────────────────────────────┐
       │            CONSEGNA, FEEDBACK & FATTURAZIONE           │
       │    (Valutazione qualità, incasso, reputazione aziendale)│
       └───────────────────────────┬────────────────────────────┘
                                   │
                                   ▼
       ┌────────────────────────────────────────────────────────┐
       │               REINVESTIMENTO & CRESCITA                │
       │ (Migliorie studio, server, dipendenti, strumenti IA)   │
       └────────────────────────────────────────────────────────┘
```

---

## 4. IL TUTORIAL FORMATIVO: LA PIZZERIA TORINESE

### Fase 1: Il Risveglio nello Studio
- Il giocatore inizia nel suo modesto studio (scrivania semplice, sedia base, laptop, smartphone, 250 € sul conto).
- Impara il movimento in prima persona (WASD, Mouse Look, Interazione [E], Salto [Spazio], Corsa [Shift]).
- Si siede al laptop: esplora il sistema operativo simulato "TO-OS", legge le email di rifiuto degli annunci aziendali tradizionali e apre il marketplace "FreelancePiemonte".

### Fase 2: L'Incontro con Mario
- Trova l'annuncio della rinomata **Pizzeria Da Mario** (Via Po): il proprietario cerca qualcuno che crei il primo sito web per ordini e prenotazioni.
- Il giocatore esce fisicamente dallo studio, cammina lungo il quartiere torinese e raggiunge la pizzeria.
- Entra nella pizzeria (ambiente caldo, forno a legna, tavoli in legno, odore di pizza).
- Parla con Mario: dialogo a scelte multiple per definire gli elementi chiave (Logo con Mole Antonelliana, Menu delle Pizze, Orari di Apertura, Modulo Prenotazione).

### Fase 3: Lo Sviluppo del Progetto
- Il giocatore torna allo studio, si siede al laptop e lancia il tool **WebForge 1.0**.
- Minigioco visuale drag-and-drop: posizionamento dell'Header, del Brand Logo, della Sezione Menu interattiva, degli Orari e del Pulsante di Chiamata/Prenotazione.
- Verifica del layout e test di responsività mobile/desktop.

### Fase 4: Consegna e Valutazione
- Invio del deliverable via email a Mario.
- Mario invia feedback immediato con rating a 5 stelle e accredito di **650 €** + **Reputazione +15**.

### Fase 5: Il Primo Reinvestimento
- Il giocatore sblocca il portale e-commerce "HardwareShop Torino".
- Acquisto di un **Secondo Monitor 27" Ultrawide** (+15% velocità di sviluppo) o di una **Sedia Ergonomica da Gaming/Ufficio** (+20% recupero fatica).
- L'oggetto viene consegnato e posizionato liberamente nella stanza tramite il sistema di arredo fisico.

---

## 5. PROGRESSIONE DELL'AZIENDA (I 5 STADI EVOLUTIVI)

1. **Freelance nel Garage:**
   - Focus: Piccoli siti vetrina, riparazioni PC di quartiere, script semplici.
   - Setup: 1 scrivania, 1 laptop, connessione ADSL/Fibra domestica.
2. **Startup Emergente:**
   - Focus: Gestionali personalizzati, e-commerce locali, primi contratti B2B.
   - Sblocco: Trasferimento in un coworking o bilocale riadattato a studio, 1° dipendente assunto, mini-NAS locale.
3. **Software House Strutturata:**
   - Focus: Applicazioni enterprise, integrazioni API, prodotti SaaS proprietari (es. gestionale ristoranti "PizzaCloud").
   - Sblocco: Ufficio privato con reception e open space, team di 3-6 specialisti (Frontend, Backend, DevOps, Designer).
4. **Tech Company & Server Room:**
   - Focus: Servizi cloud ad alta disponibilità, modelli IA personalizzati, sicurezza informatica e contratti corporate.
   - Sblocco: Stanza server climatizzata dedicata, armadi rack 42U, switch 10GbE, UPS industriali, gestione calore e guasti hardware.
5. **Azienda Tecnologica Consolidata:**
   - Focus: Suite di prodotti globali, quotazione o acquisizioni, ricerca avanzata, team multi-disciplinari autonomi.

---

## 6. SISTEMI DI GIOCO CHIAVE

### 6.1 Minigiochi Tecnici Intuitivi
- **WebForge (Sviluppo Web):** Composizione a blocchi logici (layout, palette colori, sezioni funzionali) con feedback visivo istantaneo.
- **LogicWire (Programmazione & Algoritmi):** Connessione di nodi logici (Input -> Filter -> Process -> Output) per risolvere flussi dati senza scrivere sintassi complessa.
- **DataGrid (Database):** Pulizia dati, normalizzazione tabelle e query visuali con matching di chiavi relazionali.
- **NetPulse (Networking):** Instradamento pacchetti, assegnazione indirizzi IP, collegamento cavi RJ45 a switch/router e risoluzione congestioni di rete.
- **SecurityShield (Cybersecurity):** Individuazione falle (porte aperte, payload sospetti) e configurazione regole firewall.
- **HardwareLab (Assemblaggio e Manutenzione PC/Server):** Inserimento fisico di RAM negli slot DIMM, sostituzione dischi NVMe/SSD su caddy hot-swap, applicazione pasta termica e pulizia ventole.

### 6.2 Intelligenza Artificiale ed Economia dei Token
- **Strumenti IA:** AI Website Builder, AI Code Reviewer, AI Support Bot, AI Data Analytics.
- **Dinamica:** L'IA accelera o automatizza parti dei contratti, ma consuma token API o cicli GPU dei propri server. Se mal configurata, produce "allucinazioni" (bug) che il giocatore deve verificare manualmente prima del deploy.

### 6.3 Dipendenti Viventi nello Spazio 3D
- Gli NPC dipendenti hanno nome, avatar 3D, personalità, stipendio mensile, livello di stress, skill (Frontend, Backend, DevOps, UI/UX, Sales).
- Hanno una routine: arrivano in ufficio, si siedono alla postazione assegnata, bevono caffè, collaborano, richiedono aumenti o pause se sovraccarichi.

---

## 7. MULTIPLAYER COOPERATIVO (1-4 GIOCATORI)
- Architettura host-client autorevole: l'host gestisce lo stato persistente dell'azienda.
- Nessuna divisione artificiale: tutti i giocatori possono svolgere qualsiasi compito in modo sinergico (ad es. mentre il Giocatore 1 negozia un contratto in centro città, il Giocatore 2 sviluppa il frontend e il Giocatore 3 ripara un server surriscaldato nel rack).
- Tre modalità di matchmaking:
  1. Steam P2P (Inviti amici, lobby private).
  2. LAN Direct Connect (ricerca automatica broadcast locale).
  3. Direct IP / VPN (Tailscale, ZeroTier o IP pubblico con porta custom).

---

## 8. AUDIO E IDENTITÀ SONORA
- **Ambiente Dinamico:** Rombi lontani del traffico torinese, rintocchi di campane, il fruscio del vento attraverso i portici.
- **Foley Tattile:** Clic meccanici di tastiere tattili Cherry MX Blue/Brown, click del mouse, inserimento a scatto di schede PCIe e RAM, ventole dei server che modulano l'RPM in base alla temperatura termica.
- **Musica:** Colonna sonora Lo-Fi / Synthwave rilassante e produttiva durante il lavoro al computer, con transizioni dinamiche verso l'acustico/cittadino durante l'esplorazione esterna.
