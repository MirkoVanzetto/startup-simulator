class_name WorldMapData
extends RefCounted
## WorldMapData - Coordinate geometriche reali di Borgo San Carlo, Viale Est, Borgo Valdocco e Officina Bellini.
## Allineato alle coordinate di scripts/world/village_builder.gd e scenes/world/game_world.tscn.

const WORLD_BOUNDS := Rect2(Vector2(-58.0, -14.0), Vector2(158.0, 60.0)) # X: -58..100, Z: -14..46
const SAN_CARLO_BOUNDS := Rect2(Vector2(-25.5, -10.5), Vector2(51.5, 54.0))
const PARCO_BOUNDS := Rect2(Vector2(-57.5, 10.5), Vector2(36.0, 33.0))
const VALDOCCO_BOUNDS := Rect2(Vector2(20.0, 10.0), Vector2(79.0, 35.0))
const MERCATO_BOUNDS := Rect2(Vector2(57.5, -12.0), Vector2(41.5, 34.0))

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
			"desc": "Router Wi-Fi 6, Server Xeon, PC CAD, Firewall UTM e Gadget Tech (sconto -20%% partner!)."
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
			"desc": "Parco occidentale con laghetto delle anatre, gazebo storico, ville residenziali, cassette postali e armadi fibra."
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
			"name": "Coworking OGR Torino",
			"short": "OGR",
			"district": "Mercato & OGR",
			"pos": Vector3(92.0, 0.0, 2.8),
			"footprint": Vector2(6.6, 10.6),
			"color": Color(0.32, 0.88, 0.96),
			"label_dir": "bottom",
			"desc": "Complesso OGR riconvertito in polo startup: consegne rider espresso, eventi e networking."
		}
	]

static func get_poi(poi_id: String) -> Dictionary:
	for p in get_pois():
		if p["id"] == poi_id:
			return p
	return {}

static func get_roads_and_zones() -> Dictionary:
	return {
		"grass": [
			Rect2(Vector2(-56.0, 12.0), Vector2(32.0, 30.0)),   # Parco Valentino Ovest
			Rect2(Vector2(-24.0, -9.0), Vector2(48.0, 51.0)),   # San Carlo
			Rect2(Vector2(24.0, 19.0), Vector2(35.0, 18.0)),    # Corridoio Viale Est
			Rect2(Vector2(59.0, 14.0), Vector2(38.0, 28.0)),    # Borgo Valdocco
			Rect2(Vector2(59.0, -10.0), Vector2(38.0, 24.0))    # Piazza del Mercato & OGR
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
			Rect2(Vector2(69.0, -3.2), Vector2(19.0, 17.7))     # Piazza del Mercato Nord
		],
		"asphalt": [
			Rect2(Vector2(-19.0, 9.1), Vector2(7.6, 5.4)),      # Parcheggio W
			Rect2(Vector2(11.4, 9.1), Vector2(7.6, 5.4)),       # Parcheggio E
			Rect2(Vector2(24.0, 25.3), Vector2(38.0, 5.4))      # Strada Asfaltata Est
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
			Rect2(Vector2(-30.6, 23.4), Vector2(5.2, 6.2))      # Villa Parco Sud-Est
		],
		"water_circles": [
			{"pos": Vector2(0.0, 21.0), "r": 2.2, "label": "Fontana"},
			{"pos": Vector2(68.5, 22.8), "r": 1.1, "label": "Pozzo"},
			{"pos": Vector2(-47.5, 26.8), "r": 4.0, "label": "Laghetto"}
		],
		"walls": [
			# Parco Valentino border (varco Est Z=33.6..40.0 verso San Carlo)
			[Vector2(-56.0, 12.0), Vector2(-24.0, 12.0)],
			[Vector2(-56.0, 42.0), Vector2(-24.0, 42.0)],
			[Vector2(-56.0, 12.0), Vector2(-56.0, 42.0)],
			# San Carlo border
			[Vector2(-24.0, -9.0), Vector2(24.0, -9.0)],
			[Vector2(-24.0, 42.0), Vector2(24.0, 42.0)],
			[Vector2(-24.0, -9.0), Vector2(-24.0, 33.6)],
			[Vector2(-24.0, 40.0), Vector2(-24.0, 42.0)],
			[Vector2(24.0, -9.0), Vector2(24.0, 24.8)],
			[Vector2(24.0, 31.2), Vector2(24.0, 42.0)],
			# Borgo Valdocco border (varco Nord X=75.8..82.2)
			[Vector2(59.0, 14.0), Vector2(75.8, 14.0)],
			[Vector2(82.2, 14.0), Vector2(97.0, 14.0)],
			[Vector2(59.0, 42.0), Vector2(97.0, 42.0)],
			[Vector2(97.0, 14.0), Vector2(97.0, 42.0)],
			[Vector2(59.0, 14.0), Vector2(59.0, 24.8)],
			[Vector2(59.0, 31.2), Vector2(59.0, 42.0)],
			# Mercato Nord & OGR border
			[Vector2(59.0, -10.0), Vector2(97.0, -10.0)],
			[Vector2(59.0, -10.0), Vector2(59.0, 14.0)],
			[Vector2(97.0, -10.0), Vector2(97.0, 14.0)]
		]
	}
