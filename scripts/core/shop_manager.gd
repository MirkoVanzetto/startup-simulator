extends Node
## ShopManager - Catalogo dati dei negozi del borgo e logica di acquisto (cibo, bevande, edicola, frigo).
## I prezzi sono scontati dalla notorietà (FameManager.get_discount()).

const SHOPS: Dictionary = {
	"pizzeria": {
		"title": "Pizzeria Da Mario",
		"subtitle": "La vera pizza torinese da trent'anni",
		"items": [
			{"id": "trancio_margherita", "name": "Trancio di margherita", "price": 3.50, "hunger": 35.0, "energy": 0.0},
			{"id": "pizza_intera", "name": "Pizza intera", "price": 8.00, "hunger": 70.0, "energy": 0.0},
			{"id": "tiramisu", "name": "Tiramisù della casa", "price": 4.50, "hunger": 20.0, "energy": 6.0},
			{"id": "acqua", "name": "Acqua", "price": 1.50, "hunger": 3.0, "energy": 5.0}
		]
	},
	"cafe": {
		"title": "Caffè San Carlo",
		"subtitle": "Storico caffè di Torino",
		"items": [
			{"id": "espresso", "name": "Espresso", "price": 1.20, "hunger": 0.0, "energy": 25.0},
			{"id": "bicerin", "name": "Bicerin", "price": 3.80, "hunger": 12.0, "energy": 30.0},
			{"id": "cornetto", "name": "Cornetto", "price": 1.50, "hunger": 20.0, "energy": 0.0},
			{"id": "tramezzino", "name": "Tramezzino", "price": 4.00, "hunger": 35.0, "energy": 0.0}
		]
	},
	"panificio": {
		"title": "Forno Bruno",
		"subtitle": "Pane e dolci appena sfornati",
		"items": [
			{"id": "grissini", "name": "Grissini torinesi", "price": 2.00, "hunger": 15.0, "energy": 0.0},
			{"id": "focaccia", "name": "Focaccia", "price": 3.00, "hunger": 30.0, "energy": 0.0},
			{"id": "pagnotta", "name": "Pagnotta", "price": 2.50, "hunger": 25.0, "energy": 0.0},
			{"id": "biscotti", "name": "Biscotti", "price": 3.00, "hunger": 10.0, "energy": 10.0}
		]
	},
	"alimentari": {
		"title": "Alimentari Rosa",
		"subtitle": "Spesa di quartiere (puoi riempire il frigo dello studio)",
		"fridge_stockable": true,
		"items": [
			{"id": "frutta", "name": "Frutta fresca", "price": 2.00, "hunger": 18.0, "energy": 0.0},
			{"id": "panino", "name": "Panino", "price": 3.50, "hunger": 32.0, "energy": 0.0},
			{"id": "insalata", "name": "Insalata", "price": 5.00, "hunger": 30.0, "energy": 8.0},
			{"id": "lasagna", "name": "Lasagna surgelata", "price": 6.00, "hunger": 55.0, "energy": 0.0},
			{"id": "acqua_alimentari", "name": "Acqua", "price": 1.00, "hunger": 2.0, "energy": 3.0}
		]
	},
	"edicola": {
		"title": "Edicola Sabrina",
		"subtitle": "Giornali, riviste e qualcosa per restare svegli",
		"items": [
			{"id": "rivista_tech", "name": "Rivista tech (+1 Rep al giorno)", "price": 6.00, "hunger": 0.0, "energy": 0.0},
			{"id": "giornale", "name": "Giornale", "price": 1.50, "hunger": 0.0, "energy": 0.0},
			{"id": "energy_drink", "name": "Energy drink", "price": 2.50, "hunger": -3.0, "energy": 30.0},
			{"id": "gomme", "name": "Gomme da masticare", "price": 1.00, "hunger": 1.0, "energy": 0.0}
		]
	},
	"fridge": {
		"title": "Frigo dello studio",
		"subtitle": "Le scorte comprate all'Alimentari Rosa",
		"items": []
	},
	"elettronica_componenti": {
		"title": "Elettronica TO — Hardware Clienti",
		"subtitle": "Router Wi-Fi, Server, Workstation PC & Firewall da installare ai clienti",
		"is_hardware_shop": true,
		"items": [
			{"id": "hw_wifi_router", "name": "Router Wi-Fi 6 Dual-Band Mesh", "price": 180.00, "desc": "Copertura industriale con VLAN & QoS per laboratori e uffici."},
			{"id": "hw_server_tower", "name": "Server Tower Xeon 8-Core RAID-10", "price": 520.00, "desc": "Server locale aziendale per database gestionali & backup interno."},
			{"id": "hw_workstation_pc", "name": "PC Workstation CAD & Ufficio", "price": 320.00, "desc": "Workstation Intel i7 / 32GB RAM / NVMe pronta per uffici e officine."},
			{"id": "hw_firewall_appliance", "name": "Firewall Hardware UTM Gigabit", "price": 140.00, "desc": "Appliance VPN / IPSec perimetrale per sicurezza reti B2B."}
		]
	}
}

