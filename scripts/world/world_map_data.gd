class_name WorldMapData
extends RefCounted
## WorldMapData - Coordinate geometriche reali di Borgo San Carlo, Viale Est, Borgo Valdocco e Officina Bellini.
## Allineato alle coordinate di scripts/world/village_builder.gd e scenes/world/game_world.tscn.

const WORLD_BOUNDS := Rect2(Vector2(-76.0, -52.0), Vector2(208.0, 132.0)) # X: -76..132, Z: -52..80
const MINIERA_BOUNDS := Rect2(Vector2(-72.0, -48.0), Vector2(52.0, 62.0)) # X: -72..-20, Z: -48..14
const SAN_CARLO_BOUNDS := Rect2(Vector2(-25.5, -10.5), Vector2(51.5, 54.0))
const PARCO_BOUNDS := Rect2(Vector2(-57.5, 10.5), Vector2(36.0, 33.0))
const VALDOCCO_BOUNDS := Rect2(Vector2(20.0, 10.0), Vector2(79.0, 35.0))
const MERCATO_BOUNDS := Rect2(Vector2(57.5, -12.0), Vector2(70.5, 32.0)) # X: 57.5..128.0, Z: -12..20 (incl. OGR Tech Hub)
const BORGOPO_BOUNDS := Rect2(Vector2(-26.0, 39.0), Vector2(84.0, 40.0)) # X: -26..58, Z: 39..79 (incl. Fiume Po & Molo)

