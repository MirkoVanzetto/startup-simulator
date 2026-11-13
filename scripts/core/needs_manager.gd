extends Node
## NeedsManager - Fame (hunger) ed energia del giocatore, con malus alla velocità.
## hunger: 0..100 (100 = sazio) - energy: 0..100 (100 = riposato)

# Decadimento per secondo REALE di gioco in FIRST_PERSON:
# fame 100 -> ~25 in 13.5 minuti; energia 100 -> ~25 in ~22 minuti.
const HUNGER_DECAY_PER_SEC: float = 75.0 / 810.0
const ENERGY_DECAY_PER_SEC: float = 75.0 / 1350.0
const SPRINT_ENERGY_PER_SEC: float = 0.30
const COMPUTER_DECAY_FACTOR: float = 0.5
const STARVING_ENERGY_FACTOR: float = 2.0

const HUNGRY_THRESHOLD: float = 30.0
const STARVING_THRESHOLD: float = 10.0
const TIRED_THRESHOLD: float = 25.0
const EXHAUSTED_THRESHOLD: float = 10.0

const HUNGRY_SPEED_MULT: float = 0.85
const STARVING_SPEED_MULT: float = 0.65
const TIRED_SPEED_MULT: float = 0.85
const EXHAUSTED_SPEED_MULT: float = 0.65
const MIN_SPEED_MULT: float = 0.5

const ENERGY_PER_REST_HOUR: float = 12.5 # 8 ore di riposo = 100 energia
const HUNGER_PER_REST_HOUR: float = 3.125 # 8 ore di sonno = -25 fame

var hunger: float = 100.0
var energy: float = 100.0

var _hunger_tier: int = 0
var _energy_tier: int = 0
var _last_emit_h: int = 100
var _last_emit_e: int = 100

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_hunger_tier = get_hunger_tier()
	_energy_tier = get_energy_tier()

func _process(delta: float) -> void:
	tick(delta)

## Avanza i bisogni di `delta` secondi reali, rispettando lo stato di gioco corrente.
func tick(delta: float) -> void:
	var factor = get_decay_factor()
	if factor <= 0.0 or delta <= 0.0:
		return
	var energy_mult = STARVING_ENERGY_FACTOR if hunger < STARVING_THRESHOLD else 1.0
	hunger = clampf(hunger - HUNGER_DECAY_PER_SEC * delta * factor, 0.0, 100.0)
	energy = clampf(energy - ENERGY_DECAY_PER_SEC * delta * factor * energy_mult, 0.0, 100.0)
	_after_change(true)

## Fattore di decadimento in base allo stato: 1.0 a piedi, 0.5 al computer, 0 in menu/pausa/dialogo/negozio.
func get_decay_factor() -> float:
	match GameManager.current_state:
		GameManager.GameState.FIRST_PERSON:
			return 1.0
		GameManager.GameState.COMPUTER, GameManager.GameState.MINIGAME:
			return COMPUTER_DECAY_FACTOR
		_:
			return 0.0

## Consumo extra di energia mentre si scatta (chiamato dal player).
func consume_sprint(delta: float) -> void:
	if delta <= 0.0:
		return
	energy = clampf(energy - SPRINT_ENERGY_PER_SEC * delta, 0.0, 100.0)
	_after_change(true)

func get_hunger() -> float:
	return hunger

func get_energy() -> float:
	return energy

func set_hunger(value: float) -> void:
	hunger = clampf(value, 0.0, 100.0)
	_after_change(false)

func set_energy(value: float) -> void:
	energy = clampf(value, 0.0, 100.0)
	_after_change(false)

func reset() -> void:
	hunger = 100.0
	energy = 100.0
	_hunger_tier = 0
	_energy_tier = 0
	_after_change(false)

## 0 = ok, 1 = fame (<30), 2 = molta fame (<10)
func get_hunger_tier() -> int:
	if hunger < STARVING_THRESHOLD:
		return 2
	if hunger < HUNGRY_THRESHOLD:
		return 1
	return 0

## 0 = ok, 1 = stanco (<25), 2 = esausto (<10)
func get_energy_tier() -> int:
	if energy < EXHAUSTED_THRESHOLD:
		return 2
	if energy < TIRED_THRESHOLD:
		return 1
	return 0

## Moltiplicatore velocità del player (walk e sprint).
func get_speed_multiplier() -> float:
	var mult = 1.0
	match get_hunger_tier():
		1:
			mult *= HUNGRY_SPEED_MULT
		2:
			mult *= STARVING_SPEED_MULT
	match get_energy_tier():
		1:
			mult *= TIRED_SPEED_MULT
		2:
			mult *= EXHAUSTED_SPEED_MULT
	return maxf(mult, MIN_SPEED_MULT)

## Mangia un cibo del catalogo (effetti di default dal primo negozio che lo contiene).
## Restituisce false se l'id è sconosciuto.
func eat(food_id: String) -> bool:
	var item = ShopManager.find_item(food_id)
	if item.is_empty():
		return false
	apply_effects(float(item.get("hunger", 0.0)), float(item.get("energy", 0.0)))
	return true

## Applica delta a fame ed energia (con clamp 0..100).
func apply_effects(hunger_delta: float, energy_delta: float) -> void:
	hunger = clampf(hunger + hunger_delta, 0.0, 100.0)
	energy = clampf(energy + energy_delta, 0.0, 100.0)
	_after_change(false)

## Riposo di `hours` ore: recupera energia, consuma un po' di fame.
func rest(hours: float) -> void:
	if hours <= 0.0:
		return
	apply_effects(-HUNGER_PER_REST_HOUR * hours, ENERGY_PER_REST_HOUR * hours)

## Sonno completo (fino al mattino): energia 100, fame -25.
func sleep_full() -> void:
	apply_effects(-25.0, 100.0)
	energy = 100.0
	_after_change(false)

func serialize() -> Dictionary:
	return {"hunger": hunger, "energy": energy}

func deserialize(data: Dictionary) -> void:
	hunger = clampf(float(data.get("hunger", 100.0)), 0.0, 100.0)
	energy = clampf(float(data.get("energy", 100.0)), 0.0, 100.0)
	_hunger_tier = get_hunger_tier()
	_energy_tier = get_energy_tier()
	_last_emit_h = -1
	_last_emit_e = -1
	_after_change(false, true)

func _after_change(from_tick: bool, silent: bool = false) -> void:
	var ht = get_hunger_tier()
	var et = get_energy_tier()
	if not silent:
		if ht > _hunger_tier:
			if ht == 1:
				EventBus.notification_posted.emit("Hai fame!", "Il tuo stomaco brontola: passa da un negozio del borgo. Cammini più lentamente.", "warning")
			else:
				EventBus.notification_posted.emit("Hai molta fame!", "Sei a digiuno: l'energia cala più in fretta. Mangia qualcosa!", "warning")
		if et > _energy_tier:
			if et == 1:
				EventBus.notification_posted.emit("Sei stanco!", "Hai poca energia: un caffè o una dormita ti rimetteranno in sesto.", "warning")
			else:
				EventBus.notification_posted.emit("Sei esausto!", "Non ce la fai più: riposa o bevi un caffè.", "warning")
	_hunger_tier = ht
	_energy_tier = et
	# Emette needs_changed solo quando cambia il valore intero (evita spam per frame)
	var ih = int(roundf(hunger))
	var ie = int(roundf(energy))
	if ih != _last_emit_h or ie != _last_emit_e:
		_last_emit_h = ih
		_last_emit_e = ie
		EventBus.needs_changed.emit(hunger, energy)