signal fridge_changed()
signal hardware_changed()

## Scorte del frigo: item_id -> quantità
var fridge_stock: Dictionary = {}
## Scorte hardware per clienti: hw_item_id -> quantità
var hardware_stock: Dictionary = {}
## Giorno dell'ultima rivista tech che ha dato reputazione (0 = mai)
var magazine_day: int = 0

func get_shop_ids() -> Array:
	return SHOPS.keys()

func has_shop(shop_id: String) -> bool:
	return SHOPS.has(shop_id)

func get_shop_title(shop_id: String) -> String:
	if not SHOPS.has(shop_id):
		return shop_id
	return str(SHOPS[shop_id]["title"])

func get_shop_subtitle(shop_id: String) -> String:
	if not SHOPS.has(shop_id):
		return ""
	return str(SHOPS[shop_id].get("subtitle", ""))

func is_fridge_stockable(shop_id: String) -> bool:
	return SHOPS.has(shop_id) and bool(SHOPS[shop_id].get("fridge_stockable", false))

func is_hardware_shop(shop_id: String) -> bool:
	return SHOPS.has(shop_id) and bool(SHOPS[shop_id].get("is_hardware_shop", false))

## Elenco articoli del negozio. Per 'fridge' elenca solo gli articoli in scorta (con campo 'stock').
func get_items(shop_id: String) -> Array:
	if shop_id == "fridge":
		var out: Array = []
		for item_id in fridge_stock:
			var qty = int(fridge_stock[item_id])
			if qty <= 0:
				continue
			var base = find_item(str(item_id))
			if base.is_empty():
				continue
			var item = base.duplicate()
			item["price"] = 0.0
			item["stock"] = qty
			out.append(item)
		return out
	if not SHOPS.has(shop_id):
		return []
	return SHOPS[shop_id]["items"].duplicate(true)

func get_item(shop_id: String, item_id: String) -> Dictionary:
	for item in get_items(shop_id):
		if item["id"] == item_id:
			return item
	return {}

## Cerca un articolo in tutti i negozi (esclude il frigo). Aggiunge il campo 'shop_id'.
func find_item(item_id: String) -> Dictionary:
	for shop_id in SHOPS:
		if shop_id == "fridge":
			continue
		for item in SHOPS[shop_id]["items"]:
			if item["id"] == item_id:
				var found = item.duplicate()
				found["shop_id"] = shop_id
				return found
	return {}

## Prezzo base senza sconto.
func get_base_price(shop_id: String, item_id: String) -> float:
	if shop_id == "fridge":
		return 0.0
	var item = get_item(shop_id, item_id)
	return float(item.get("price", 0.0))

## Prezzo finale con sconto notorietà (e sconto partner -20% da Davide su componenti hardware), arrotondato al centesimo.
func get_price(shop_id: String, item_id: String) -> float:
	var base = get_base_price(shop_id, item_id)
	if base <= 0.0:
		return 0.0
	var mult := 1.0 - FameManager.get_discount()
	if is_hardware_shop(shop_id) and ContractManager.is_contract_completed("elettronica_to"):
		mult *= 0.80
	return snappedf(base * mult, 0.01)