static func get_pois() -> Array[Dictionary]:
	return [
		{
			"id": "studio",
			"name": "Studio Tech (Casa Base)",
			"short": "Studio",
			"district": "Borgo San Carlo",
			"pos": Vector3(0.0, 0.0, 0.0),
			"footprint": Vector2(7.8, 6.2),
			"color": Color(0.22, 0.78, 0.98),
			"desc": "Il tuo studio: Laptop TO-OS, Server Rack 19\", letto per riposare, frigo scorte e arredo."
		},
		{
			"id": "forno_bruno",
			"name": "Forno Bruno",
			"short": "Forno",
			"district": "Via del Borgo",
			"pos": Vector3(-8.2, 0.0, 7.8),
			"footprint": Vector2(5.4, 6.4),
			"color": Color(0.96, 0.65, 0.22),
			"label_dir": "left",
			"desc": "Panificio artigianale: grissini, focaccia, pagnotte e biscotti freschi per la giornata."
		},
		{
			"id": "alimentari_rosa",
			"name": "Alimentari Rosa",
			"short": "Alimentari",
			"district": "Via del Borgo",
			"pos": Vector3(8.2, 0.0, 7.8),
			"footprint": Vector2(5.4, 6.4),
			"color": Color(0.32, 0.85, 0.48),
			"label_dir": "top",
			"desc": "Negozio di alimentari: spesa per riempire il frigo o mettere cibi pronti nello zaino."
		},
		{
			"id": "edicola_sabrina",
			"name": "Edicola Sabrina",
			"short": "Edicola",
			"district": "Piazzetta Nord",
			"pos": Vector3(6.8, 0.0, 14.5),
			"footprint": Vector2(3.0, 2.5),
			"color": Color(0.45, 0.72, 0.98),
			"label_dir": "bottom",
			"desc": "Riviste tech (+1 Rep/giorno), barrette proteiche, energy drink e notizie di Torino."
		},
		{
			"id": "caffe_san_carlo",
			"name": "Caffè San Carlo (Elena)",
			"short": "Caffè",
			"district": "Piazzetta San Carlo",
			"pos": Vector3(-13.8, 0.0, 20.5),
			"footprint": Vector2(6.0, 7.8),
			"color": Color(0.96, 0.44, 0.36),
			"desc": "Espresso, Thermos Bicerin da viaggio, cornetti e la missione Web POS di Elena."
		},
		{
			"id": "elettronica_to",
			"name": "Elettronica TO (Davide)",
			"short": "Elettronica",
			"district": "Piazzetta San Carlo",
			"pos": Vector3(13.8, 0.0, 20.5),
			"footprint": Vector2(6.0, 7.8),
			"color": Color(0.28, 0.62, 1.0),
			"label_dir": "top",
			"desc": "Router Wi-Fi 6, Server Xeon, PC CAD, Firewall UTM e Gadget Tech (sconto -20% partner!)."
		},
		{
			"id": "pizzeria_mario",
			"name": "Pizzeria Da Mario",
			"short": "Pizzeria",
			"district": "Piazzetta Sud",
			"pos": Vector3(0.0, 0.0, 30.8),
			"footprint": Vector2(8.4, 6.6),
			"color": Color(0.92, 0.28, 0.25),
			"desc": "Pizza torinese al forno a legna e la tua prima commessa con Mario Esposito."
		},
		{
			"id": "parco_valentino",
			"name": "Parco Valentino (Laghetto)",
			"short": "Parco",
			"district": "Parco Valentino Ovest",
			"pos": Vector3(-47.5, 0.0, 26.8),
			"footprint": Vector2(8.5, 6.5),
			"color": Color(0.36, 0.86, 0.56),
			"label_dir": "bottom",
			"desc": "Parco occidentale con laghetto delle anatre, gazebo storico, ville residenziali e sentiero verso l'Arco Nord per la Miniera Alpina."
		},
		{
			"id": "miniera_alpina",
			"name": "Miniera Alpina · Polo Estrattivo Val di Susa",
			"short": "Miniera",
			"district": "Miniera Alpina NO",
			"pos": Vector3(-46.0, 0.0, -22.0),
			"footprint": Vector2(40.0, 34.0),
			"color": Color(0.95, 0.72, 0.24),
			"label_dir": "bottom",
			"desc": "Cava alpina ai piedi delle Alpi: Galleria Estrattiva 01 con carrello su rotaia, 3 filoni minerari (Rame, Silicio, Terre Rare), Mining Robot MK1/MK2, Raffineria, Gru di cava & Capocava Ferrero."
		},
		{
			"id": "arco_valdocco",
			"name": "Arco San Carlo → Valdocco",
			"short": "Arco Est",
			"district": "Viale Est",
			"pos": Vector3(24.0, 0.0, 28.0),
			"footprint": Vector2(2.0, 6.8),
			"color": Color(0.76, 0.80, 0.86),
			"desc": "Varco orientale lungo la strada asfaltata che collega Borgo San Carlo a Borgo Valdocco."
		},
		{
			"id": "borgo_valdocco",
			"name": "Piazza & Pozzo Valdocco",
			"short": "Valdocco",
			"district": "Borgo Valdocco",
			"pos": Vector3(68.5, 0.0, 22.8),
			"footprint": Vector2(3.2, 3.2),
			"color": Color(0.70, 0.84, 0.96),
			"label_dir": "left",
			"desc": "Piazzetta storica del borgo industriale orientale con pozzo in pietra, bivi e accesso verso il Mercato Nord."
		},
		{
			"id": "officina_bellini",
			"name": "Officina Meccanica Bellini",
			"short": "Officina",
			"district": "Borgo Valdocco Est",
			"pos": Vector3(85.0, 0.0, 27.5),
			"footprint": Vector2(10.0, 12.2),
			"color": Color(0.96, 0.78, 0.18),
			"desc": "Maxi-Appalto Ing. Bellini: sopralluogo 4 zone, ologrammi blueprint 3D, Wi-Fi 6 + VLAN, Server Xeon, 2 PC CAD e portale."
		},
		{
			"id": "ufficio_postale",
			"name": "Ufficio Postale Torino Nord",
			"short": "Poste",
			"district": "Mercato Nord",
			"pos": Vector3(64.8, 0.0, 6.2),
			"footprint": Vector2(7.6, 5.6),
			"color": Color(0.98, 0.82, 0.16),
			"label_dir": "left",
			"desc": "Hub smistamento pacchi per i turni di Logistica Merci, spedizioni e collegamenti di quartiere."
		},
		{
			"id": "mercato_rionale",
			"name": "Mercato Rionale Torino",
			"short": "Mercato",
			"district": "Mercato Nord",
			"pos": Vector3(78.5, 0.0, -4.2),
			"footprint": Vector2(13.8, 2.4),
			"color": Color(0.96, 0.56, 0.28),
			"label_dir": "bottom",
			"desc": "Bancarelle coperte, Bacheca Lavori Rapidi e terminal POS per lavoretti di quartiere."
		},
		{
			"id": "coworking_ogr",
			"name": "OGR Tech Hub · Torino Enterprise",
			"short": "OGR Hub",
			"district": "Mercato & OGR",
			"pos": Vector3(110.25, 0.0, 2.75),
			"footprint": Vector2(27.5, 24.5),
			"color": Color(0.32, 0.88, 0.96),
			"label_dir": "bottom",
			"desc": "Grande navata OGR Enterprise: Ing. Andrea Viale, Bay 01, coworking startup e grandi contratti B2B corporate."
		},
		{
			"id": "arco_borgopo",
			"name": "Arco Sud → Borgo Po",
			"short": "Arco Sud",
			"district": "Borgo Po",
			"pos": Vector3(8.2, 0.0, 42.0),
			"footprint": Vector2(6.8, 2.0),
			"color": Color(0.76, 0.86, 0.96),
			"label_dir": "right",
			"desc": "Varco meridionale lungo la passeggiata lastricata che scende da San Carlo verso Viale Lungo Po."
		},
		{
			"id": "incubatore_i3p",
			"name": "Incubatore Startup Torino",
			"short": "Incubatore",
			"district": "Borgo Po",
			"pos": Vector3(-13.5, 0.0, 48.0),
			"footprint": Vector2(11.0, 6.4),
			"color": Color(0.26, 0.86, 0.98),
			"label_dir": "bottom",
			"desc": "Incubatore Startup & Direzione Dipartimenti (Fase 4 CEO) su Viale Lungo Po: fonda le divisioni Hardware, Cloud AI e Droni."
		},
		{
			"id": "lab_droni",
			"name": "Lab Droni Torino · Aero R&D",
			"short": "Lab Droni",
			"district": "Borgo Po",
			"pos": Vector3(24.0, 0.0, 48.2),
			"footprint": Vector2(8.6, 6.0),
			"color": Color(0.45, 0.82, 1.0),
			"label_dir": "bottom",
			"desc": "Laboratorio Aero R&D con Dr.ssa Chiara Conti, Banco Assemblaggio Fisico TO-Drone MK1 (7 fasi) e Piazzola H per missioni di volo."
		},
		{
			"id": "torrefazione_po",
			"name": "Torrefazione Po · Storica",
			"short": "Torrefazione",
			"district": "Borgo Po",
			"pos": Vector3(41.5, 0.0, 48.2),
			"footprint": Vector2(7.6, 5.8),
			"color": Color(0.92, 0.62, 0.34),
			"label_dir": "bottom",
			"desc": "Storica torrefazione torinese con dehors affacciato su Viale Lungo Po e Murazzi."
		},
		{
			"id": "molo_po",
			"name": "Molo sul Fiume Po & Murazzi",
			"short": "Molo Po",
			"district": "Lungo Po",
			"pos": Vector3(16.0, 0.0, 68.5),
			"footprint": Vector2(4.4, 5.4),
			"color": Color(0.32, 0.78, 0.96),
			"label_dir": "bottom",
			"desc": "Imbarcadero panoramico in legno sul Fiume Po lungo i Murazzi meridionali."
		}
	]

