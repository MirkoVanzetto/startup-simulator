extends Node
## FameManager - Sistema NOTORIETÀ (fama) costruito sopra GameManager.reputation_points.
## La tier è sempre calcolata dai punti reputazione; si persiste solo shop_spent_total e talked_to.

const TIER_THRESHOLDS: Array[int] = [0, 5, 15, 35, 70, 130]
const TIER_NAMES: Array[String] = [
	"Sconosciuto",
	"Conosciuto in Paese",
	"Freelance Apprezzato",
	"Volto del Borgo",
	"Astro Nascente di Torino",
	"Leggenda del Tech"
]
## Sconto sui negozi locali per tier
const TIER_DISCOUNTS: Array[float] = [0.0, 0.03, 0.06, 0.10, 0.14, 0.20]
## Moltiplicatore sul compenso dei NUOVI contratti per tier
const TIER_CONTRACT_BONUS: Array[float] = [1.0, 1.03, 1.07, 1.12, 1.18, 1.25]
## +1 reputazione ogni tot euro spesi nei negozi locali
const SPEND_PER_REP: float = 25.0

var shop_spent_total: float = 0.0
var talked_to: Array[String] = []

var _last_tier: int = 0
var _poll_accum: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_last_tier = get_tier_index()
	EventBus.contract_completed.connect(func(_id, _r, _rep): check_tier())

func _process(delta: float) -> void:
	_poll_accum += delta
	if _poll_accum >= 0.5:
		_poll_accum = 0.0
		check_tier()

static func tier_index_for_points(points: int) -> int:
	var idx = 0
	for i in range(TIER_THRESHOLDS.size()):
		if points >= TIER_THRESHOLDS[i]:
			idx = i
	return idx

func get_tier_index() -> int:
	return tier_index_for_points(GameManager.reputation_points)

func get_tier_name() -> String:
	return TIER_NAMES[get_tier_index()]

## Soglia di punti del prossimo tier (-1 se già al massimo).
func get_next_threshold() -> int:
	var idx = get_tier_index()
	if idx >= TIER_THRESHOLDS.size() - 1:
		return -1
	return TIER_THRESHOLDS[idx + 1]

## Avanzamento 0..1 verso il prossimo tier (1.0 al massimo).
func progress() -> float:
	var idx = get_tier_index()
	if idx >= TIER_THRESHOLDS.size() - 1:
		return 1.0
	var lo = TIER_THRESHOLDS[idx]
	var hi = TIER_THRESHOLDS[idx + 1]
	return clampf(float(GameManager.reputation_points - lo) / float(hi - lo), 0.0, 1.0)

## Sconto dei negozi come frazione (0.0 .. 0.20).
func get_discount() -> float:
	return TIER_DISCOUNTS[get_tier_index()]

## Sconto in percentuale intera (0, 3, 6, 10, 14, 20).
func get_discount_percent() -> int:
	return int(roundf(get_discount() * 100.0))

## Moltiplicatore compenso per i contratti NUOVI (1.0 .. 1.25).
func get_contract_bonus() -> float:
	return TIER_CONTRACT_BONUS[get_tier_index()]

## Etichetta HUD, es. "★ 12 · Conosciuto in Paese"
func get_hud_label() -> String:
	return "★ %d · %s" % [GameManager.reputation_points, get_tier_name()]

## Controlla se la tier è cambiata; se è salita emette il segnale + notifica festosa.
func check_tier() -> void:
	var idx = get_tier_index()
	if idx == _last_tier:
		return
	var went_up = idx > _last_tier
	_last_tier = idx
	EventBus.fame_tier_changed.emit(idx, TIER_NAMES[idx])
	if went_up:
		EventBus.notification_posted.emit(
			"🎉 Nuova Notorietà!",
			"Ora sei «%s»! Sconto %d%% nei negozi del borgo e compensi più alti sui nuovi contratti." % [TIER_NAMES[idx], get_discount_percent()],
			"success"
		)
		SoundManager.play_ui_success()

## Allinea silenziosamente la tier interna (dopo load/reset) senza notifiche.
func sync_silently() -> void:
	_last_tier = get_tier_index()

## Registra una spesa nei negozi locali: +1 rep ogni 25 € spesi in totale. Ritorna i punti guadagnati.
func register_shop_spend(amount: float) -> int:
	if amount <= 0.0:
		return 0
	var before = int(floorf(shop_spent_total / SPEND_PER_REP))
	shop_spent_total += amount
	var after = int(floorf(shop_spent_total / SPEND_PER_REP))
	var gained = after - before
	if gained > 0:
		GameManager.reputation_points += gained
		EventBus.notification_posted.emit("Cliente Affezionato", "+%d Reputazione: il borgo apprezza chi compra locale!" % gained, "success")
	check_tier()
	return gained

## Parlare con un cliente/PNG per la prima volta dà +1 reputazione. Ritorna true se assegnato.
func register_talk(npc_id: String) -> bool:
	if npc_id == "" or npc_id in talked_to:
		return false
	talked_to.append(npc_id)
	GameManager.reputation_points += 1
	EventBus.notification_posted.emit("Nuova Conoscenza", "+1 Reputazione: hai fatto due chiacchiere con un cliente.", "info")
	check_tier()
	return true

## Aggiunge reputazione arbitraria (usato dagli acquisti speciali, es. rivista tech).
func add_reputation(points: int, reason: String = "") -> void:
	if points <= 0:
		return
	GameManager.reputation_points += points
	if reason != "":
		EventBus.notification_posted.emit("Reputazione +%d" % points, reason, "success")
	check_tier()

func reset() -> void:
	shop_spent_total = 0.0
	talked_to.clear()
	_last_tier = get_tier_index()

func serialize() -> Dictionary:
	return {
		"shop_spent_total": shop_spent_total,
		"talked_to": talked_to.duplicate()
	}

func deserialize(data: Dictionary) -> void:
	shop_spent_total = maxf(float(data.get("shop_spent_total", 0.0)), 0.0)
	talked_to.clear()
	for n in data.get("talked_to", []):
		talked_to.append(str(n))
	sync_silently()