func get_fridge_count(item_id: String = "") -> int:
	if item_id != "":
		return int(fridge_stock.get(item_id, 0))
	var total = 0
	for k in fridge_stock:
		total += int(fridge_stock[k])
	return total

func get_hardware_count(item_id: String = "") -> int:
	if item_id != "":
		return int(hardware_stock.get(item_id, 0))
	var total = 0
	for k in hardware_stock:
		total += int(hardware_stock[k])
	return total

func has_hardware(item_id: String, qty: int = 1) -> bool:
	return get_hardware_count(item_id) >= qty

func get_hardware_item_name(item_id: String) -> String:
	var item = get_item("elettronica_componenti", item_id)
	if not item.is_empty():
		return str(item["name"])
	return item_id

func consume_hardware(item_id: String, qty: int = 1) -> bool:
	if qty <= 0:
		return true
	var cur := get_hardware_count(item_id)
	if cur < qty:
		return false
	var rem := cur - qty
	if rem > 0:
		hardware_stock[item_id] = rem
	else:
		hardware_stock.erase(item_id)
	hardware_changed.emit()
	return true

## Testo descrittivo degli effetti, es. "+35 fame · +5 energia" oppure info hardware.
func describe_effects(item: Dictionary) -> String:
	if item.has("desc"):
		var count = get_hardware_count(str(item.get("id", "")))
		return "%s · In magazzino: x%d" % [str(item["desc"]), count]
	var parts: Array[String] = []
	var h = float(item.get("hunger", 0.0))
	var e = float(item.get("energy", 0.0))
	if h != 0.0:
		parts.append("%+d fame" % int(h))
	if e != 0.0:
		parts.append("%+d energia" % int(e))
	if item.get("id", "") == "rivista_tech":
		parts.append("+1 Rep")
	if parts.is_empty():
		return "nessun effetto"
	return " · ".join(parts)

## Acquista (e consuma subito) un articolo. Per 'fridge' preleva dalle scorte gratuitamente.
## Con fondi insufficienti lo stato non cambia. Ritorna true se l'operazione è riuscita.
func buy(shop_id: String, item_id: String) -> bool:
	if not SHOPS.has(shop_id):
		return false
	if shop_id == "fridge":
		return _take_from_fridge(item_id)
	if is_hardware_shop(shop_id):
		return buy_hardware(item_id, 1)
	var item = get_item(shop_id, item_id)
	if item.is_empty():
		return false
	var price = get_price(shop_id, item_id)
	if not EconomyManager.can_afford(price):
		EventBus.notification_posted.emit("Fondi Insufficienti", "Non ti bastano i soldi per «%s» (€ %0.2f)." % [item["name"], price], "warning")
		SoundManager.play_ui_error()
		return false
	if not EconomyManager.spend(price, "%s: %s" % [get_shop_title(shop_id), item["name"]]):
		return false
	SoundManager.play_cash_register()
	NeedsManager.apply_effects(float(item["hunger"]), float(item["energy"]))
	var rep_gain = FameManager.register_shop_spend(price)
	var extra = _apply_special_effects(item_id)
	var msg = "%s · € %0.2f · %s" % [item["name"], price, describe_effects(item)]
	if rep_gain > 0 and extra == "":
		msg += " · +%d Rep" % rep_gain
	if extra != "":
		msg += " · " + extra
	EventBus.notification_posted.emit("Acquisto: " + get_shop_title(shop_id), msg, "success")
	return true

## Acquista componenti hardware per clienti (stoccati in hardware_stock).
func buy_hardware(item_id: String, qty: int = 1) -> bool:
	if qty <= 0:
		return false
	var item = get_item("elettronica_componenti", item_id)
	if item.is_empty():
		return false
	var unit_price = get_price("elettronica_componenti", item_id)
	var total_price = snappedf(unit_price * float(qty), 0.01)
	if not EconomyManager.can_afford(total_price):
		EventBus.notification_posted.emit("Fondi Insufficienti", "Servono € %0.2f per %dx %s." % [total_price, qty, item["name"]], "warning")
		SoundManager.play_ui_error()
		return false
	if not EconomyManager.spend(total_price, "Fornitura Hardware: %dx %s" % [qty, item["name"]]):
		return false
	SoundManager.play_cash_register()
	hardware_stock[item_id] = int(hardware_stock.get(item_id, 0)) + qty
	var rep_gain = FameManager.register_shop_spend(total_price)
	var msg = "%dx %s aggiunto all'inventario (€ %0.2f · Totale in stock: x%d)" % [qty, item["name"], total_price, get_hardware_count(item_id)]
	if rep_gain > 0:
		msg += " · +%d Rep" % rep_gain
	EventBus.notification_posted.emit("Hardware Acquistato", msg, "success")
	hardware_changed.emit()
	SaveManager.request_auto_save()
	return true