static func get_poi(poi_id: String) -> Dictionary:
	var lookup := "incubatore_i3p" if poi_id == "incubatore" else poi_id
	for p in get_pois():
		if p["id"] == lookup:
			return p
	return {}

static func get_roads_and_zones() -> Dictionary:
	return {
		"grass": [
			Rect2(Vector2(-72.0, -45.0), Vector2(50.0, 57.0)),  # Fascia Alpina & Miniera NO
			Rect2(Vector2(-56.0, 12.0), Vector2(32.0, 30.0)),   # Parco Valentino Ovest
			Rect2(Vector2(-24.0, -9.0), Vector2(48.0, 51.0)),   # San Carlo
			Rect2(Vector2(24.0, 19.0), Vector2(35.0, 18.0)),    # Corridoio Viale Est
			Rect2(Vector2(59.0, 14.0), Vector2(38.0, 28.0)),    # Borgo Valdocco
			Rect2(Vector2(59.0, -12.0), Vector2(69.0, 29.0)),   # Piazza del Mercato & OGR Tech Hub
			Rect2(Vector2(-24.0, 42.0), Vector2(80.0, 24.0))    # Borgo Po / Lungo Po
		],
		"quarry": [
			Rect2(Vector2(-67.0, -39.0), Vector2(40.0, 34.0))   # Cava & Piazzale Miniera Alpina
		],
		"gravel": [
			Rect2(Vector2(-44.0, -9.25), Vector2(5.0, 21.5)),   # Viale Ghiaia Parco -> Miniera Alpina
			Rect2(Vector2(-43.6, 11.7), Vector2(4.2, 9.6)),     # Raccordo Arco Nord Parco
			Rect2(Vector2(-39.6, 17.2), Vector2(4.2, 19.6)),    # Vialetto Ville Parco
			Rect2(Vector2(-50.0, 34.6), Vector2(38.0, 4.4)),    # Passeggiata Parco Ovest
			Rect2(Vector2(37.2, 20.9), Vector2(8.6, 3.8))       # Slargo Consegne Valdocco
		],
		"rails": [
			[Vector2(-46.0, -39.6), Vector2(-46.0, -25.8)]      # Binario Galleria 01 -> Carrello
		],
		"cobble": [
			Rect2(Vector2(-4.2, 2.4), Vector2(8.4, 11.2)),      # Via del Borgo
			Rect2(Vector2(-10.5, 13.5), Vector2(21.0, 14.0)),   # Piazzetta San Carlo
			Rect2(Vector2(-50.0, 34.6), Vector2(38.0, 4.4)),    # Passeggiata Parco Ovest
			Rect2(Vector2(-39.6, 17.2), Vector2(4.2, 19.6)),    # Vialetto Ville Parco
			Rect2(Vector2(6.0, 27.5), Vector2(4.5, 3.2)),       # Raccordo Est
			Rect2(Vector2(10.5, 25.3), Vector2(13.5, 5.4)),     # Ponte Arco Est
			Rect2(Vector2(62.0, 18.0), Vector2(18.0, 20.0)),    # Piazza Valdocco
			Rect2(Vector2(75.8, 13.5), Vector2(6.4, 5.0)),      # Passaggio Arco Nord
			Rect2(Vector2(69.0, -3.2), Vector2(19.0, 17.7)),    # Piazza del Mercato Nord
			Rect2(Vector2(6.0, 29.0), Vector2(4.4, 14.5)),      # Vialetto Arco Sud Borgo Po
			Rect2(Vector2(1.0, 43.0), Vector2(14.4, 12.3))      # Piazza Borgo Po
		],
		"slabs": [
			Rect2(Vector2(87.9, -0.35), Vector2(8.7, 6.2)),     # Promenade Mercato -> Cancello OGR
			Rect2(Vector2(96.5, -9.5), Vector2(27.5, 24.5)),    # Pavimentazione Navata OGR Tech Hub
			Rect2(Vector2(-17.8, 51.1), Vector2(8.6, 4.2)),     # Sagrato Incubatore
			Rect2(Vector2(20.2, 51.1), Vector2(7.6, 4.2)),      # Sagrato Lab Droni
			Rect2(Vector2(37.7, 51.1), Vector2(7.6, 4.2)),      # Sagrato Torrefazione Po
			Rect2(Vector2(-24.0, 60.7), Vector2(80.0, 5.1))     # Promenade Murazzi Lungo Po
		],

		"asphalt": [
			Rect2(Vector2(-19.0, 9.1), Vector2(7.6, 5.4)),      # Parcheggio W
			Rect2(Vector2(11.4, 9.1), Vector2(7.6, 5.4)),       # Parcheggio E
			Rect2(Vector2(24.0, 25.3), Vector2(38.0, 5.4)),     # Strada Asfaltata Est
			Rect2(Vector2(-22.5, 55.3), Vector2(77.0, 5.4))     # Viale Lungo Po
		],
		"rivers": [
			Rect2(Vector2(-32.0, 65.8), Vector2(96.0, 11.4))    # Fiume Po
		],
		"wood_piers": [
			Rect2(Vector2(13.8, 65.8), Vector2(4.4, 5.4))       # Molo sul Po
		],
		"houses": [
			Rect2(Vector2(-11.6, -2.7), Vector2(6.2, 5.4)),
			Rect2(Vector2(5.4, -2.7), Vector2(6.2, 5.4)),
			Rect2(Vector2(-18.5, 2.8), Vector2(5.4, 5.6)),
			Rect2(Vector2(12.8, 2.8), Vector2(5.4, 5.6)),
			Rect2(Vector2(-17.8, 26.5), Vector2(6.5, 5.6)),
			Rect2(Vector2(12.2, 33.4), Vector2(6.5, 5.6)),
			Rect2(Vector2(64.9, 14.1), Vector2(6.2, 4.8)),
			Rect2(Vector2(63.6, 36.8), Vector2(5.8, 4.8)),
			Rect2(Vector2(71.4, 36.8), Vector2(5.6, 4.8)),
			Rect2(Vector2(-37.4, 13.2), Vector2(6.8, 5.6)),     # Villa Parco Nord
			Rect2(Vector2(-30.6, 23.4), Vector2(5.2, 6.2)),     # Villa Parco Sud-Est
			Rect2(Vector2(-58.8, -16.1), Vector2(4.6, 3.2)),    # Ufficio Geologico Cava (Quarry Cabin)
			Rect2(Vector2(-36.8, -18.8), Vector2(3.6, 2.5)),    # Raffineria & Frantoio Miniera
			Rect2(Vector2(-5.6, 45.6), Vector2(6.0, 5.2)),      # Casa Borgo Po Ovest
			Rect2(Vector2(48.3, 45.6), Vector2(5.8, 5.2))       # Casa Borgo Po Est
		],
		"water_circles": [
			{"pos": Vector2(0.0, 21.0), "r": 2.2, "label": "Fontana"},
			{"pos": Vector2(68.5, 22.8), "r": 1.1, "label": "Pozzo"},
			{"pos": Vector2(-47.5, 26.8), "r": 4.0, "label": "Laghetto"}
		],
		"walls": [
			# Miniera Alpina perimeter (varco Sud X=-44.5..-38.5 verso Parco Valentino)
			[Vector2(-67.0, -5.0), Vector2(-44.5, -5.0)],
			[Vector2(-38.5, -5.0), Vector2(-27.0, -5.0)],
			[Vector2(-67.0, -39.0), Vector2(-67.0, -5.0)],
			[Vector2(-27.0, -39.0), Vector2(-27.0, -5.0)],
			[Vector2(-67.0, -39.0), Vector2(-27.0, -39.0)],
			# Parco Valentino border (varco Nord X=-44.5..-38.5 Miniera; varco Est Z=33.6..40.0 San Carlo)
			[Vector2(-56.0, 12.0), Vector2(-44.5, 12.0)],
			[Vector2(-38.5, 12.0), Vector2(-24.0, 12.0)],
			[Vector2(-56.0, 42.0), Vector2(-24.0, 42.0)],
			[Vector2(-56.0, 12.0), Vector2(-56.0, 42.0)],
			# San Carlo border (varco Sud Borgo Po X=5.0..11.4)
			[Vector2(-24.0, -9.0), Vector2(24.0, -9.0)],
			[Vector2(-24.0, 42.0), Vector2(5.0, 42.0)],
			[Vector2(11.4, 42.0), Vector2(24.0, 42.0)],
			[Vector2(-24.0, -9.0), Vector2(-24.0, 33.6)],
			[Vector2(-24.0, 40.0), Vector2(-24.0, 42.0)],
			[Vector2(24.0, -9.0), Vector2(24.0, 24.8)],
			[Vector2(24.0, 31.2), Vector2(24.0, 42.0)],
			# Borgo Po / Lungo Po border (muro Nord X=24..56, Est/Ovest, Balustrada Lungofiume aperta al Molo X=13.8..18.2)
			[Vector2(24.0, 42.0), Vector2(56.0, 42.0)],
			[Vector2(-24.0, 42.0), Vector2(-24.0, 65.8)],
			[Vector2(56.0, 42.0), Vector2(56.0, 65.8)],
			[Vector2(-24.0, 65.8), Vector2(13.8, 65.8)],
			[Vector2(18.2, 65.8), Vector2(56.0, 65.8)],
			# Borgo Valdocco border (varco Nord X=75.8..82.2, muro Est Z=15..42 sotto la navata OGR)
			[Vector2(59.0, 14.0), Vector2(75.8, 14.0)],
			[Vector2(82.2, 14.0), Vector2(96.75, 14.0)],
			[Vector2(59.0, 42.0), Vector2(96.75, 42.0)],
			[Vector2(96.75, 15.0), Vector2(96.75, 42.0)],
			[Vector2(59.0, 14.0), Vector2(59.0, 24.8)],
			[Vector2(59.0, 31.2), Vector2(59.0, 42.0)],
			# Mercato Nord & Ingresso OGR border (muro Est spezzato attorno a Z=0.35..5.15)
			[Vector2(59.0, -10.0), Vector2(96.2, -10.0)],
			[Vector2(59.0, -10.0), Vector2(59.0, 14.0)],
			[Vector2(96.2, -10.0), Vector2(96.2, 0.35)],
			[Vector2(96.2, 5.15), Vector2(96.2, 15.0)],
			# Perimetro esterno Navata OGR Tech Hub (aperto ad Ovest Z=0.35..5.15)
			[Vector2(96.5, -9.5), Vector2(124.0, -9.5)],
			[Vector2(124.0, -9.5), Vector2(124.0, 15.0)],
			[Vector2(124.0, 15.0), Vector2(96.5, 15.0)],
			[Vector2(96.5, -9.5), Vector2(96.5, 0.35)],
			[Vector2(96.5, 5.15), Vector2(96.5, 15.0)]
		]
	}