## Acquista un articolo dell'alimentari mettendolo nel frigo dello studio (non lo consuma).
func buy_for_fridge(shop_id: String, item_id: String) -> bool:
	if not is_fridge_stockable(shop_id):
		return false
	var item = get_item(shop_id, item_id)
	if item.is_empty():
		return false
	var price = get_price(shop_id, item_id)
	if not EconomyManager.can_afford(price):
		EventBus.notification_posted.emit("Fondi Insufficienti", "Non ti bastano i soldi per «%s» (€ %0.2f)." % [item["name"], price], "warning")
		SoundManager.play_ui_error()
		return false
	if not EconomyManager.spend(price, "%s: %s (per il frigo)" % [get_shop_title(shop_id), item["name"]]):
		return false
	SoundManager.play_cash_register()
	fridge_stock[item_id] = int(fridge_stock.get(item_id, 0)) + 1
	var rep_gain = FameManager.register_shop_spend(price)
	var msg = "%s riposto nel frigo dello studio (€ %0.2f)." % [item["name"], price]
	if rep_gain > 0:
		msg += " +%d Rep" % rep_gain
	EventBus.notification_posted.emit("Scorte per lo studio", msg, "success")
	fridge_changed.emit()
	return true

func _take_from_fridge(item_id: String) -> bool:
	if int(fridge_stock.get(item_id, 0)) <= 0:
		EventBus.notification_posted.emit("Frigo", "Questo articolo è finito: fai scorta all'Alimentari Rosa.", "warning")
		return false
	var base = find_item(item_id)
	if base.is_empty():
		return false
	fridge_stock[item_id] = int(fridge_stock[item_id]) - 1
	if int(fridge_stock[item_id]) <= 0:
		fridge_stock.erase(item_id)
	NeedsManager.apply_effects(float(base["hunger"]), float(base["energy"]))
	SoundManager.play_ui_success()
	EventBus.notification_posted.emit("Dal frigo", "%s · %s" % [base["name"], describe_effects(base)], "success")
	fridge_changed.emit()
	return true

## Effetti speciali (rivista tech: +1 reputazione una volta al giorno). Ritorna un testo per il toast.
func _apply_special_effects(item_id: String) -> String:
	if item_id == "rivista_tech":
		var today = CalendarSystem.current_day
		if magazine_day != today:
			magazine_day = today
			FameManager.add_reputation(1)
			return "+1 Rep (rivista del giorno)"
		return "oggi hai già guadagnato reputazione dalla rivista"
	return ""

func reset() -> void:
	fridge_stock.clear()
	hardware_stock.clear()
	magazine_day = 0
	fridge_changed.emit()
	hardware_changed.emit()

func serialize() -> Dictionary:
	return {
		"fridge_stock": fridge_stock.duplicate(),
		"hardware_stock": hardware_stock.duplicate(),
		"magazine_day": magazine_day
	}

func deserialize(data: Dictionary) -> void:
	fridge_stock.clear()
	var fs = data.get("fridge_stock", {})
	if fs is Dictionary:
		for k in fs:
			var q = int(fs[k])
			if q > 0:
				fridge_stock[str(k)] = q
	hardware_stock.clear()
	var hs = data.get("hardware_stock", {})
	if hs is Dictionary:
		for k in hs:
			var q = int(hs[k])
			if q > 0:
				hardware_stock[str(k)] = q
	magazine_day = int(data.get("magazine_day", 0))
	fridge_changed.emit()
	hardware_changed.emit()
