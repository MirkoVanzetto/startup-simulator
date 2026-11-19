extends Control
## ComputerScreen - Simulated Desktop Operating System (TO-OS 26.4 Torino Edition)
## Desktop moderno con sfondo geometrico, App Grid selezionabile, Bottom Dock,
## Posta, Freelance Hub, TorinoHardware, Banca, Rack Manager, Talent Hub,
## Potenziamenti ★ e OGR Enterprise.

@onready var desktop_wallpaper: ColorRect = $DesktopWallpaper
@onready var top_balance_label: Label = $TopBar/HBox/BalanceLabel
@onready var stars_label: Label = $TopBar/HBox/StarsLabel
@onready var clock_label: Label = $TopBar/HBox/ClockLabel
@onready var wifi_label: Label = $TopBar/HBox/WifiLabel
@onready var exit_button: Button = $TopBar/HBox/ExitButton
@onready var windows_root: Control = $Windows

# App windows (scena + finestre procedurali TO-OS 26.4)
@onready var mail_window: PanelContainer = $Windows/MailWindow
@onready var freelance_window: PanelContainer = $Windows/FreelanceWindow
@onready var shop_window: PanelContainer = $Windows/ShopWindow
@onready var bank_window: PanelContainer = $Windows/BankWindow
@onready var rack_window: PanelContainer = $Windows/RackWindow
@onready var talent_window: PanelContainer = $Windows/TalentWindow
var upgrades_window: PanelContainer = null
var knowledge_window: PanelContainer = null
var ogr_window: PanelContainer = null

# Desktop & Dock (TO-OS 26.4)
var desktop_area: Control = null
var desktop_hero_title: Label = null
var desktop_hero_sub: Label = null
var desktop_apps_scroll: ScrollContainer = null
var desktop_apps_grid: GridContainer = null
var bottom_dock: Control = null
var dock_row: HBoxContainer = null

# Mail Window components
@onready var mail_list: ItemList = $Windows/MailWindow/Margin/VBox/Split/MailList
@onready var mail_subject: Label = $Windows/MailWindow/Margin/VBox/Split/MailBody/SubjectLabel
@onready var mail_content: RichTextLabel = $Windows/MailWindow/Margin/VBox/Split/MailBody/ContentLabel
@onready var deliver_project_btn: Button = $Windows/MailWindow/Margin/VBox/Split/MailBody/DeliverButton

# Shop components
@onready var buy_monitor_btn: Button = $Windows/ShopWindow/Margin/VBox/ShopScroll/ShopVBox/Grid/MonitorCard/VBox/HBox/BuyButton
@onready var buy_chair_btn: Button = $Windows/ShopWindow/Margin/VBox/ShopScroll/ShopVBox/Grid/ChairCard/VBox/HBox/BuyButton
@onready var buy_plant_btn: Button = $Windows/ShopWindow/Margin/VBox/ShopScroll/ShopVBox/Grid/PlantCard/VBox/HBox/BuyButton
@onready var buy_server_btn: Button = $Windows/ShopWindow/Margin/VBox/ShopScroll/ShopVBox/Grid/ServerCard/VBox/HBox/BuyButton
@onready var monitor_status: Label = $Windows/ShopWindow/Margin/VBox/ShopScroll/ShopVBox/Grid/MonitorCard/VBox/HBox/StatusLabel
@onready var chair_status: Label = $Windows/ShopWindow/Margin/VBox/ShopScroll/ShopVBox/Grid/ChairCard/VBox/HBox/StatusLabel
@onready var plant_status: Label = $Windows/ShopWindow/Margin/VBox/ShopScroll/ShopVBox/Grid/PlantCard/VBox/HBox/StatusLabel
@onready var server_status: Label = $Windows/ShopWindow/Margin/VBox/ShopScroll/ShopVBox/Grid/ServerCard/VBox/HBox/StatusLabel
@onready var hw_hint_label: Label = $Windows/ShopWindow/Margin/VBox/ShopScroll/ShopVBox/HwHintLabel
@onready var hw_grid: GridContainer = $Windows/ShopWindow/Margin/VBox/ShopScroll/ShopVBox/HwGrid

# Freelance components
@onready var lead_banner_label: Label = $Windows/FreelanceWindow/Margin/VBox/LeadBanner/LeadLabel
@onready var freelance_cards: VBoxContainer = $Windows/FreelanceWindow/Margin/VBox/FreelanceScroll/FreelanceVBox/CardsContainer
@onready var freelance_text: RichTextLabel = $Windows/FreelanceWindow/Margin/VBox/FreelanceScroll/FreelanceVBox/DetailsLabel
@onready var open_webforge_btn: Button = $Windows/FreelanceWindow/Margin/VBox/LaunchWebForgeButton

# Bank components
@onready var bank_ledger_text: RichTextLabel = $Windows/BankWindow/Margin/VBox/LedgerText

# Rack Manager components
@onready var temp_label: Label = $Windows/RackWindow/Margin/VBox/TelemetryBanner/HBox/TempLabel
@onready var fans_label: Label = $Windows/RackWindow/Margin/VBox/TelemetryBanner/HBox/FansLabel
@onready var bandwidth_label: Label = $Windows/RackWindow/Margin/VBox/TelemetryBanner/HBox/BandwidthLabel
@onready var uptime_label: Label = $Windows/RackWindow/Margin/VBox/TelemetryBanner/HBox/UptimeLabel
@onready var cool_silent_btn: Button = $Windows/RackWindow/Margin/VBox/CoolingRow/CoolSilentBtn
@onready var cool_auto_btn: Button = $Windows/RackWindow/Margin/VBox/CoolingRow/CoolAutoBtn
@onready var cool_boost_btn: Button = $Windows/RackWindow/Margin/VBox/CoolingRow/CoolBoostBtn
@onready var recalibrate_btn: Button = $Windows/RackWindow/Margin/VBox/CoolingRow/RecalibrateBtn
@onready var domains_text: RichTextLabel = $Windows/RackWindow/Margin/VBox/Split/DomainsPanel/VBox/DomainsText
@onready var buy_blade_btn: Button = $Windows/RackWindow/Margin/VBox/Split/ModulesPanel/ModulesScroll/VBox/BuyBladeBtn
@onready var buy_liquid_btn: Button = $Windows/RackWindow/Margin/VBox/Split/ModulesPanel/ModulesScroll/VBox/BuyLiquidBtn
@onready var buy_san_btn: Button = $Windows/RackWindow/Margin/VBox/Split/ModulesPanel/ModulesScroll/VBox/BuySanBtn
@onready var upgrade_tier2_btn: Button = $Windows/RackWindow/Margin/VBox/Split/ModulesPanel/ModulesScroll/VBox/UpgradeTier2Btn
@onready var upgrade_tier3_btn: Button = $Windows/RackWindow/Margin/VBox/Split/ModulesPanel/ModulesScroll/VBox/UpgradeTier3Btn

# Talent Hub components
@onready var talent_stats_label: Label = $Windows/TalentWindow/Margin/VBox/StatsBanner/StatsLabel
@onready var candidates_list: VBoxContainer = $Windows/TalentWindow/Margin/VBox/CandidatesScroll/CandidatesList
@onready var firewall_icon: Button = $DesktopIcons/Scroll/VBox/FirewallIcon

# Upgrades ★, Conoscenza R&D & OGR Enterprise dynamic sub-nodes
var upgrades_stars_banner_label: Label = null
var upgrades_grid: GridContainer = null
var knowledge_banner_label: Label = null
var knowledge_banner_actions: HFlowContainer = null
var knowledge_grid: GridContainer = null
var ogr_banner_label: Label = null
var ogr_banner_actions: HFlowContainer = null
var ogr_content_vbox: VBoxContainer = null

var emails: Array[Dictionary] = []
var _selected_email_cid: String = ""
var _app_tiles: Dictionary = {} # app_id -> {btn, badge, accent}
var _dock_buttons: Dictionary = {} # app_id -> Button
var _dock_short_labels: Dictionary = {}
var _dock_wide_labels: Dictionary = {}
var _window_compact_state: Dictionary = {} # PanelContainer -> bool
var _active_app_id: String = "desktop"

const APP_CATALOG: Array[Dictionary] = [
	{"id": "mail", "icon": "✉", "title": "Posta / Mail", "sub": "Email & Consegne", "dock_s": "✉ Mail", "dock_w": "✉ Posta", "accent": Color(0.45, 0.88, 1.0)},
	{"id": "freelance", "icon": "💼", "title": "Freelance Hub", "sub": "Contratti & Lead B2B", "dock_s": "💼 Hub", "dock_w": "💼 Freelance", "accent": Color(1.0, 0.82, 0.35)},
	{"id": "webforge", "icon": "⚡", "title": "WebForge IDE", "sub": "Sviluppo Siti 5.0", "dock_s": "⚡ IDE", "dock_w": "⚡ WebForge", "accent": Color(0.32, 0.96, 1.0)},
	{"id": "shop", "icon": "🛒", "title": "TorinoHardware", "sub": "Studio & Ricambi", "dock_s": "🛒 Shop", "dock_w": "🛒 Shop", "accent": Color(0.45, 1.0, 0.68)},
	{"id": "bank", "icon": "🏛", "title": "Banca & Spese", "sub": "Conto Startup", "dock_s": "🏛 €", "dock_w": "🏛 Banca", "accent": Color(0.35, 1.0, 0.58)},
	{"id": "rack", "icon": "🖥", "title": "Rack Manager", "sub": "Cluster 19\" Cloud", "dock_s": "🖥 Rack", "dock_w": "🖥 Rack 19\"", "accent": Color(0.38, 0.85, 1.0)},
	{"id": "talent", "icon": "👥", "title": "Talent Hub HR", "sub": "Team & Sede", "dock_s": "👥 HR", "dock_w": "👥 Talent HR", "accent": Color(0.84, 0.70, 1.0)},
	{"id": "firewall", "icon": "🛡", "title": "NetShield Cyber", "sub": "Reti, VLAN & DMZ", "dock_s": "🛡 Net", "dock_w": "🛡 NetShield", "accent": Color(1.0, 0.62, 0.25)},
	{"id": "upgrades", "icon": "★", "title": "Potenziamenti ★", "sub": "Albero Abilità", "dock_s": "★ Skill", "dock_w": "★ Skill", "accent": Color(1.0, 0.86, 0.30)},
	{"id": "knowledge", "icon": "📘", "title": "Conoscenza R&D", "sub": "Ricerca Post-Bellini", "dock_s": "📘 R&D", "dock_w": "📘 Ricerca", "accent": Color(0.52, 0.88, 1.0)},
	{"id": "ogr", "icon": "🏢", "title": "OGR Enterprise", "sub": "Appalti Corporate", "dock_s": "🏢 OGR", "dock_w": "🏢 OGR Corp", "accent": Color(0.40, 0.95, 0.92)}
]

func _ready() -> void:
	visible = false
	_build_to_os_desktop_and_apps()
	_enhance_all_window_headers()

	EventBus.computer_opened.connect(_on_computer_opened)
	EventBus.computer_closed.connect(_on_computer_closed)
	EventBus.funds_changed.connect(_on_funds_changed)
	EventBus.contract_updated.connect(_on_contract_updated)
	EventBus.contract_completed.connect(func(_id, _r, _rep):
		_update_freelance_display()
		_update_shop_buttons()
		_setup_emails()
		_update_rack_display()
		_update_knowledge_display()
		_update_ogr_display()
		_refresh_desktop_badges()
	)
	EventBus.stars_changed.connect(func(_s, _d, _r):
		_update_top_bar()
		_update_upgrades_display()
		_update_ogr_display()
		_refresh_desktop_badges()
	)
	EventBus.upgrade_purchased.connect(func(_uid, _rk):
		_update_top_bar()
		_update_upgrades_display()
		_update_ogr_display()
		_update_rack_display()
		_refresh_desktop_badges()
	)
	EventBus.knowledge_upgraded.connect(func(_tid, _rk):
		_update_top_bar()
		_update_knowledge_display()
		_update_freelance_display()
		_update_rack_display()
		_update_ogr_display()
		_refresh_desktop_badges()
	)
	EventBus.ogr_hub_unlocked.connect(func():
		_update_knowledge_display()
		_update_ogr_display()
		_refresh_desktop_badges()
	)

	exit_button.pressed.connect(_on_exit_pressed)

	# Legacy sidebar icons (nascosti ma mantenuti connessi per compatibilità)
	$DesktopIcons/Scroll/VBox/MailIcon.pressed.connect(func(): _open_window(mail_window))
	$DesktopIcons/Scroll/VBox/FreelanceIcon.pressed.connect(func(): _open_window(freelance_window))
	$DesktopIcons/Scroll/VBox/WebForgeIcon.pressed.connect(_launch_webforge)
	$DesktopIcons/Scroll/VBox/ShopIcon.pressed.connect(func(): _open_window(shop_window))
	$DesktopIcons/Scroll/VBox/BankIcon.pressed.connect(func(): _open_window(bank_window))
	$DesktopIcons/Scroll/VBox/RackIcon.pressed.connect(func(): _open_window(rack_window))
	$DesktopIcons/Scroll/VBox/TalentIcon.pressed.connect(func(): _open_window(talent_window))
	firewall_icon.pressed.connect(_launch_firewall)

	# Window buttons close -> return to TO-OS Desktop
	for win in _all_windows():
		var close_btn := win.get_node_or_null("Margin/VBox/Header/CloseBtn") as Button
		if close_btn:
			close_btn.pressed.connect(_show_desktop)

	mail_list.item_selected.connect(_on_mail_selected)
	deliver_project_btn.pressed.connect(_on_deliver_project_pressed)
	open_webforge_btn.pressed.connect(_launch_webforge)
	buy_monitor_btn.pressed.connect(_buy_monitor)
	buy_chair_btn.pressed.connect(_buy_chair)
	buy_plant_btn.pressed.connect(_buy_plant)
	buy_server_btn.pressed.connect(_buy_server)

	# Rack Manager buttons
	cool_silent_btn.pressed.connect(func(): ServerRackManager.set_cooling_mode("silent"))
	cool_auto_btn.pressed.connect(func(): ServerRackManager.set_cooling_mode("auto"))
	cool_boost_btn.pressed.connect(func(): ServerRackManager.set_cooling_mode("boost"))
	recalibrate_btn.pressed.connect(func(): ServerRackManager.resolve_physical_maintenance(); _update_rack_display())
	buy_blade_btn.pressed.connect(_buy_blade)
	buy_liquid_btn.pressed.connect(_buy_liquid)
	buy_san_btn.pressed.connect(_buy_san)
	upgrade_tier2_btn.pressed.connect(func(): ServerRackManager.upgrade_rack_tier(2); _update_rack_display())
	upgrade_tier3_btn.pressed.connect(func(): ServerRackManager.upgrade_rack_tier(3); _update_rack_display())

	ServerRackManager.telemetry_updated.connect(_on_rack_telemetry)
	EventBus.employee_hired.connect(func(_id, _n):
		_update_talent_display()
		_update_freelance_display()
		_update_ogr_display()
		_refresh_desktop_badges()
	)
	EventBus.employee_fired.connect(func(_id):
		_update_talent_display()
		_update_freelance_display()
		_update_ogr_display()
		_refresh_desktop_badges()
	)
	if ShopManager.has_signal("hardware_changed"):
		ShopManager.hardware_changed.connect(func():
			_update_shop_buttons()
			_update_freelance_display()
			_update_ogr_display()
		)

	_setup_emails()
	_update_shop_buttons()
	_update_freelance_display()
	_update_upgrades_display()
	_update_knowledge_display()
	_update_ogr_display()
	_update_top_bar()
	_show_desktop()

	resized.connect(_update_responsive_layout)
	_update_responsive_layout()

	EventBus.time_tick.connect(func(_h, _m, _d):
		_update_top_bar()
		if visible and freelance_window.visible:
			_update_lead_banner_only()
	)
	EventBus.contract_marketplace_refreshed.connect(func():
		_update_freelance_display()
		_update_ogr_display()
		_refresh_desktop_badges()
	)

func _all_windows() -> Array[PanelContainer]:
	var arr: Array[PanelContainer] = [mail_window, freelance_window, shop_window, bank_window, rack_window, talent_window]
	if upgrades_window:
		arr.append(upgrades_window)
	if knowledge_window:
		arr.append(knowledge_window)
	if ogr_window:
		arr.append(ogr_window)
	return arr

func _make_frosted_style(bg: Color, border: Color, radius: int = 10, bw: int = 1) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(radius)
	return sb

func _build_to_os_desktop_and_apps() -> void:
	# 1. DesktopArea (sopra DesktopWallpaper, sotto $Windows)
	desktop_area = Control.new()
	desktop_area.name = "DesktopArea"
	desktop_area.set_anchors_preset(Control.PRESET_FULL_RECT)
	desktop_area.offset_left = 18.0
	desktop_area.offset_top = 52.0
	desktop_area.offset_right = -18.0
	desktop_area.offset_bottom = -64.0
	desktop_area.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(desktop_area)
	move_child(desktop_area, windows_root.get_index())

	var d_vbox := VBoxContainer.new()
	d_vbox.name = "DesktopVBox"
	d_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	d_vbox.add_theme_constant_override("separation", 10)
	desktop_area.add_child(d_vbox)

	# Hero banner trasparente
	var hero := PanelContainer.new()
	hero.name = "HeroBanner"
	var hero_sb := _make_frosted_style(Color(0.055, 0.105, 0.175, 0.72), Color(0.32, 0.78, 0.96, 0.38), 10, 1)
	hero_sb.set_content_margin_all(10)
	hero.add_theme_stylebox_override("panel", hero_sb)
	d_vbox.add_child(hero)

	var h_vbox := VBoxContainer.new()
	h_vbox.add_theme_constant_override("separation", 2)
	hero.add_child(h_vbox)

	desktop_hero_title = Label.new()
	desktop_hero_title.text = "❖ DESKTOP TO-OS 26.4 — WORKSPACE TORINO"
	desktop_hero_title.add_theme_font_size_override("font_size", 15)
	desktop_hero_title.add_theme_color_override("font_color", Color(0.55, 0.92, 1.0))
	desktop_hero_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	h_vbox.add_child(desktop_hero_title)

	desktop_hero_sub = Label.new()
	desktop_hero_sub.text = "Seleziona un'app qui sotto o usa la barra rapida in basso."
	desktop_hero_sub.add_theme_font_size_override("font_size", 12)
	desktop_hero_sub.add_theme_color_override("font_color", Color(0.80, 0.89, 0.96))
	desktop_hero_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	h_vbox.add_child(desktop_hero_sub)

	# Griglia App centrata
	desktop_apps_scroll = ScrollContainer.new()
	desktop_apps_scroll.name = "AppsScroll"
	desktop_apps_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desktop_apps_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	desktop_apps_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	d_vbox.add_child(desktop_apps_scroll)

	var center_box := CenterContainer.new()
	center_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desktop_apps_scroll.add_child(center_box)

	desktop_apps_grid = GridContainer.new()
	desktop_apps_grid.name = "DesktopAppsGrid"
	desktop_apps_grid.columns = 5
	desktop_apps_grid.add_theme_constant_override("h_separation", 12)
	desktop_apps_grid.add_theme_constant_override("v_separation", 12)
	center_box.add_child(desktop_apps_grid)

	for app in APP_CATALOG:
		var aid := str(app["id"])
		var acc: Color = app["accent"]

		var tile_btn := Button.new()
		tile_btn.name = "AppTile_" + aid
		tile_btn.custom_minimum_size = Vector2(146, 86)
		tile_btn.focus_mode = Control.FOCUS_NONE
		tile_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

		var n_sb := _make_frosted_style(Color(0.075, 0.135, 0.215, 0.82), Color(acc.r, acc.g, acc.b, 0.45), 10, 1)
		n_sb.set_content_margin_all(8)
		var h_sb := _make_frosted_style(Color(0.115, 0.215, 0.325, 0.94), Color(acc.r, acc.g, acc.b, 0.95), 10, 2)
		h_sb.set_content_margin_all(8)
		var p_sb := _make_frosted_style(Color(0.055, 0.110, 0.180, 0.96), acc, 10, 2)
		p_sb.set_content_margin_all(8)
		tile_btn.add_theme_stylebox_override("normal", n_sb)
		tile_btn.add_theme_stylebox_override("hover", h_sb)
		tile_btn.add_theme_stylebox_override("pressed", p_sb)

		var tv := VBoxContainer.new()
		tv.set_anchors_preset(Control.PRESET_FULL_RECT)
		tv.offset_left = 8
		tv.offset_top = 6
		tv.offset_right = -8
		tv.offset_bottom = -6
		tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tv.add_theme_constant_override("separation", 2)
		tile_btn.add_child(tv)

		var top_line := HBoxContainer.new()
		top_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tv.add_child(top_line)

		var ico_lbl := Label.new()
		ico_lbl.text = str(app["icon"])
		ico_lbl.add_theme_font_size_override("font_size", 20)
		ico_lbl.add_theme_color_override("font_color", acc)
		ico_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		top_line.add_child(ico_lbl)

		var sp := Control.new()
		sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		top_line.add_child(sp)

		var badge_lbl := Label.new()
		badge_lbl.text = ""
		badge_lbl.add_theme_font_size_override("font_size", 10)
		badge_lbl.add_theme_color_override("font_color", acc)
		badge_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		top_line.add_child(badge_lbl)

		var title_lbl := Label.new()
		title_lbl.text = str(app["title"])
		title_lbl.add_theme_font_size_override("font_size", 13)
		title_lbl.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0))
		title_lbl.clip_text = true
		title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tv.add_child(title_lbl)

		var sub_lbl := Label.new()
		sub_lbl.text = str(app["sub"])
		sub_lbl.add_theme_font_size_override("font_size", 10)
		sub_lbl.add_theme_color_override("font_color", Color(0.68, 0.78, 0.88))
		sub_lbl.clip_text = true
		sub_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tv.add_child(sub_lbl)

		var aid_copy := aid
		tile_btn.pressed.connect(func(): open_app(aid_copy))
		desktop_apps_grid.add_child(tile_btn)
		_app_tiles[aid] = {"btn": tile_btn, "badge": badge_lbl, "sub": sub_lbl, "accent": acc}

	# 2. BottomDock (pill trasparente centrata in basso)
	bottom_dock = Control.new()
	bottom_dock.name = "BottomDock"
	bottom_dock.anchor_left = 0.0
	bottom_dock.anchor_top = 1.0
	bottom_dock.anchor_right = 1.0
	bottom_dock.anchor_bottom = 1.0
	bottom_dock.offset_top = -54.0
	bottom_dock.offset_bottom = -8.0
	bottom_dock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bottom_dock)

	var dock_center := CenterContainer.new()
	dock_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dock_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_dock.add_child(dock_center)

	var dock_panel := PanelContainer.new()
	dock_panel.name = "DockPanel"
	var dock_sb := _make_frosted_style(Color(0.05, 0.085, 0.14, 0.90), Color(0.32, 0.72, 0.92, 0.42), 12, 1)
	dock_sb.content_margin_left = 5
	dock_sb.content_margin_right = 5
	dock_sb.content_margin_top = 4
	dock_sb.content_margin_bottom = 4
	dock_panel.add_theme_stylebox_override("panel", dock_sb)
	dock_center.add_child(dock_panel)

	dock_row = HBoxContainer.new()
	dock_row.name = "DockRow"
	dock_row.add_theme_constant_override("separation", 2)
	dock_panel.add_child(dock_row)

	_add_dock_button("desktop", "❖ OS", "❖ Desktop", "Torna al Desktop TO-OS", Color(0.55, 0.92, 1.0))
	for app in APP_CATALOG:
		_add_dock_button(str(app["id"]), str(app["dock_s"]), str(app["dock_w"]), str(app["title"]), app["accent"])

	# 3. Finestre procedurali: Potenziamenti ★, Conoscenza R&D e OGR Enterprise
	_build_upgrades_window()
	_build_knowledge_window()
	_build_ogr_window()

func _add_dock_button(app_id: String, short_lbl: String, wide_lbl: String, tip: String, accent: Color) -> void:
	var btn := Button.new()
	btn.name = "Dock_" + app_id
	btn.text = short_lbl
	btn.tooltip_text = tip
	btn.focus_mode = Control.FOCUS_NONE
	btn.clip_text = true
	btn.custom_minimum_size = Vector2(54, 34)
	btn.add_theme_font_size_override("font_size", 10)
	btn.add_theme_color_override("font_color", accent)
	btn.pressed.connect(func():
		if app_id == "desktop":
			SoundManager.play_ui_click()
			_show_desktop()
		else:
			open_app(app_id)
	)
	dock_row.add_child(btn)
	_dock_buttons[app_id] = btn
	_dock_short_labels[app_id] = short_lbl
	_dock_wide_labels[app_id] = wide_lbl

func _create_window_shell(node_name: String, title_text: String, title_col: Color) -> Dictionary:
	var win := PanelContainer.new()
	win.name = node_name
	win.visible = false
	win.set_anchors_preset(Control.PRESET_FULL_RECT)
	win.add_theme_stylebox_override("panel", _make_frosted_style(Color(0.075, 0.115, 0.180, 0.91), Color(0.32, 0.72, 0.92, 0.55), 10, 1))
	windows_root.add_child(win)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	win.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var header := HBoxContainer.new()
	header.name = "Header"
	header.add_theme_constant_override("separation", 6)
	vbox.add_child(header)

	var title := Label.new()
	title.name = "Title"
	title.text = title_text
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", title_col)
	header.add_child(title)

	var spacer := Control.new()
	spacer.name = "Spacer"
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)

	var close_btn := Button.new()
	close_btn.name = "CloseBtn"
	close_btn.text = " ✕ "
	header.add_child(close_btn)

	return {"win": win, "vbox": vbox}

func _build_upgrades_window() -> void:
	var shell := _create_window_shell("UpgradesWindow", "POTENZIAMENTI ★ — ALBERO ABILITÀ STARTUP", Color(1.0, 0.86, 0.35))
	upgrades_window = shell["win"]
	var vbox: VBoxContainer = shell["vbox"]

	var banner := PanelContainer.new()
	banner.add_theme_stylebox_override("panel", _make_frosted_style(Color(0.115, 0.168, 0.245, 0.90), Color(0.95, 0.78, 0.25, 0.45), 8, 1))
	var bm := MarginContainer.new()
	bm.add_theme_constant_override("margin_left", 10)
	bm.add_theme_constant_override("margin_right", 10)
	bm.add_theme_constant_override("margin_top", 8)
	bm.add_theme_constant_override("margin_bottom", 8)
	banner.add_child(bm)

	upgrades_stars_banner_label = Label.new()
	upgrades_stars_banner_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	upgrades_stars_banner_label.add_theme_font_size_override("font_size", 12)
	upgrades_stars_banner_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.62))
	bm.add_child(upgrades_stars_banner_label)
	vbox.add_child(banner)

	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(sc)

	upgrades_grid = GridContainer.new()
	upgrades_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upgrades_grid.columns = 2
	upgrades_grid.add_theme_constant_override("h_separation", 12)
	upgrades_grid.add_theme_constant_override("v_separation", 12)
	sc.add_child(upgrades_grid)

func _build_knowledge_window() -> void:
	var shell := _create_window_shell("KnowledgeWindow", "CONOSCENZA R&D — RICERCA TECNOLOGICA TORINO", Color(0.52, 0.88, 1.0))
	knowledge_window = shell["win"]
	var vbox: VBoxContainer = shell["vbox"]

	var banner := PanelContainer.new()
	banner.add_theme_stylebox_override("panel", _make_frosted_style(Color(0.105, 0.165, 0.245, 0.90), Color(0.45, 0.85, 1.0, 0.50), 8, 1))
	var bm := MarginContainer.new()
	bm.add_theme_constant_override("margin_left", 10)
	bm.add_theme_constant_override("margin_right", 10)
	bm.add_theme_constant_override("margin_top", 8)
	bm.add_theme_constant_override("margin_bottom", 8)
	banner.add_child(bm)

	var bv := VBoxContainer.new()
	bv.add_theme_constant_override("separation", 6)
	bm.add_child(bv)

	knowledge_banner_label = Label.new()
	knowledge_banner_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	knowledge_banner_label.add_theme_font_size_override("font_size", 12)
	knowledge_banner_label.add_theme_color_override("font_color", Color(0.84, 0.95, 1.0))
	bv.add_child(knowledge_banner_label)

	knowledge_banner_actions = HFlowContainer.new()
	knowledge_banner_actions.add_theme_constant_override("h_separation", 8)
	knowledge_banner_actions.add_theme_constant_override("v_separation", 6)
	bv.add_child(knowledge_banner_actions)
	vbox.add_child(banner)

	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(sc)

	knowledge_grid = GridContainer.new()
	knowledge_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	knowledge_grid.columns = 2
	knowledge_grid.add_theme_constant_override("h_separation", 12)
	knowledge_grid.add_theme_constant_override("v_separation", 12)
	sc.add_child(knowledge_grid)

func _build_ogr_window() -> void:
	var shell := _create_window_shell("OgrWindow", "OGR TECH HUB TORINO — APPALTI ENTERPRISE", Color(0.42, 0.94, 1.0))
	ogr_window = shell["win"]
	var vbox: VBoxContainer = shell["vbox"]

	var banner := PanelContainer.new()
	banner.add_theme_stylebox_override("panel", _make_frosted_style(Color(0.11, 0.165, 0.24, 0.90), Color(0.32, 0.78, 0.96, 0.50), 8, 1))
	var bm := MarginContainer.new()
	bm.add_theme_constant_override("margin_left", 10)
	bm.add_theme_constant_override("margin_right", 10)
	bm.add_theme_constant_override("margin_top", 8)
	bm.add_theme_constant_override("margin_bottom", 8)
	banner.add_child(bm)

	var bv := VBoxContainer.new()
	bv.add_theme_constant_override("separation", 6)
	bm.add_child(bv)

	ogr_banner_label = Label.new()
	ogr_banner_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ogr_banner_label.add_theme_font_size_override("font_size", 12)
	ogr_banner_label.add_theme_color_override("font_color", Color(0.84, 0.95, 1.0))
	bv.add_child(ogr_banner_label)

	ogr_banner_actions = HFlowContainer.new()
	ogr_banner_actions.add_theme_constant_override("h_separation", 8)
	ogr_banner_actions.add_theme_constant_override("v_separation", 6)
	bv.add_child(ogr_banner_actions)
	vbox.add_child(banner)

	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(sc)

	ogr_content_vbox = VBoxContainer.new()
	ogr_content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ogr_content_vbox.add_theme_constant_override("separation", 10)
	sc.add_child(ogr_content_vbox)

func _enhance_all_window_headers() -> void:
	for win in _all_windows():
		_window_compact_state[win] = false
		var hdr := win.get_node_or_null("Margin/VBox/Header") as HBoxContainer
		if hdr == null:
			continue
		var close_btn := hdr.get_node_or_null("CloseBtn") as Button
		if close_btn == null:
			continue
		close_btn.focus_mode = Control.FOCUS_NONE

		var min_btn := Button.new()
		min_btn.name = "MinBtn"
		min_btn.text = " _ "
		min_btn.tooltip_text = "Riduci sul Desktop"
		min_btn.focus_mode = Control.FOCUS_NONE
		min_btn.pressed.connect(func():
			SoundManager.play_ui_click()
			_show_desktop()
		)
		hdr.add_child(min_btn)
		hdr.move_child(min_btn, close_btn.get_index())

		var max_btn := Button.new()
		max_btn.name = "MaxBtn"
		max_btn.text = " □ "
		max_btn.tooltip_text = "Alterna Finestra Compatta / Schermo Intero"
		max_btn.focus_mode = Control.FOCUS_NONE
		var w_ref := win
		max_btn.pressed.connect(func():
			SoundManager.play_ui_click()
			_toggle_window_compact(w_ref)
		)
		hdr.add_child(max_btn)
		hdr.move_child(max_btn, close_btn.get_index())

func _toggle_window_compact(win: PanelContainer) -> void:
	var next_compact := not bool(_window_compact_state.get(win, false))
	_window_compact_state[win] = next_compact
	if next_compact:
		win.anchor_left = 0.06
		win.anchor_top = 0.05
		win.anchor_right = 0.94
		win.anchor_bottom = 0.95
	else:
		win.anchor_left = 0.0
		win.anchor_top = 0.0
		win.anchor_right = 1.0
		win.anchor_bottom = 1.0
	win.offset_left = 0.0
	win.offset_top = 0.0
	win.offset_right = 0.0
	win.offset_bottom = 0.0

func _update_responsive_layout() -> void:
	var w := size.x if size.x > 10.0 else 1280.0
	if wifi_label:
		wifi_label.visible = (w >= 920.0)
	if desktop_apps_grid:
		var avail_w := w - 48.0
		var cols := 5 if avail_w >= 900.0 else (4 if avail_w >= 650.0 else 3)
		desktop_apps_grid.columns = cols
		var tile_w := 168.0 if avail_w >= 1060.0 else 146.0
		var tile_h := 94.0 if avail_w >= 1060.0 else 86.0
		for aid in _app_tiles:
			var tbtn := _app_tiles[aid]["btn"] as Button
			if tbtn:
				tbtn.custom_minimum_size = Vector2(tile_w, tile_h)
	var u_avail := w - 72.0
	if upgrades_grid:
		upgrades_grid.columns = 2 if u_avail >= 560.0 else 1
	if knowledge_grid:
		knowledge_grid.columns = 2 if u_avail >= 560.0 else 1
	var use_wide_dock := (w >= 1120.0)
	if dock_row:
		dock_row.add_theme_constant_override("separation", 4 if use_wide_dock else 2)
	for aid in _dock_buttons:
		var db := _dock_buttons[aid] as Button
		if db:
			db.text = _dock_wide_labels[aid] if use_wide_dock else _dock_short_labels[aid]
			db.custom_minimum_size = Vector2(82 if use_wide_dock else 54, 34)
			db.add_theme_font_size_override("font_size", 11 if use_wide_dock else 10)

func _show_desktop() -> void:
	_active_app_id = "desktop"
	for w in _all_windows():
		w.visible = false
	if desktop_area:
		desktop_area.visible = true
	_refresh_desktop_badges()
	_sync_dock_highlight()

func open_app(app_id: String) -> void:
	match app_id:
		"mail":
			_open_window(mail_window)
		"freelance":
			_open_window(freelance_window)
		"webforge":
			_launch_webforge()
		"shop":
			_open_window(shop_window)
		"bank":
			_open_window(bank_window)
		"rack":
			_open_window(rack_window)
		"talent":
			_open_window(talent_window)
		"firewall":
			_launch_firewall()
		"upgrades":
			_open_window(upgrades_window)
		"knowledge":
			_open_window(knowledge_window)
		"ogr":
			_open_window(ogr_window)
		_:
			_show_desktop()

func _window_to_app_id(win: PanelContainer) -> String:
	if win == mail_window: return "mail"
	if win == freelance_window: return "freelance"
	if win == shop_window: return "shop"
	if win == bank_window: return "bank"
	if win == rack_window: return "rack"
	if win == talent_window: return "talent"
	if win == upgrades_window: return "upgrades"
	if win == knowledge_window: return "knowledge"
	if win == ogr_window: return "ogr"
	return "desktop"

func _sync_dock_highlight() -> void:
	for aid in _dock_buttons:
		var btn := _dock_buttons[aid] as Button
		if not btn:
			continue
		if aid == _active_app_id:
			var hi := _make_frosted_style(Color(0.14, 0.30, 0.45, 0.96), Color(0.45, 0.92, 1.0, 0.95), 7, 1)
			hi.content_margin_left = 4
			hi.content_margin_right = 4
			btn.add_theme_stylebox_override("normal", hi)
		else:
			btn.remove_theme_stylebox_override("normal")

func _refresh_desktop_badges() -> void:
	var stars_count := UpgradeManager.get_stars() if is_instance_valid(UpgradeManager) else 0
	var ogr_open := ContractManager.is_ogr_unlocked()
	if desktop_hero_sub:
		var tier_n := GameManager.get_company_tier_name() if GameManager.has_method("get_company_tier_name") else "Studio"
		var ogr_s := "OGR Sbloccata ✔" if ogr_open else "OGR 🔒 (Completa Via Po & Bellini)"
		var rd_s := ("R&D %d/%d" % [KnowledgeManager.get_total_rank(), KnowledgeManager.TRACK_ORDER.size() * KnowledgeManager.MAX_RANK]) if (is_instance_valid(KnowledgeManager) and KnowledgeManager.is_unlocked()) else "R&D 🔒"
		desktop_hero_sub.text = "Sede: %s · Rep: %d · Stelle: %d ★ · Lead: %d · %s · %s" % [
			tier_n, GameManager.reputation_points, stars_count, ContractManager.marketplace_contracts.size(), rd_s, ogr_s
		]

	if _app_tiles.has("mail"):
		var ready_deliver := 0
		for ac in ContractManager.active_contracts.values():
			if ac is Dictionary and str(ac.get("status", "")) == "built":
				ready_deliver += 1
		(_app_tiles["mail"]["badge"] as Label).text = "%d pronte" % ready_deliver if ready_deliver > 0 else "%d mail" % emails.size()

	if _app_tiles.has("freelance"):
		var n_mkt := ContractManager.marketplace_contracts.size()
		(_app_tiles["freelance"]["badge"] as Label).text = "%d offerte" % n_mkt if n_mkt > 0 else "Attivo"

	if _app_tiles.has("upgrades"):
		var buyable := 0
		if is_instance_valid(UpgradeManager):
			for up in UpgradeManager.get_all_upgrades():
				if bool(up.get("can_afford", false)):
					buyable += 1
		(_app_tiles["upgrades"]["badge"] as Label).text = "%d ★ (%d ok)" % [stars_count, buyable] if buyable > 0 else "%d ★" % stars_count

	if _app_tiles.has("knowledge"):
		if is_instance_valid(KnowledgeManager) and KnowledgeManager.is_unlocked():
			var tot_r := KnowledgeManager.get_total_rank()
			var max_r := KnowledgeManager.TRACK_ORDER.size() * KnowledgeManager.MAX_RANK
			(_app_tiles["knowledge"]["badge"] as Label).text = "Lv.%d/%d" % [tot_r, max_r]
		else:
			(_app_tiles["knowledge"]["badge"] as Label).text = "🔒 Bellini"

	if _app_tiles.has("ogr"):
		(_app_tiles["ogr"]["badge"] as Label).text = ("Tier %d (%d)" % [UpgradeManager.get_enterprise_tier() if is_instance_valid(UpgradeManager) else 1, ContractManager.enterprise_contracts.size()]) if ogr_open else "🔒 Bloccato"

func _on_computer_opened() -> void:
	visible = true
	SoundManager.play_keyboard_sound()
	_update_top_bar()
	_setup_emails()
	_update_freelance_display()
	_update_bank_display()
	_update_shop_buttons()
	_update_rack_display()
	_update_talent_display()
	_update_upgrades_display()
	_update_knowledge_display()
	_update_ogr_display()
	_update_responsive_layout()
	_show_desktop()

func _on_computer_closed() -> void:
	visible = false

func _on_exit_pressed() -> void:
	SoundManager.play_ui_click()
	EventBus.computer_closed.emit()

func _update_top_bar() -> void:
	top_balance_label.text = "Fondi: € %0.2f" % EconomyManager.balance
	clock_label.text = "%s - Giorno %d (%s)" % [CalendarSystem.get_formatted_time(), CalendarSystem.current_day, CalendarSystem.get_day_name()]
	if stars_label:
		var st := UpgradeManager.get_stars() if is_instance_valid(UpgradeManager) else 0
		var rc := TechOpsManager.research_credits if is_instance_valid(TechOpsManager) else 0
		if rc > 0 or (is_instance_valid(TechOpsManager) and TechOpsManager.ogr_tech_mission_started):
			stars_label.text = "★ %d · 🔬 %d RC" % [st, rc]
		else:
			stars_label.text = "★ %d" % st


func _on_funds_changed(new_balance: float, _delta: float, _reason: String) -> void:
	top_balance_label.text = "Fondi: € %0.2f" % new_balance
	_update_shop_buttons()
	_update_bank_display()
	_update_rack_display()
	_update_knowledge_display()
	_update_ogr_display()
	if freelance_window.visible:
		_update_freelance_display()

func _on_contract_updated(_id: String, _status: String) -> void:
	_update_freelance_display()
	_update_knowledge_display()
	_update_ogr_display()
	_setup_emails()
	_refresh_desktop_badges()

func _open_window(target_window: PanelContainer) -> void:
	if target_window == null:
		return
	SoundManager.play_ui_click()
	if desktop_area:
		desktop_area.visible = false
	for w in _all_windows():
		w.visible = false
	target_window.visible = true
	_active_app_id = _window_to_app_id(target_window)
	_sync_dock_highlight()

	if target_window == freelance_window:
		_update_freelance_display()
	elif target_window == shop_window:
		_update_shop_buttons()
	elif target_window == bank_window:
		_update_bank_display()
	elif target_window == rack_window:
		_update_rack_display()
	elif target_window == talent_window:
		_update_talent_display()
	elif target_window == upgrades_window:
		_update_upgrades_display()
	elif target_window == knowledge_window:
		_update_knowledge_display()
	elif target_window == ogr_window:
		_update_ogr_display()

# ==============================================================================
# POTENZIAMENTI ★ UI
# ==============================================================================
func _update_upgrades_display() -> void:
	if not upgrades_window or not upgrades_grid:
		return
	for ch in upgrades_grid.get_children():
		ch.queue_free()

	var sc := UpgradeManager.get_stars() if is_instance_valid(UpgradeManager) else 0
	var list := UpgradeManager.get_all_upgrades() if is_instance_valid(UpgradeManager) else []
	var unlocked_total := 0
	for item in list:
		unlocked_total += int(item.get("rank", 0))
	if upgrades_stars_banner_label:
		upgrades_stars_banner_label.text = "★ Stelle Disponibili: %d ★  |  Livelli Sbloccati: %d / %d  —  Guadagna Stelle da Contratti, Bandi OGR, Notorietà e Lavoretti (ogni 2 = +1 ★)." % [
			sc, unlocked_total, list.size() * UpgradeManager.MAX_RANK
		]

	for up in list:
		var uid := str(up["id"])
		var rk := int(up["rank"])
		var max_rk := int(up["max_rank"])
		var next_cost := int(up["next_cost"])
		var can_buy := bool(up["can_afford"])
		var labels: Array = up.get("effect_labels", [])

		var border_col := Color(0.35, 1.0, 0.58, 0.78) if rk >= max_rk else (Color(1.0, 0.85, 0.30, 0.85) if can_buy else Color(0.30, 0.50, 0.72, 0.65))
		var card := _make_hub_card(Color(0.11, 0.16, 0.24, 0.94), border_col)
		card.custom_minimum_size = Vector2(220, 146)

		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 5)
		card.add_child(cv)

		var top := HBoxContainer.new()
		var t_lbl := Label.new()
		t_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		t_lbl.text = "%s %s" % [str(up["icon"]), str(up["title"])]
		t_lbl.add_theme_font_size_override("font_size", 14)
		t_lbl.add_theme_color_override("font_color", Color(0.55, 0.92, 1.0))
		t_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		top.add_child(t_lbl)

		var stars_badge := Label.new()
		stars_badge.text = "★".repeat(rk) + "☆".repeat(maxi(0, max_rk - rk))
		stars_badge.add_theme_font_size_override("font_size", 13)
		stars_badge.add_theme_color_override("font_color", Color(1.0, 0.86, 0.32))
		top.add_child(stars_badge)
		cv.add_child(top)

		var sum_lbl := Label.new()
		sum_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		sum_lbl.text = str(up["summary"])
		sum_lbl.add_theme_font_size_override("font_size", 11)
		sum_lbl.add_theme_color_override("font_color", Color(0.78, 0.85, 0.92))
		sum_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cv.add_child(sum_lbl)

		var cur_eff := str(labels[rk]) if rk < labels.size() else "Attivo"
		var eff_lbl := Label.new()
		eff_lbl.add_theme_font_size_override("font_size", 11)
		eff_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if rk < max_rk and (rk + 1) < labels.size():
			eff_lbl.text = "Attuale: %s  ➔  Prossimo: %s" % [cur_eff, str(labels[rk + 1])]
			eff_lbl.add_theme_color_override("font_color", Color(0.60, 0.95, 0.72))
		else:
			eff_lbl.text = "Attuale: %s (Livello Massimo)" % cur_eff
			eff_lbl.add_theme_color_override("font_color", Color(0.38, 1.0, 0.62))
		cv.add_child(eff_lbl)

		var act_btn := Button.new()
		act_btn.custom_minimum_size = Vector2(0, 32)
		act_btn.focus_mode = Control.FOCUS_NONE
		if rk >= max_rk:
			act_btn.text = "✔ POTENZIAMENTO AL MASSIMO (Lv.3/3)"
			act_btn.disabled = true
		else:
			act_btn.text = "★ Sblocca Livello %d/%d — Costo: %d ★" % [rk + 1, max_rk, next_cost]
			act_btn.disabled = not can_buy
			if can_buy:
				act_btn.add_theme_color_override("font_color", Color(1.0, 0.88, 0.30))
			var uid_copy := uid
			act_btn.pressed.connect(func():
				if UpgradeManager.purchase(uid_copy):
					_update_upgrades_display()
					_update_top_bar()
					_refresh_desktop_badges()
			)
		cv.add_child(act_btn)
		upgrades_grid.add_child(card)

# ==============================================================================
# CONOSCENZA R&D UI (SBLOCCATA DOPO OFFICINA BELLINI)
# ==============================================================================
func _update_knowledge_display() -> void:
	if not knowledge_window or not knowledge_grid or not is_instance_valid(KnowledgeManager):
		return
	for ch in knowledge_grid.get_children():
		ch.queue_free()
	if knowledge_banner_actions:
		for ch in knowledge_banner_actions.get_children():
			ch.queue_free()

	var unlocked := KnowledgeManager.is_unlocked()
	var fac := ContractManager.get_factory_progress_summary()
	var tracks := KnowledgeManager.get_all_tracks()
	var tot_rk := KnowledgeManager.get_total_rank()
	var max_tot := tracks.size() * KnowledgeManager.MAX_RANK

	var rc_avail := TechOpsManager.research_credits if is_instance_valid(TechOpsManager) else 0
	var tech_rk := TechOpsManager.get_total_tech_rank() if is_instance_valid(TechOpsManager) else 0
	if knowledge_banner_label:
		if not unlocked:
			knowledge_banner_label.text = "🔒 RICERCA R&D BLOCCATA — Completa prima il Maxi-Appalto Officina Bellini (Borgo Valdocco Est: Sopralluogo %d/4, Wi-Fi %s, Web %s, Server %s, PC %s)." % [
				int(fac.get("scouted_count", 0)),
				"✔" if bool(fac.get("wifi_done", false)) else "○",
				"✔" if bool(fac.get("web_done", false)) else "○",
				"✔" if bool(fac.get("server_done", false)) else "○",
				"✔" if bool(fac.get("pcs_done", false)) else "○"
			]
		else:
			knowledge_banner_label.text = "📘 RICERCA & SVILUPPO TECNOLOGICO — Conoscenza: %d/%d · Tech Tree: %d/18 · 🔬 Crediti Ricerca: %d RC · Fondi: € %0.2f — Sblocca tecnologie per Mining Robot, TO-Drone MK1, AI e Cloud." % [
				tot_rk, max_tot, tech_rk, rc_avail, EconomyManager.balance
			]

	if knowledge_banner_actions:
		var hub_btn := Button.new()
		hub_btn.text = "💼 Apri Freelance Hub"
		hub_btn.focus_mode = Control.FOCUS_NONE
		hub_btn.pressed.connect(func(): _open_window(freelance_window))
		knowledge_banner_actions.add_child(hub_btn)
		if unlocked:
			var wf_btn := Button.new()
			wf_btn.text = "⚡ Apri WebForge"
			wf_btn.focus_mode = Control.FOCUS_NONE
			wf_btn.pressed.connect(_launch_webforge)
			knowledge_banner_actions.add_child(wf_btn)
			var ogr_btn := Button.new()
			ogr_btn.text = "🏢 Apri OGR & Tech Ops"
			ogr_btn.focus_mode = Control.FOCUS_NONE
			ogr_btn.pressed.connect(func(): _open_window(ogr_window))
			knowledge_banner_actions.add_child(ogr_btn)

	for tr in tracks:
		var tid := str(tr["id"])
		var rk := int(tr["rank"])
		var max_rk := int(tr["max_rank"])
		var next_cost := float(tr["next_cost"])
		var next_rep := int(tr["next_rep_req"])
		var can_study := bool(tr["can_study"])
		var block_reason := str(tr.get("block_reason", ""))
		var labels: Array = tr.get("effect_labels", [])

		var border_col := Color(0.45, 0.52, 0.62, 0.50) if not unlocked else (Color(0.35, 1.0, 0.58, 0.78) if rk >= max_rk else (Color(0.42, 0.90, 1.0, 0.88) if can_study else Color(0.32, 0.50, 0.72, 0.65)))
		var card := _make_hub_card(Color(0.11, 0.16, 0.24, 0.94), border_col)
		card.custom_minimum_size = Vector2(220, 152)

		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 5)
		card.add_child(cv)

		var top := HBoxContainer.new()
		var t_lbl := Label.new()
		t_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		t_lbl.text = "%s %s" % [str(tr["icon"]), str(tr["title"])]
		t_lbl.add_theme_font_size_override("font_size", 14)
		t_lbl.add_theme_color_override("font_color", Color(0.55, 0.92, 1.0) if unlocked else Color(0.68, 0.75, 0.84))
		t_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		top.add_child(t_lbl)

		var rk_badge := Label.new()
		rk_badge.text = "Lv.%d/%d" % [rk, max_rk] if unlocked else "🔒 Lv.0/3"
		rk_badge.add_theme_font_size_override("font_size", 12)
		rk_badge.add_theme_color_override("font_color", Color(0.42, 0.94, 1.0) if unlocked else Color(1.0, 0.72, 0.35))
		top.add_child(rk_badge)
		cv.add_child(top)

		var sum_lbl := Label.new()
		sum_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		sum_lbl.text = str(tr["summary"])
		sum_lbl.add_theme_font_size_override("font_size", 11)
		sum_lbl.add_theme_color_override("font_color", Color(0.78, 0.85, 0.92))
		sum_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cv.add_child(sum_lbl)

		var cur_eff := str(labels[rk]) if rk < labels.size() else "Attivo"
		var eff_lbl := Label.new()
		eff_lbl.add_theme_font_size_override("font_size", 11)
		eff_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if not unlocked:
			eff_lbl.text = "Sblocco al completamento di Officina Bellini (Borgo Valdocco)"
			eff_lbl.add_theme_color_override("font_color", Color(1.0, 0.78, 0.42))
		elif rk < max_rk and (rk + 1) < labels.size():
			eff_lbl.text = "Attuale: %s  ➔  Prossimo: %s" % [cur_eff, str(labels[rk + 1])]
			eff_lbl.add_theme_color_override("font_color", Color(0.60, 0.95, 0.72))
		else:
			eff_lbl.text = "Attuale: %s (Padronanza Massima)" % cur_eff
			eff_lbl.add_theme_color_override("font_color", Color(0.38, 1.0, 0.62))
		cv.add_child(eff_lbl)

		var act_btn := Button.new()
		act_btn.custom_minimum_size = Vector2(0, 32)
		act_btn.focus_mode = Control.FOCUS_NONE
		act_btn.clip_text = true
		if not unlocked:
			act_btn.text = "🔒 Richiede Officina Bellini Completata"
			act_btn.disabled = true
		elif rk >= max_rk:
			act_btn.text = "✔ RICERCA AL MASSIMO (Lv.3/3)"
			act_btn.disabled = true
		else:
			if can_study:
				act_btn.text = "📘 Studia Lv.%d/%d — € %0.0f · %d Rep" % [rk + 1, max_rk, next_cost, next_rep]
				act_btn.add_theme_color_override("font_color", Color(0.42, 0.96, 1.0))
			else:
				act_btn.text = "📘 € %0.0f · %d Rep (%s)" % [next_cost, next_rep, "Rep insuff." if GameManager.reputation_points < next_rep else "Fondi insuff."]
				act_btn.tooltip_text = block_reason
			act_btn.disabled = not can_study
			var tid_copy := tid
			act_btn.pressed.connect(func():
				if KnowledgeManager.study(tid_copy):
					_update_knowledge_display()
					_update_freelance_display()
					_update_top_bar()
					_refresh_desktop_badges()
			)
		cv.add_child(act_btn)
		knowledge_grid.add_child(card)

	# Rami Tecnologici Post-OGR (6 Rami sbloccabili con 🔬 Crediti di Ricerca + €)
	if is_instance_valid(TechOpsManager):
		var tech_branches: Array = TechOpsManager.get_all_tech_branches()
		var ogr_open: bool = ContractManager.is_ogr_unlocked() or bool(TechOpsManager.ogr_tech_mission_started)
		for tb in tech_branches:
			var bid := str(tb["id"])
			var rk := int(tb["rank"])
			var max_rk := int(tb["max_rank"])
			var rc_cost := int(tb["next_rc_cost"])
			var euro_cost := float(tb["next_euro_cost"])
			var can_res := bool(tb["can_research"])
			var labels: Array = tb.get("effect_labels", [])

			var b_col := Color(0.45, 0.52, 0.62, 0.50) if not ogr_open else (Color(0.35, 1.0, 0.58, 0.78) if rk >= max_rk else (Color(1.0, 0.84, 0.32, 0.90) if can_res else Color(0.38, 0.55, 0.78, 0.65)))
			var card := _make_hub_card(Color(0.12, 0.15, 0.23, 0.95), b_col)
			card.custom_minimum_size = Vector2(220, 152)

			var cv := VBoxContainer.new()
			cv.add_theme_constant_override("separation", 5)
			card.add_child(cv)

			var top := HBoxContainer.new()
			var t_lbl := Label.new()
			t_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			t_lbl.text = "%s %s" % [str(tb["icon"]), str(tb["title"])]
			t_lbl.add_theme_font_size_override("font_size", 14)
			t_lbl.add_theme_color_override("font_color", Color(1.0, 0.86, 0.38) if ogr_open else Color(0.68, 0.75, 0.84))
			t_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			top.add_child(t_lbl)

			var rk_badge := Label.new()
			rk_badge.text = "🔬 Lv.%d/%d" % [rk, max_rk]
			rk_badge.add_theme_font_size_override("font_size", 12)
			rk_badge.add_theme_color_override("font_color", Color(1.0, 0.86, 0.35))
			top.add_child(rk_badge)
			cv.add_child(top)

			var sum_lbl := Label.new()
			sum_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
			sum_lbl.text = str(tb["summary"])
			sum_lbl.add_theme_font_size_override("font_size", 11)
			sum_lbl.add_theme_color_override("font_color", Color(0.80, 0.86, 0.94))
			sum_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			cv.add_child(sum_lbl)

			var cur_eff := str(labels[rk]) if rk < labels.size() else "Attivo"
			var eff_lbl := Label.new()
			eff_lbl.add_theme_font_size_override("font_size", 11)
			eff_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			if rk < max_rk and (rk + 1) < labels.size():
				eff_lbl.text = "Attuale: %s  ➔  Prossimo: %s" % [cur_eff, str(labels[rk + 1])]
				eff_lbl.add_theme_color_override("font_color", Color(0.65, 0.96, 0.75))
			else:
				eff_lbl.text = "Attuale: %s (Livello Massimo)" % cur_eff
				eff_lbl.add_theme_color_override("font_color", Color(0.38, 1.0, 0.62))
			cv.add_child(eff_lbl)

			var act_btn := Button.new()
			act_btn.custom_minimum_size = Vector2(0, 32)
			act_btn.focus_mode = Control.FOCUS_NONE
			act_btn.clip_text = true
			if rk >= max_rk:
				act_btn.text = "✔ TECNOLOGIA AL MASSIMO (Lv.3/3)"
				act_btn.disabled = true
			else:
				act_btn.text = ("🔬 Sblocca Lv.%d/%d — %d RC" % [rk + 1, max_rk, rc_cost]) if euro_cost <= 0.0 else ("🔬 Sblocca Lv.%d/%d — %d RC + € %0.0f" % [rk + 1, max_rk, rc_cost, euro_cost])
				act_btn.disabled = not can_res
				if can_res:
					act_btn.add_theme_color_override("font_color", Color(1.0, 0.88, 0.32))
				var bid_copy := bid
				act_btn.pressed.connect(func():
					if TechOpsManager.research_branch(bid_copy):
						_update_knowledge_display()
						_update_ogr_display()
						_update_top_bar()
						_refresh_desktop_badges()
				)
			cv.add_child(act_btn)
			knowledge_grid.add_child(card)


# ==============================================================================
# OGR ENTERPRISE UI
# ==============================================================================
func _update_ogr_display() -> void:
	if not ogr_window or not ogr_content_vbox:
		return
	for ch in ogr_content_vbox.get_children():
		ch.queue_free()
	if ogr_banner_actions:
		for ch in ogr_banner_actions.get_children():
			ch.queue_free()

	var unlocked := ContractManager.is_ogr_unlocked()
	if not unlocked:
		if ogr_banner_label:
			ogr_banner_label.text = "🔒 ACCESSO OGR TECH HUB TORINO BLOCCATO — Completa le 4 missioni iniziali di San Carlo & Valdocco per aprire i cancelli OGR di Mercato Est."
		if ogr_banner_actions:
			var go_hub := Button.new()
			go_hub.text = "💼 Apri Freelance Hub"
			go_hub.pressed.connect(func(): _open_window(freelance_window))
			ogr_banner_actions.add_child(go_hub)

		var chk_card := _make_hub_card(Color(0.14, 0.16, 0.23, 0.92), Color(1.0, 0.58, 0.32, 0.75))
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 6)
		chk_card.add_child(cv)

		var hdr := Label.new()
		hdr.text = "REQUISITI SBLOCCO CANCELLI OGR (ING. ANDREA VIALE):"
		hdr.add_theme_font_size_override("font_size", 13)
		hdr.add_theme_color_override("font_color", Color(1.0, 0.80, 0.40))
		hdr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cv.add_child(hdr)

		var steps := [
			["Pizzeria Da Mario (Via Po 18)", ContractManager.is_contract_completed("pizzeria_da_mario")],
			["Caffè San Carlo — Touch Web POS", ContractManager.is_contract_completed("caffe_san_carlo")],
			["Elettronica TO — Migrazione Cloud", ContractManager.is_contract_completed("elettronica_to")],
			["Maxi-Appalto Officina Bellini (4 Zone + 4 Pilastri)", ContractManager.is_contract_completed("factory_bellini") or bool(ContractManager.factory_state.get("completed", false))]
		]
		for st in steps:
			var done := bool(st[1])
			var line := Label.new()
			line.text = "%s %s" % ["✔" if done else "○", str(st[0])]
			line.add_theme_font_size_override("font_size", 12)
			line.add_theme_color_override("font_color", Color(0.42, 1.0, 0.62) if done else Color(0.86, 0.88, 0.94))
			line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			cv.add_child(line)
		ogr_content_vbox.add_child(chk_card)
		return

	if ContractManager.enterprise_contracts.is_empty():
		ContractManager.refresh_enterprise_contracts(true)

	var ent_tier := UpgradeManager.get_enterprise_tier() if is_instance_valid(UpgradeManager) else 1
	var ent_bonus_pct := roundi((UpgradeManager.get_enterprise_payout_mult() - 1.0) * 100.0) if is_instance_valid(UpgradeManager) else 0
	var rc_now: int = int(TechOpsManager.research_credits) if is_instance_valid(TechOpsManager) else 0
	if ogr_banner_label:
		ogr_banner_label.text = "🏢 OGR TECH HUB & POLO TECNOLOGICO — Appalti Tier %d/4 (+%d%%) · 🔬 %d RC · Magazzino: %d mat. · Dipartimenti: +€ %0.0f/g" % [
			ent_tier, ent_bonus_pct, rc_now,
			int(TechOpsManager.get_stored_total()) if is_instance_valid(TechOpsManager) else 0,
			float(TechOpsManager.calculate_departments_daily_revenue()) if is_instance_valid(TechOpsManager) else 0.0
		]

	if ogr_banner_actions:
		var ref_btn := Button.new()
		ref_btn.text = "↻ Aggiorna Bandi"
		ref_btn.pressed.connect(func():
			ContractManager.refresh_enterprise_contracts(true)
			_update_ogr_display()
		)
		ogr_banner_actions.add_child(ref_btn)
		var rd_btn := Button.new()
		rd_btn.text = "🔬 Albero Ricerca (%d RC)" % rc_now
		rd_btn.add_theme_color_override("font_color", Color(0.45, 0.95, 1.0))
		rd_btn.pressed.connect(func(): _open_window(knowledge_window))
		ogr_banner_actions.add_child(rd_btn)
		if ent_tier < 4:
			var up_btn := Button.new()
			up_btn.text = "★ Potenzia Appalti OGR (Attuale Tier %d)" % ent_tier
			up_btn.add_theme_color_override("font_color", Color(1.0, 0.86, 0.35))
			up_btn.pressed.connect(func(): _open_window(upgrades_window))
			ogr_banner_actions.add_child(up_btn)

	if is_instance_valid(TechOpsManager):
		_append_ogr_tech_ops_cards()

	# Contratti Enterprise attivi

	var active_ent: Array[Dictionary] = []
	for cid in ContractManager.active_contracts:
		var c = ContractManager.active_contracts[cid]
		if c is Dictionary and bool(c.get("is_enterprise", false)) and str(c.get("status", "")) != "completed":
			active_ent.append(c)

	if not active_ent.is_empty():
		var ah := Label.new()
		ah.text = "🔧 APPALTI CORPORATE IN LAVORAZIONE:"
		ah.add_theme_font_size_override("font_size", 13)
		ah.add_theme_color_override("font_color", Color(0.45, 0.94, 1.0))
		ogr_content_vbox.add_child(ah)

		for c in active_ent:
			var cid := str(c["id"])
			var st := str(c.get("status", "in_progress"))
			var etype := str(c.get("execution_type", "webforge"))
			var card := _make_hub_card(Color(0.12, 0.19, 0.28, 0.94), Color(0.35, 0.85, 1.0, 0.85))
			var v := VBoxContainer.new()
			v.add_theme_constant_override("separation", 6)
			card.add_child(v)

			var rd_pct := roundi((KnowledgeManager.get_contract_payout_mult(c) - 1.0) * 100.0) if is_instance_valid(KnowledgeManager) else 0
			var rd_note := " · +%d%% R&D 📘" % rd_pct if rd_pct > 0 else ""

			var ttl := Label.new()
			ttl.text = "[TIER %d] %s — %s (€ %0.2f · +%d★%s)" % [
				int(c.get("tier", 1)), str(c.get("title", cid)), str(c.get("client", "")), float(c.get("budget", 0.0)), int(c.get("star_reward", 3)), rd_note
			]
			ttl.add_theme_font_size_override("font_size", 13)
			ttl.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0))
			ttl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			v.add_child(ttl)

			var req := Label.new()
			req.text = "%s | Requisiti: %s" % [str(c.get("category", "Enterprise")), ", ".join(c.get("requirements", []))]
			req.add_theme_font_size_override("font_size", 11)
			req.add_theme_color_override("font_color", Color(0.75, 0.84, 0.92))
			req.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			v.add_child(req)

			var row := HFlowContainer.new()
			row.add_theme_constant_override("h_separation", 8)
			row.add_theme_constant_override("v_separation", 6)
			if st == "built":
				var d_btn := Button.new()
				d_btn.text = "★ Consegna & Incassa (€ %0.2f)" % float(c.get("budget", 0.0))
				d_btn.add_theme_color_override("font_color", Color(0.35, 1.0, 0.58))
				d_btn.pressed.connect(func(): _complete_contract_by_id(cid))
				row.add_child(d_btn)
			elif etype == "netshield":
				var ns_btn := Button.new()
				ns_btn.text = "🛡 Configura su NetShield Cyber"
				ns_btn.add_theme_color_override("font_color", Color(1.0, 0.72, 0.30))
				ns_btn.pressed.connect(func(): _launch_netshield_for(cid))
				row.add_child(ns_btn)
			elif etype == "hardware":
				var req_hw: Dictionary = c.get("required_hardware", {})
				var all_ok := true
				var parts: Array[String] = []
				for hw_id in req_hw:
					var need := int(req_hw[hw_id])
					var have := ShopManager.get_hardware_count(str(hw_id))
					if have < need:
						all_ok = false
					parts.append("%s: %d/%d" % [ShopManager.get_hardware_item_name(str(hw_id)), have, need])
				var hw_lbl := Label.new()
				hw_lbl.custom_minimum_size = Vector2(210, 0)
				hw_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				hw_lbl.text = "Stock: " + ", ".join(parts)
				hw_lbl.add_theme_font_size_override("font_size", 11)
				hw_lbl.add_theme_color_override("font_color", Color(0.45, 1.0, 0.65) if all_ok else Color(1.0, 0.78, 0.35))
				hw_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				row.add_child(hw_lbl)

				var hw_btn := Button.new()
				hw_btn.text = "📦 Installa & Consegna" if all_ok else "🛒 Ordina su TorinoHardware"
				if all_ok:
					hw_btn.add_theme_color_override("font_color", Color(0.35, 1.0, 0.55))
					hw_btn.pressed.connect(func():
						ContractManager.deliver_hardware_contract(cid)
						_update_ogr_display()
					)
				else:
					hw_btn.pressed.connect(func(): _open_window(shop_window))
				row.add_child(hw_btn)
			else:
				var wf_btn := Button.new()
				wf_btn.text = "⚡ Sviluppa su WebForge"
				wf_btn.add_theme_color_override("font_color", Color(0.40, 0.92, 1.0))
				wf_btn.pressed.connect(func(): _launch_webforge_for(cid))
				row.add_child(wf_btn)

			var cancel_btn := Button.new()
			cancel_btn.text = "✕ Annulla Bando"
			cancel_btn.add_theme_color_override("font_color", Color(1.0, 0.52, 0.52))
			cancel_btn.pressed.connect(func():
				ContractManager.cancel_active_contract(cid)
				_update_ogr_display()
			)
			row.add_child(cancel_btn)
			v.add_child(row)
			ogr_content_vbox.add_child(card)

	# Bandi OGR Disponibili
	var th := Label.new()
	th.text = "🏛 BANDI DISPONIBILI IN SALA OGR (%d):" % ContractManager.enterprise_contracts.size()
	th.add_theme_font_size_override("font_size", 13)
	th.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	ogr_content_vbox.add_child(th)

	for c in ContractManager.enterprise_contracts:
		var cid := str(c["id"])
		var tier_n := int(c.get("tier", 1))
		var etype := str(c.get("execution_type", "webforge"))
		var rd_pct := roundi((KnowledgeManager.get_contract_payout_mult(c) - 1.0) * 100.0) if is_instance_valid(KnowledgeManager) else 0
		var card := _make_hub_card(Color(0.13, 0.17, 0.25, 0.92), Color(0.38, 0.72, 0.95, 0.65))
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 5)
		card.add_child(v)

		var row := HFlowContainer.new()
		row.add_theme_constant_override("h_separation", 8)
		row.add_theme_constant_override("v_separation", 6)

		var tl := Label.new()
		tl.custom_minimum_size = Vector2(220, 0)
		tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tl.text = "[TIER %d · %s%s] %s — %s" % [tier_n, etype.to_upper(), " · 📘 R&D" if rd_pct > 0 else "", str(c["title"]), str(c["client"])]
		tl.add_theme_font_size_override("font_size", 13)
		tl.add_theme_color_override("font_color", Color(0.55, 0.94, 1.0))
		tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(tl)

		var acc_btn := Button.new()
		acc_btn.custom_minimum_size = Vector2(150, 32)
		acc_btn.text = "✓ Accetta (€ %0.0f)" % float(c["budget"])
		acc_btn.add_theme_color_override("font_color", Color(0.35, 1.0, 0.58))
		acc_btn.pressed.connect(func():
			SoundManager.play_ui_click()
			ContractManager.accept_enterprise_contract(cid)
			_update_ogr_display()
		)
		row.add_child(acc_btn)
		v.add_child(row)

		var ml := Label.new()
		var rd_txt := " · +%d%% Conoscenza" % rd_pct if rd_pct > 0 else ""
		ml.text = "Premio: € %0.2f (+%d★ · +%d Rep%s) | %s\nRequisiti: %s" % [
			float(c["budget"]), int(c.get("star_reward", 3)), int(c.get("reputation_reward", 40)), rd_txt,
			str(c.get("category", "Enterprise")), ", ".join(c.get("requirements", []))
		]
		ml.add_theme_font_size_override("font_size", 11)
		ml.add_theme_color_override("font_color", Color(0.78, 0.85, 0.92))
		ml.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(ml)
		ogr_content_vbox.add_child(card)


func _append_ogr_tech_ops_cards() -> void:
	# 1. Imprevisti Attivi (se presenti)
	if not TechOpsManager.active_incidents.is_empty():
		var inc_card := _make_hub_card(Color(0.24, 0.12, 0.14, 0.95), Color(1.0, 0.38, 0.35, 0.90))
		var iv := VBoxContainer.new()
		iv.add_theme_constant_override("separation", 6)
		inc_card.add_child(iv)

		var ih := Label.new()
		ih.text = "⚠ IMPREVISTI & CRITICITÀ AZIENDALI ATTIVE (%d):" % TechOpsManager.active_incidents.size()
		ih.add_theme_font_size_override("font_size", 13)
		ih.add_theme_color_override("font_color", Color(1.0, 0.55, 0.45))
		ih.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		iv.add_child(ih)

		for inc_id in TechOpsManager.active_incidents.keys():
			var inc: Dictionary = TechOpsManager.active_incidents[inc_id]
			var irow := HFlowContainer.new()
			irow.add_theme_constant_override("h_separation", 8)
			irow.add_theme_constant_override("v_separation", 4)
			var ilbl := Label.new()
			ilbl.custom_minimum_size = Vector2(220, 0)
			ilbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			ilbl.text = "• %s: %s" % [str(inc.get("title", inc_id)), str(inc.get("desc", ""))]
			ilbl.add_theme_font_size_override("font_size", 11)
			ilbl.add_theme_color_override("font_color", Color(0.96, 0.86, 0.84))
			ilbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			irow.add_child(ilbl)

			var ibtn := Button.new()
			var rcost := float(inc.get("fix_cost_eur", 60.0))
			ibtn.text = "🔧 Risolvi Ora (Gratis)" if rcost <= 0.0 else ("🔧 Risolvi da Remoto (€ %0.0f)" % rcost)
			ibtn.disabled = (rcost > 0.0 and not EconomyManager.can_afford(rcost))
			var id_copy := str(inc_id)
			ibtn.pressed.connect(func():
				if TechOpsManager.resolve_incident(id_copy, false):
					_update_ogr_display()
					_update_top_bar()
			)
			irow.add_child(ibtn)
			iv.add_child(irow)
		ogr_content_vbox.add_child(inc_card)

	# 2. Polo Materiali, Mining Robot & Progetto TO-Drone MK1
	var ops_card := _make_hub_card(Color(0.11, 0.17, 0.25, 0.94), Color(0.38, 0.88, 0.95, 0.80))
	var ov := VBoxContainer.new()
	ov.add_theme_constant_override("separation", 6)
	ops_card.add_child(ov)

	var oh := Label.new()
	oh.text = "🔬 POLO TECNOLOGICO OGR — MATERIALI, MINING ROBOT & PROGETTO DRONE MK1"
	oh.add_theme_font_size_override("font_size", 13)
	oh.add_theme_color_override("font_color", Color(0.48, 0.95, 1.0))
	oh.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ov.add_child(oh)

	var mat_lbl := Label.new()
	mat_lbl.text = "📦 Magazzino Materiali: Rame x%d · Silicio x%d · Alluminio x%d · Circuiti x%d · Terre Rare x%d · Compositi x%d" % [
		int(TechOpsManager.get_stored_count("copper")),
		int(TechOpsManager.get_stored_count("silicon")),
		int(TechOpsManager.get_stored_count("aluminum")),
		int(TechOpsManager.get_stored_count("circuits")),
		int(TechOpsManager.get_stored_count("rare_earths")),
		int(TechOpsManager.get_stored_count("composites"))
	]
	mat_lbl.add_theme_font_size_override("font_size", 11)
	mat_lbl.add_theme_color_override("font_color", Color(0.84, 0.90, 0.96))
	mat_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ov.add_child(mat_lbl)

	var r1_txt := "Da installare alla Miniera Alpina"
	if TechOpsManager.is_robot_built(1):
		var st1 := TechOpsManager.get_robot_state(1)
		r1_txt = "Attivo Lv.%d (Cond. %d%% · Cassa %d/%d)" % [
			int(st1.get("level", 1)),
			int(roundf(float(st1.get("condition", 100.0)))),
			int(TechOpsManager.get_robot_hopper_total(1)),
			int(st1.get("hopper_cap", 18))
		]
	var r2_txt := "Non installato"
	if TechOpsManager.is_robot_built(2):
		var st2 := TechOpsManager.get_robot_state(2)
		r2_txt = "Attivo Lv.%d (Cond. %d%% · Cassa %d/%d%s)" % [
			int(st2.get("level", 1)),
			int(roundf(float(st2.get("condition", 100.0)))),
			int(TechOpsManager.get_robot_hopper_total(2)),
			int(st2.get("hopper_cap", 32)),
			" · Nastro ON" if TechOpsManager.conveyor_installed else ""
		]
	var dr_txt := "Assemblaggio: %d/7 step al Lab Droni (Borgo Po)" % int(TechOpsManager.drone_assembly_step)
	if TechOpsManager.drone_built:
		if not TechOpsManager.active_drone_mission.is_empty():
			dr_txt = "IN VOLO: %s (%d min)" % [
				str(TechOpsManager.active_drone_mission.get("title", "Missione")),
				int(TechOpsManager.active_drone_mission.get("remaining_mins", 0))
			]
		else:
			dr_txt = "OPERATIVO ✔ (Missioni completate: %d)" % int(TechOpsManager.completed_drone_missions_count)

	var st_lbl := Label.new()
	st_lbl.text = "🤖 Mining Robot MK1: %s  |  MK2: %s  |  🚁 TO-Drone MK1: %s" % [r1_txt, r2_txt, dr_txt]
	st_lbl.add_theme_font_size_override("font_size", 11)
	st_lbl.add_theme_color_override("font_color", Color(0.55, 0.96, 0.72))
	st_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ov.add_child(st_lbl)

	var act_row := HFlowContainer.new()
	act_row.add_theme_constant_override("h_separation", 8)
	act_row.add_theme_constant_override("v_separation", 6)

	if TechOpsManager.drone_built:
		var in_flight := not TechOpsManager.active_drone_mission.is_empty()
		for mid in TechOpsManager.DRONE_MISSION_ORDER:
			var mdef: Dictionary = TechOpsManager.DRONE_MISSIONS[mid]
			var mbtn := Button.new()
			if in_flight:
				mbtn.text = "🚁 %s (Drone in volo)" % str(mdef["title"])
				mbtn.disabled = true
			else:
				mbtn.text = "🚁 %s (+€ %0.0f · +%d RC)" % [str(mdef["title"]), float(mdef["reward_eur"]), int(mdef["reward_rc"])]
				mbtn.add_theme_color_override("font_color", Color(0.40, 1.0, 0.65))
				var mid_copy: String = str(mid)
				mbtn.pressed.connect(func():
					if TechOpsManager.start_drone_mission(mid_copy):
						_update_ogr_display()
						_update_top_bar()
				)
			act_row.add_child(mbtn)

	if act_row.get_child_count() > 0:
		ov.add_child(act_row)
	ogr_content_vbox.add_child(ops_card)

	# 3. Fase 4: Dipartimenti Aziendali & Investimenti (Incubatore Startup Torino)
	var dept_card := _make_hub_card(Color(0.13, 0.15, 0.24, 0.94), Color(0.85, 0.72, 1.0, 0.75))
	var dv := VBoxContainer.new()
	dv.add_theme_constant_override("separation", 6)
	dept_card.add_child(dv)

	var dh := Label.new()
	dh.text = "🏛 FASE 4 — DIPARTIMENTI DIREZIONALI & CEO (%d/3 · +€ %0.0f/g · +%d RC/g · INCUBATORE)" % [
		TechOpsManager.unlocked_departments.size(),
		TechOpsManager.calculate_departments_daily_revenue(),
		TechOpsManager.calculate_departments_daily_rc()
	]
	dh.add_theme_font_size_override("font_size", 13)
	dh.add_theme_color_override("font_color", Color(0.86, 0.75, 1.0))
	dh.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dv.add_child(dh)

	var d_flow := HFlowContainer.new()
	d_flow.add_theme_constant_override("h_separation", 8)
	d_flow.add_theme_constant_override("v_separation", 6)
	for did in TechOpsManager.DEPT_ORDER:
		var def: Dictionary = TechOpsManager.DEPARTMENTS[did]
		var is_open := TechOpsManager.is_department_unlocked(did)
		var chk: Dictionary = TechOpsManager.can_unlock_department(did)
		var dbtn := Button.new()
		dbtn.focus_mode = Control.FOCUS_NONE
		if is_open:
			dbtn.text = "✔ %s (+€ %0.0f/g · +%d RC/g)" % [str(def["title"]), float(def["daily_eur"]), int(def["daily_rc"])]
			dbtn.disabled = true
		else:
			var c_euro := float(def.get("cost_eur", 2400.0))
			var c_rc := int(def.get("cost_rc", 30))
			dbtn.text = "🏛 Fonda %s (€ %0.0f · %d RC)" % [str(def["title"]), c_euro, c_rc]
			dbtn.disabled = not bool(chk.get("allowed", false))
			if bool(chk.get("allowed", false)):
				dbtn.add_theme_color_override("font_color", Color(0.85, 0.75, 1.0))
			else:
				dbtn.tooltip_text = str(chk.get("reason", ""))
			var did_copy: String = str(did)
			dbtn.pressed.connect(func():
				if TechOpsManager.unlock_department(did_copy):
					_update_ogr_display()
					_update_top_bar()
			)
		d_flow.add_child(dbtn)
	dv.add_child(d_flow)
	ogr_content_vbox.add_child(dept_card)


# ==============================================================================
# MAIL, FREELANCE HUB, SHOP, BANK
# ==============================================================================
func _setup_emails() -> void:
	mail_list.clear()
	emails.clear()
	_selected_email_cid = ""

	emails.append({
		"from": "Mario Esposito <mario@pizzeriadamario-to.it>",
		"subject": "Richiesta Realizzazione Sito Web - Pizzeria Da Mario (Via Po)",
		"body": "Gentile Dottore,\n\nHo visto il suo annuncio su Freelance Hub Torino. Cerchiamo qualcuno che crei il nostro sito web ufficiale per attirare turisti e clienti a Torino.\n\nBudget concordato: € 260,00 netti (+ eventuale mancia qualità).\n\nPassi a trovarmi direttamente di persona in bottega in Via Po 18 (esca dal suo studio e segua la via fino all'insegna luminosa).\n\nMario Esposito - Titolare",
		"contract_id": "pizzeria_da_mario"
	})

	if ContractManager.is_contract_completed("pizzeria_da_mario") or ContractManager.active_contracts.has("caffe_san_carlo"):
		emails.append({
			"from": "Elena Rossi <elena@caffesancarlo.to.it>",
			"subject": "Richiesta Touch Web POS Cassa & Ordini - Caffè San Carlo",
			"body": "Gentile Sviluppatore,\n\nMario mi ha mostrato il nuovo sito web e ne sono rimasta affascinata!\nQui al Caffè San Carlo abbiamo code al bancone nelle ore di punta. Ci serve un sistema Web POS moderno per velocizzare le ordinazioni di caffè e bicerin.\n\nBudget: € 540,00 netti + Hosting mensile sul suo server rack!\nPassi al bancone del Caffè in Piazzetta per definire i dettagli.\n\nCordiali saluti,\nElena - Store Manager",
			"contract_id": "caffe_san_carlo"
		})

	if ContractManager.is_contract_completed("caffe_san_carlo") or ContractManager.active_contracts.has("elettronica_to"):
		emails.append({
			"from": "Davide Ferrero <davide@elettronicato.com>",
			"subject": "Proposta Migrazione Cloud & Catalogo - Elettronica TO",
			"body": "Ciao collega,\n\nHo saputo del Web POS installato al Caffè San Carlo, lavoro eccellente!\nDa Elettronica TO dobbiamo dismettere il nostro vecchio server locale e migrare a un'architettura cloud con database ridondato e backup sul tuo server rack.\n\nBudget stanziato: € 860,00 netti + 20% di sconto permanente sui componenti hardware (Router Wi-Fi, Server Xeon, PC & Firewall)!\nVieni in negozio in Piazzetta per iniziare.\n\nA presto,\nDavide - Tecnico Elettronica TO",
			"contract_id": "elettronica_to"
		})

	for cid in ContractManager.active_contracts:
		if cid in ["pizzeria_da_mario", "caffe_san_carlo", "elettronica_to"]:
			continue
		var ac = ContractManager.active_contracts[cid]
		if ac is Dictionary and ac.get("execution_type", "webforge") == "webforge":
			var st = ac.get("status", "")
			if st == "in_progress" or st == "built":
				emails.append({
					"from": "%s <b2b@torino-clienti.it>" % str(ac.get("client", "Cliente B2B")),
					"subject": "%s%s (€ %0.2f)" % ["[PRONTA CONSEGNA] " if st == "built" else "[ATTIVO] ", str(ac.get("title", cid)), float(ac.get("budget", 0.0))],
					"body": "Commissione B2B attiva: %s\n\n%s\n\nCompenso base: € %0.2f\nStato attuale: %s\nRequisiti: %s" % [
						str(ac.get("title", cid)),
						str(ac.get("brief", ac.get("objective_text", ""))),
						float(ac.get("budget", 0.0)),
						st.to_upper(),
						", ".join(ac.get("requirements", []))
					],
					"contract_id": cid
				})

	emails.append({
		"from": "Risorse Umane <recruiting@megacorp-consulting.it>",
		"subject": "Esito candidatura Posizione Junior Software Engineer",
		"body": "Gentile Candidato,\n\nLa ringraziamo per aver inviato il suo CV. Pur apprezzando il suo brillante percorso di laurea con 110 e lode al Politecnico, cerchiamo per questo stage (rimborso mensile: 400€ lordi) un profilo con almeno 8 anni di esperienza pregressa in cloud computing e intelligenza artificiale quantistica.\n\nLe auguriamo il meglio per il suo futuro.",
		"contract_id": ""
	})

	emails.append({
		"from": "Segreteria Studenti <laurea@unito.it>",
		"subject": "Certificato Ufficiale di Laurea in Informatica",
		"body": "Gentile Dottore,\n\nIl suo certificato ufficiale di Laurea Magistrale in Informatica (110 e Lode) è pronto. Può ammirarlo appeso alla parete del suo studio.\n\nCongratulazioni per il traguardo raggiunto!",
		"contract_id": ""
	})

	for i in range(emails.size()):
		mail_list.add_item(emails[i]["subject"])

	if emails.size() > 0:
		_display_email(0)

func _on_mail_selected(index: int) -> void:
	_display_email(index)

func _display_email(index: int) -> void:
	if index >= 0 and index < emails.size():
		var e = emails[index]
		mail_subject.text = e["subject"]
		mail_content.text = "[b]Da:[/b] " + e["from"] + "\n\n" + e["body"]

		var cid = str(e.get("contract_id", ""))
		_selected_email_cid = cid
		if cid != "":
			var c = ContractManager.get_contract(cid)
			var status = c.get("status", "available")
			if status == "built" and not ContractManager.is_contract_completed(cid):
				deliver_project_btn.visible = true
				deliver_project_btn.text = "★ Consegna Progetto a %s (€ %0.2f)" % [c.get("client", "Cliente"), c.get("budget", 260.0)]
				return
		deliver_project_btn.visible = false

func _on_deliver_project_pressed() -> void:
	if _selected_email_cid != "":
		var sel = ContractManager.get_contract(_selected_email_cid)
		if sel.get("status") == "built":
			_complete_contract_by_id(_selected_email_cid)
			return
	for cid in ContractManager.active_contracts.keys():
		var c = ContractManager.get_contract(cid)
		if c.get("status") == "built":
			_complete_contract_by_id(cid)
			return

func _complete_contract_by_id(cid: String) -> void:
	if cid in ["pizzeria_da_mario", "caffe_san_carlo", "elettronica_to"]:
		ContractManager.complete_story_contract(cid)
	else:
		ContractManager.complete_marketplace_contract(cid)
	deliver_project_btn.visible = false
	_setup_emails()
	_update_freelance_display()
	_update_ogr_display()
	_update_shop_buttons()
	_update_rack_display()
	_update_top_bar()
	_refresh_desktop_badges()

func _update_lead_banner_only() -> void:
	if not lead_banner_label:
		return
	var hw_summary := "Magazzino Hardware: Router x%d | Server x%d | PC x%d | Firewall x%d" % [
		ShopManager.get_hardware_count("hw_wifi_router"),
		ShopManager.get_hardware_count("hw_server_tower"),
		ShopManager.get_hardware_count("hw_workstation_pc"),
		ShopManager.get_hardware_count("hw_firewall_appliance")
	]
	lead_banner_label.text = "📡 %s\n📦 %s" % [ContractManager.get_lead_eta_text(), hw_summary]

func _make_hub_card(bg: Color, border: Color) -> PanelContainer:
	var card := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = bg
	st.border_color = border
	st.set_border_width_all(1)
	st.set_corner_radius_all(8)
	st.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", st)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return card

func _update_freelance_display() -> void:
	_update_lead_banner_only()
	if not freelance_cards:
		return
	for ch in freelance_cards.get_children():
		ch.queue_free()

	# 1. Grande Appalto Officina Bellini (Borgo Valdocco Est)
	var fac := ContractManager.get_factory_progress_summary()
	if fac["accepted"] or ContractManager.is_contract_completed("elettronica_to"):
		var f_card := _make_hub_card(Color(0.14, 0.17, 0.24, 0.94), Color(0.92, 0.65, 0.22, 0.85))
		var f_vbox := VBoxContainer.new()
		f_vbox.add_theme_constant_override("separation", 6)
		f_card.add_child(f_vbox)

		var f_title := Label.new()
		f_title.text = "🏭 MAXI-APPALTO: OFFICINA MECCANICA BELLINI (BORGO VALDOCCO — EST)"
		f_title.add_theme_font_size_override("font_size", 13)
		f_title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.35))
		f_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		f_vbox.add_child(f_title)

		var f_info := Label.new()
		f_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		f_info.add_theme_font_size_override("font_size", 12)
		if not fac["accepted"]:
			f_info.text = "Esci dalla piazzetta e segui la strada asfaltata verso Est fino a Borgo Valdocco. Parla con l'Ing. Bellini e perlustra la fabbrica (Wi-Fi, Sito, Server Xeon, 2 PC)!"
			f_info.add_theme_color_override("font_color", Color(0.84, 0.88, 0.94))
			f_vbox.add_child(f_info)
		elif fac["completed"]:
			f_info.text = "✔ Appalto Completato al 100%%! Wi-Fi, Sito Web, Server Xeon e 2 Workstation CAD attivi — Cancelli OGR aperti!"
			f_info.add_theme_color_override("font_color", Color(0.35, 1.0, 0.58))
			f_vbox.add_child(f_info)
		else:
			var s_tag := "✔" if fac["all_scouted"] else "○"
			var w_tag := "✔" if fac["wifi_done"] else ("⚡NetShield" if fac["wifi_mounted"] else "○")
			var web_tag := "✔" if fac["web_done"] else "○"
			var srv_tag := "✔" if fac["server_done"] else "○"
			var pc_tag := "✔" if fac["pcs_done"] else "○"
			f_info.text = "Sopralluogo %s (%d/4 zone) | %s Wi-Fi Router & VLAN | %s Portale Web | %s Server Xeon | %s 2x PC CAD" % [
				s_tag, fac["scouted_count"], w_tag, web_tag, srv_tag, pc_tag
			]
			f_info.add_theme_color_override("font_color", Color(0.86, 0.92, 0.98))
			f_vbox.add_child(f_info)

			var f_actions := HFlowContainer.new()
			f_actions.add_theme_constant_override("h_separation", 8)
			f_actions.add_theme_constant_override("v_separation", 6)
			var web_c := ContractManager.get_contract("factory_bellini_web")
			var web_st := str(web_c.get("status", ""))
			var web_bgt := float(web_c.get("budget", 680.0))
			if web_st == "in_progress":
				var b_wf := Button.new()
				b_wf.text = "⚡ Sito WebForge (€ %0.0f)" % web_bgt
				b_wf.pressed.connect(func(): _launch_webforge_for("factory_bellini_web"))
				f_actions.add_child(b_wf)
			elif web_st == "built":
				var b_del := Button.new()
				b_del.text = "★ Consegna Sito (€ %0.0f)" % web_bgt
				b_del.add_theme_color_override("font_color", Color(0.35, 1.0, 0.55))
				b_del.pressed.connect(func(): _complete_contract_by_id("factory_bellini_web"))
				f_actions.add_child(b_del)
			if fac["wifi_mounted"] and not fac["wifi_done"]:
				var b_ns := Button.new()
				b_ns.text = "🛡 VLAN NetShield (€ 290)"
				b_ns.add_theme_color_override("font_color", Color(1.0, 0.72, 0.3))
				b_ns.pressed.connect(func(): _launch_netshield_for("factory_bellini_wifi"))
				f_actions.add_child(b_ns)
			if f_actions.get_child_count() > 0:
				f_vbox.add_child(f_actions)

		freelance_cards.add_child(f_card)

	# 2. Incarichi Attivi (Storia + B2B presi in carico)
	var active_ids: Array[String] = []
	for cid in ContractManager.active_contracts.keys():
		if cid == "factory_bellini_web":
			continue
		var st := str(ContractManager.active_contracts[cid].get("status", ""))
		if st == "in_progress" or st == "built":
			active_ids.append(cid)

	if not active_ids.is_empty():
		var act_hdr := Label.new()
		act_hdr.text = "🔧 INCARICHI IN LAVORAZIONE:"
		act_hdr.add_theme_font_size_override("font_size", 13)
		act_hdr.add_theme_color_override("font_color", Color(0.4, 0.92, 1.0))
		freelance_cards.add_child(act_hdr)

		for cid in active_ids:
			var c: Dictionary = ContractManager.active_contracts[cid]
			var st := str(c.get("status", "in_progress"))
			var etype := str(c.get("execution_type", "webforge"))
			var card := _make_hub_card(Color(0.14, 0.19, 0.28, 0.94), Color(0.30, 0.72, 0.95, 0.85))
			var v := VBoxContainer.new()
			v.add_theme_constant_override("separation", 6)
			card.add_child(v)

			var rd_pct := roundi((KnowledgeManager.get_contract_payout_mult(c) - 1.0) * 100.0) if is_instance_valid(KnowledgeManager) else 0
			var is_spec := bool(c.get("is_knowledge_specialty", false))
			var rd_tag := ""
			if is_spec or rd_pct > 0:
				rd_tag = " · ★ R&D +%d%%" % rd_pct if rd_pct > 0 else " · ★ R&D"

			var ttl := Label.new()
			ttl.text = "%s — %s (€ %0.2f · +%d Rep%s)" % [str(c.get("title", cid)), str(c.get("client", "")), float(c.get("budget", 0.0)), int(c.get("reputation_reward", 10)), rd_tag]
			ttl.add_theme_font_size_override("font_size", 13)
			ttl.add_theme_color_override("font_color", Color(0.95, 0.96, 1.0))
			ttl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			v.add_child(ttl)

			var req := Label.new()
			req.text = "%s | Requisiti: %s" % [str(c.get("category", "B2B")), ", ".join(c.get("requirements", []))]
			req.add_theme_font_size_override("font_size", 11)
			req.add_theme_color_override("font_color", Color(0.75, 0.82, 0.90))
			req.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			v.add_child(req)

			var row := HFlowContainer.new()
			row.add_theme_constant_override("h_separation", 8)
			row.add_theme_constant_override("v_separation", 6)
			if st == "built":
				var d_btn := Button.new()
				d_btn.text = "★ Consegna & Incassa (€ %0.2f)" % float(c.get("budget", 0.0))
				d_btn.add_theme_color_override("font_color", Color(0.35, 1.0, 0.55))
				var cid_copy := cid
				d_btn.pressed.connect(func(): _complete_contract_by_id(cid_copy))
				row.add_child(d_btn)
			elif etype == "netshield":
				var ns_btn := Button.new()
				ns_btn.text = "🛡 Configura su NetShield Cyber"
				ns_btn.add_theme_color_override("font_color", Color(1.0, 0.72, 0.30))
				var cid_copy := cid
				ns_btn.pressed.connect(func(): _launch_netshield_for(cid_copy))
				row.add_child(ns_btn)
			elif etype == "hardware":
				var req_hw: Dictionary = c.get("required_hardware", {})
				var parts: Array[String] = []
				var all_ok := true
				for hw_id in req_hw:
					var need := int(req_hw[hw_id])
					var have := ShopManager.get_hardware_count(str(hw_id))
					if have < need:
						all_ok = false
					parts.append("%s: %d/%d" % [ShopManager.get_hardware_item_name(str(hw_id)), have, need])
				var hw_lbl := Label.new()
				hw_lbl.custom_minimum_size = Vector2(220, 0)
				hw_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				hw_lbl.text = "Stock: " + ", ".join(parts)
				hw_lbl.add_theme_font_size_override("font_size", 11)
				hw_lbl.add_theme_color_override("font_color", Color(0.45, 1.0, 0.65) if all_ok else Color(1.0, 0.78, 0.35))
				hw_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				row.add_child(hw_lbl)

				var hw_btn := Button.new()
				hw_btn.text = "📦 Installa & Consegna" if all_ok else "🛒 Compra Hardware"
				var cid_copy := cid
				if all_ok:
					hw_btn.add_theme_color_override("font_color", Color(0.35, 1.0, 0.55))
					hw_btn.pressed.connect(func():
						ContractManager.deliver_hardware_contract(cid_copy)
						_update_freelance_display()
					)
				else:
					hw_btn.pressed.connect(func(): _open_window(shop_window))
				row.add_child(hw_btn)
			else:
				var wf_btn := Button.new()
				wf_btn.text = "⚡ Sviluppa su WebForge"
				wf_btn.add_theme_color_override("font_color", Color(0.40, 0.92, 1.0))
				var cid_copy := cid
				wf_btn.pressed.connect(func(): _launch_webforge_for(cid_copy))
				row.add_child(wf_btn)

			if not (cid in ["pizzeria_da_mario", "caffe_san_carlo", "elettronica_to", "factory_bellini_web"]):
				var cxl_btn := Button.new()
				cxl_btn.text = "✕ Ritira"
				cxl_btn.add_theme_color_override("font_color", Color(1.0, 0.55, 0.55))
				var cid_cxl := cid
				cxl_btn.pressed.connect(func():
					ContractManager.cancel_active_contract(cid_cxl)
					_update_freelance_display()
				)
				row.add_child(cxl_btn)

			v.add_child(row)
			freelance_cards.add_child(card)

	# 3. Offerte B2B Disponibili su Freelance Hub
	var mkt_hdr := Label.new()
	mkt_hdr.text = "💼 MARKETPLACE FREELANCE TORINO (%d OFFERTE APERTE):" % ContractManager.marketplace_contracts.size()
	mkt_hdr.add_theme_font_size_override("font_size", 13)
	mkt_hdr.add_theme_color_override("font_color", Color(1.0, 0.82, 0.32))
	freelance_cards.add_child(mkt_hdr)

	if ContractManager.marketplace_contracts.is_empty():
		var empty_card := _make_hub_card(Color(0.14, 0.16, 0.21, 0.9), Color(0.28, 0.34, 0.45, 0.7))
		var empty_lbl := Label.new()
		empty_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_lbl.add_theme_font_size_override("font_size", 12)
		empty_lbl.add_theme_color_override("font_color", Color(0.75, 0.80, 0.88))
		if not ContractManager.is_contract_completed("pizzeria_da_mario"):
			empty_lbl.text = "Consegna prima il sito alla Pizzeria Da Mario: i primi clienti B2B arriveranno dopo la tua prima referenza nel borgo!"
		else:
			empty_lbl.text = "Nessuna nuova richiesta in questo istante. %s" % ContractManager.get_lead_eta_text()
		empty_card.add_child(empty_lbl)
		freelance_cards.add_child(empty_card)
	else:
		for c in ContractManager.marketplace_contracts:
			var cid := str(c["id"])
			var etype := str(c.get("execution_type", "webforge"))
			var rd_pct := roundi((KnowledgeManager.get_contract_payout_mult(c) - 1.0) * 100.0) if is_instance_valid(KnowledgeManager) else 0
			var is_spec := bool(c.get("is_knowledge_specialty", false))
			var badge_col := Color(0.35, 0.88, 1.0)
			var type_tag := "WEBFORGE"
			if etype == "netshield":
				badge_col = Color(1.0, 0.68, 0.25)
				type_tag = "NETSHIELD CYBER"
			elif etype == "hardware":
				badge_col = Color(0.55, 1.0, 0.58)
				type_tag = "HARDWARE B2B"
			if is_spec:
				type_tag += " ★ R&D"

			var m_card := _make_hub_card(Color(0.14, 0.18, 0.26, 0.94), badge_col * Color(1, 1, 1, 0.7))
			var mv := VBoxContainer.new()
			mv.add_theme_constant_override("separation", 5)
			m_card.add_child(mv)

			var top_row := HFlowContainer.new()
			top_row.add_theme_constant_override("h_separation", 8)
			top_row.add_theme_constant_override("v_separation", 4)
			var title_lbl := Label.new()
			title_lbl.custom_minimum_size = Vector2(220, 0)
			title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			title_lbl.text = "[%s] %s — %s" % [type_tag, str(c["title"]), str(c["client"])]
			title_lbl.add_theme_font_size_override("font_size", 13)
			title_lbl.add_theme_color_override("font_color", badge_col)
			title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			top_row.add_child(title_lbl)

			var accept_btn := Button.new()
			accept_btn.custom_minimum_size = Vector2(145, 32)
			accept_btn.text = "✓ Accetta (€ %0.0f)" % float(c["budget"])
			accept_btn.add_theme_color_override("font_color", Color(0.35, 1.0, 0.58))
			accept_btn.pressed.connect(func():
				SoundManager.play_ui_click()
				ContractManager.accept_marketplace_contract(cid)
				_update_freelance_display()
			)
			top_row.add_child(accept_btn)
			mv.add_child(top_row)

			var meta_lbl := Label.new()
			var rd_bonus_txt := " (+%d%% Conoscenza 📘)" % rd_pct if rd_pct > 0 else ""
			meta_lbl.text = "Settore: %s | Compenso: € %0.2f%s (+%d Rep) | Scadenza: %d gg | Difficoltà: %s\nRequisiti: %s" % [
				str(c.get("category", "B2B")),
				float(c.get("budget", 0.0)),
				rd_bonus_txt,
				int(c.get("reputation_reward", 10)),
				int(c.get("deadline_days", 3)),
				"★".repeat(int(c.get("difficulty", 1))),
				", ".join(c.get("requirements", []))
			]
			meta_lbl.add_theme_font_size_override("font_size", 11)
			meta_lbl.add_theme_color_override("font_color", Color(0.80, 0.85, 0.92))
			meta_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			mv.add_child(meta_lbl)

			freelance_cards.add_child(m_card)

	# 4. Riepilogo Missioni Storia San Carlo
	var story_hdr := Label.new()
	story_hdr.text = "📜 COMMISSIONI QUARTIERE BORGO SAN CARLO:"
	story_hdr.add_theme_font_size_override("font_size", 12)
	story_hdr.add_theme_color_override("font_color", Color(0.75, 0.82, 0.92))
	freelance_cards.add_child(story_hdr)

	for scid in ["pizzeria_da_mario", "caffe_san_carlo", "elettronica_to"]:
		var sc = ContractManager.get_contract(scid)
		if sc.is_empty():
			continue
		var sst = str(sc.get("status", "available"))
		var s_lbl := Label.new()
		s_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		s_lbl.add_theme_font_size_override("font_size", 11)
		s_lbl.text = "• %s (%s) — € %0.2f [%s] — %s" % [sc.get("title", ""), sc.get("client", ""), float(sc.get("budget", 0.0)), sst.to_upper(), sc.get("objective_text", "")]
		s_lbl.add_theme_color_override("font_color", Color(0.55, 1.0, 0.65) if sst == "completed" else Color(0.78, 0.82, 0.88))
		freelance_cards.add_child(s_lbl)

	var has_wf := false
	for ac in ContractManager.active_contracts.values():
		if ac.get("status") == "in_progress" and ac.get("execution_type", "webforge") == "webforge":
			has_wf = true
			break
	open_webforge_btn.visible = has_wf
	if has_wf:
		open_webforge_btn.text = "⚡ Apri WebForge IDE (Sviluppa Sito Selezionato)"

	if freelance_text:
		freelance_text.text = ContractManager.get_lead_eta_text()

func _launch_webforge() -> void:
	var has_active = false
	for c in ContractManager.active_contracts.values():
		if c.get("status") == "in_progress" and c.get("execution_type", "webforge") == "webforge":
			has_active = true
			break
	if not has_active:
		SoundManager.play_ui_click()
		EventBus.notification_posted.emit(
			"WebForge Inattivo",
			"Nessun sito web in lavorazione! Accetta un lavoro su Freelance Hub o parla con i clienti nel Borgo.",
			"warning"
		)
		return
	SoundManager.play_ui_click()
	EventBus.minigame_started.emit("web_forge")

func _launch_webforge_for(cid: String) -> void:
	ContractManager.preferred_webforge_contract_id = cid
	SoundManager.play_ui_click()
	EventBus.minigame_started.emit("web_forge")

func _launch_netshield_for(cid: String) -> void:
	ContractManager.preferred_netshield_contract_id = cid
	SoundManager.play_ui_click()
	EventBus.minigame_started.emit("firewall_router")

func _update_shop_buttons() -> void:
	var has_monitor = "monitor_upgrade" in GameManager.studio_upgrades_installed
	var has_chair = "chair_gaming_upgrade" in GameManager.studio_upgrades_installed
	var has_plant = "plant_aloe" in GameManager.studio_upgrades_installed or "plant_aloe_upgrade" in GameManager.studio_upgrades_installed
	var has_server = "server_rack_upgrade" in GameManager.studio_upgrades_installed
	var col_ok := Color(0.27, 1.0, 0.53)
	var col_avail := Color(0.75, 0.78, 0.85)

	if has_monitor:
		buy_monitor_btn.disabled = true
		buy_monitor_btn.text = "GIÀ INSTALLATO"
		monitor_status.text = "Installato sulla scrivania"
		monitor_status.add_theme_color_override("font_color", col_ok)
	else:
		buy_monitor_btn.disabled = not EconomyManager.can_afford(350.0)
		buy_monitor_btn.text = "Acquista (€ 350,00)"
		monitor_status.text = "Disponibile"
		monitor_status.add_theme_color_override("font_color", col_avail)

	if has_chair:
		buy_chair_btn.disabled = true
		buy_chair_btn.text = "GIÀ INSTALLATA"
		chair_status.text = "Installata alla postazione"
		chair_status.add_theme_color_override("font_color", col_ok)
	else:
		buy_chair_btn.disabled = not EconomyManager.can_afford(220.0)
		buy_chair_btn.text = "Acquista (€ 220,00)"
		chair_status.text = "Disponibile"
		chair_status.add_theme_color_override("font_color", col_avail)

	if has_plant:
		buy_plant_btn.disabled = true
		buy_plant_btn.text = "GIÀ POSIZIONATA"
		plant_status.text = "Posizionata in studio"
		plant_status.add_theme_color_override("font_color", col_ok)
	else:
		buy_plant_btn.disabled = not EconomyManager.can_afford(35.0)
		buy_plant_btn.text = "Acquista (€ 35,00)"
		plant_status.text = "Disponibile"
		plant_status.add_theme_color_override("font_color", col_avail)

	if has_server:
		buy_server_btn.disabled = true
		buy_server_btn.text = "GIÀ INSTALLATO"
		server_status.text = "Attivo (Hosting ON)"
		server_status.add_theme_color_override("font_color", col_ok)
	else:
		buy_server_btn.disabled = not EconomyManager.can_afford(450.0)
		buy_server_btn.text = "Acquista (€ 450,00)"
		server_status.text = "Disponibile"
		server_status.add_theme_color_override("font_color", col_avail)

	_rebuild_client_hardware_shop()

func _rebuild_client_hardware_shop() -> void:
	if not hw_grid:
		return
	for ch in hw_grid.get_children():
		ch.queue_free()

	if hw_hint_label:
		var partner := ContractManager.is_contract_completed("elettronica_to")
		var fame_disc := FameManager.get_discount_percent()
		var disc_str := "Sconto Partner Davide (-20%) ATTIVO!" if partner else "Completa Elettronica TO per -20% sconto fisso."
		if fame_disc > 0:
			disc_str += " | Bonus Fame: -%d%%" % fame_disc
		hw_hint_label.text = "%s | Totale pezzi in magazzino: %d" % [disc_str, ShopManager.get_hardware_count()]

	var items := ShopManager.get_items("elettronica_componenti")
	for it in items:
		var hw_id := str(it["id"])
		var base_p := ShopManager.get_base_price("elettronica_componenti", hw_id)
		var price := ShopManager.get_price("elettronica_componenti", hw_id)
		var stock := ShopManager.get_hardware_count(hw_id)

		var card := _make_hub_card(Color(0.14, 0.18, 0.26, 0.94), Color(0.32, 0.45, 0.65, 0.75))
		card.custom_minimum_size = Vector2(235, 138)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 6)
		card.add_child(v)

		var n_lbl := Label.new()
		n_lbl.text = str(it["name"])
		n_lbl.add_theme_font_size_override("font_size", 14)
		n_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
		n_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(n_lbl)

		var p_lbl := Label.new()
		if price < base_p:
			p_lbl.text = "€ %0.2f (Listino € %0.2f)" % [price, base_p]
		else:
			p_lbl.text = "€ %0.2f" % price
		p_lbl.add_theme_font_size_override("font_size", 13)
		p_lbl.add_theme_color_override("font_color", Color(0.35, 1.0, 0.60))
		v.add_child(p_lbl)

		var d_lbl := Label.new()
		d_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		d_lbl.text = str(it.get("desc", ""))
		d_lbl.add_theme_font_size_override("font_size", 11)
		d_lbl.add_theme_color_override("font_color", Color(0.76, 0.82, 0.88))
		d_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(d_lbl)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 6)
		var st_lbl := Label.new()
		st_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		st_lbl.text = "Stock: x%d" % stock
		st_lbl.clip_text = true
		st_lbl.add_theme_font_size_override("font_size", 12)
		st_lbl.add_theme_color_override("font_color", Color(0.35, 1.0, 0.60) if stock > 0 else Color(0.75, 0.78, 0.85))
		hbox.add_child(st_lbl)

		var buy_btn := Button.new()
		buy_btn.custom_minimum_size = Vector2(115, 32)
		buy_btn.text = "Ordina (€ %0.0f)" % price
		buy_btn.disabled = not EconomyManager.can_afford(price)
		buy_btn.pressed.connect(func():
			if ShopManager.buy_hardware(hw_id, 1):
				_update_shop_buttons()
				_update_freelance_display()
		)
		hbox.add_child(buy_btn)
		v.add_child(hbox)
		hw_grid.add_child(card)

func _buy_monitor() -> void:
	if EconomyManager.spend(350.0, "Acquisto Monitor 27\" Ultrawide"):
		EventBus.item_purchased.emit("monitor_upgrade", 350.0)
		EventBus.notification_posted.emit("Upgrade Installato", "Il secondo monitor è stato montato sulla scrivania!", "success")
		_update_shop_buttons()

func _buy_chair() -> void:
	if EconomyManager.spend(220.0, "Acquisto Sedia Ergonomica Pro"):
		EventBus.item_purchased.emit("chair_gaming_upgrade", 220.0)
		EventBus.notification_posted.emit("Upgrade Installato", "La nuova sedia ergonomica è stata posizionata!", "success")
		_update_shop_buttons()

func _buy_plant() -> void:
	if EconomyManager.spend(35.0, "Acquisto Pianta Succulenta d'Arredo"):
		EventBus.item_purchased.emit("plant_aloe", 35.0)
		EventBus.notification_posted.emit("Arredo Posizionato", "La pianta d'arredo è stata collocata nel tuo studio!", "success")
		_update_shop_buttons()

func _buy_server() -> void:
	if EconomyManager.spend(450.0, "Acquisto Mini Server Rack 4U & NAS"):
		EventBus.item_purchased.emit("server_rack_upgrade", 450.0)
		ServerRackManager.unlock_server_rack()
		EventBus.notification_posted.emit("Infrastruttura Attiva", "Il server rack è attivo in studio! Sbloccati servizi di Hosting.", "success")
		_update_shop_buttons()
		_update_rack_display()

func _update_bank_display() -> void:
	var t = "[b]SALDO ATTUALE:[/b] € %0.2f\n\n[b]ESTRATTO CONTO RECENTE:[/b]\n" % EconomyManager.balance
	for entry in EconomyManager.ledger:
		var delta_str = "+€ %0.2f" % entry["delta"] if entry["delta"] >= 0 else "-€ %0.2f" % abs(entry["delta"])
		t += "• %s: %s (Saldo: € %0.2f)\n" % [entry["reason"], delta_str, entry["balance_after"]]
	bank_ledger_text.text = t

# ==============================================================================
# RACK MANAGER UI
# ==============================================================================
func _launch_firewall() -> void:
	SoundManager.play_ui_click()
	EventBus.minigame_started.emit("firewall_router")

func _update_rack_display() -> void:
	if not rack_window:
		return

	var temp = ServerRackManager.temperature_celsius
	var fans = ServerRackManager.fan_speed_rpm
	var bw = ServerRackManager.bandwidth_mbps
	var status = ServerRackManager.status_health

	_on_rack_telemetry(temp, fans, bw, status)

	var max_safe = ServerRackManager.get_max_safe_domains()
	var current_domains = ServerRackManager.hosted_domains.size()
	var dt = "[b]HARDWARE:[/b] [color=#00ccff]%s[/color]\n" % ServerRackManager.get_tier_name()
	dt += "[b]CAPACITÀ ATTUALE:[/b] %d / %d Domini Massimi\n\n" % [current_domains, max_safe]

	if current_domains > max_safe:
		dt += "[color=#ff4444][b]⚠ ATTENZIONE: SERVER IN SOVRACCARICO (OVERLOAD)![/b]\nIl mini-rack casalingo è sovraccarico (limite: %d clienti). CPU al 95%%, thermal throttling attivo e rendite dimezzate (-50%%)! Aggiorna a Blade 12U Enterprise![/color]\n\n" % max_safe
	elif current_domains == max_safe:
		dt += "[color=#ffbb33]Capacità massima del rack raggiunta (%d/%d). Nuovi contratti richiederanno un upgrade hardware![/color]\n\n" % [current_domains, max_safe]

	if ServerRackManager.hosted_domains.is_empty():
		dt += "Nessun dominio ospitato. Acquista il server rack e completa contratti per vendere servizi di hosting!\n"
	else:
		var total_daily = ServerRackManager.calculate_daily_hosting_revenue()
		for d in ServerRackManager.hosted_domains:
			dt += "• [b]%s[/b] (%s)\n  Canone: [color=#44ff88]+€ %0.2f/giorno[/color] | Status: [color=#33ff77]ONLINE 200 OK[/color]\n\n" % [d["domain"], d["client_name"], d["daily_rate"]]
		dt += "[b]Totale Ricavi Ricorrenti:[/b] [color=#44ff88]+€ %0.2f/giorno[/color]" % total_daily
		if EmployeeManager.is_employee_hired("emp_sara"):
			dt += " [color=#00ccff](+35% Bonus DevOps Sara Bellini)[/color]"
		if is_instance_valid(UpgradeManager) and UpgradeManager.get_rank("hosting") > 0:
			var pct := roundi((UpgradeManager.get_hosting_bonus_mult() - 1.0) * 100.0)
			dt += " [color=#ffd655](+%d%% Cluster Cloud ★)[/color]" % pct
		if is_instance_valid(KnowledgeManager) and KnowledgeManager.get_rank("cloud_devops") > 0:
			var kpct := roundi((KnowledgeManager.get_rack_hosting_mult() - 1.0) * 100.0)
			dt += " [color=#7ad8ff](+%d%% Cloud R&D 📘)[/color]" % kpct

	domains_text.text = dt

	var has_blade = "server_blade_quad" in ServerRackManager.installed_modules
	var has_liquid = "server_cooling_liquid" in ServerRackManager.installed_modules
	var has_san = "server_storage_san" in ServerRackManager.installed_modules
	var is_unlocked = ServerRackManager.is_rack_unlocked

	buy_blade_btn.disabled = has_blade or not is_unlocked or not EconomyManager.can_afford(450.0)
	buy_blade_btn.text = "✔ Blade Quad-Core Installato" if has_blade else "+ Modulo Blade Xeon (€ 450,00)"

	buy_liquid_btn.disabled = has_liquid or not is_unlocked or not EconomyManager.can_afford(320.0)
	buy_liquid_btn.text = "✔ Raffreddamento Liquido Attivo" if has_liquid else "+ Raffreddamento Liquido (€ 320,00)"

	buy_san_btn.disabled = has_san or not is_unlocked or not EconomyManager.can_afford(680.0)
	buy_san_btn.text = "✔ Storage SAN Raid-10 Attivo (+25%)" if has_san else "+ Storage SAN Raid-10 (€ 680,00)"

	var tier = ServerRackManager.rack_tier
	if tier >= 2:
		upgrade_tier2_btn.disabled = true
		upgrade_tier2_btn.text = "✔ Tier 2: Blade 12U Enterprise"
	else:
		upgrade_tier2_btn.disabled = not is_unlocked or not EconomyManager.can_afford(750.0)
		upgrade_tier2_btn.text = "▲ Blade 12U Enterprise (€ 750,00) [8 Domini]"

	if tier >= 3:
		upgrade_tier3_btn.disabled = true
		upgrade_tier3_btn.text = "✔ Tier 3: Full Cabinet 42U DC"
	elif tier == 2:
		upgrade_tier3_btn.disabled = not EconomyManager.can_afford(1600.0)
		upgrade_tier3_btn.text = "▲ Cabinet 42U Data Center (€ 1.600) [20 Domini]"
	else:
		upgrade_tier3_btn.disabled = true
		upgrade_tier3_btn.text = "▲ Cabinet 42U (Richiede Tier 2)"

func _on_rack_telemetry(temp: float, fans: int, bw: float, status: String) -> void:
	temp_label.text = "🌡 CPU: %0.1f °C [%s]" % [temp, status.to_upper()]
	fans_label.text = "💨 Ventole: %d RPM" % fans
	bandwidth_label.text = "📡 Banda: %0.1f Mbps" % bw
	uptime_label.text = "⏱ Uptime: %0.2f%%" % ServerRackManager.uptime_percent

func _buy_blade() -> void:
	if ServerRackManager.install_module("server_blade_quad", "Blade Quad-Core Xeon", 450.0):
		_update_rack_display()

func _buy_liquid() -> void:
	if ServerRackManager.install_module("server_cooling_liquid", "Raffreddamento a Liquido AIO", 320.0):
		_update_rack_display()

func _buy_san() -> void:
	if ServerRackManager.install_module("server_storage_san", "Storage SAN Raid-10", 680.0):
		_update_rack_display()

# ==============================================================================
# TALENT HUB UI
# ==============================================================================
func _update_talent_display() -> void:
	if not talent_window:
		return

	var hired = EmployeeManager.get_hired_employees()
	var payroll = EmployeeManager.calculate_daily_payroll()
	var revenue = EmployeeManager.calculate_employee_revenue()
	var net = revenue - payroll

	var max_slots: int = GameManager.get_max_employee_slots() if GameManager.has_method("get_max_employee_slots") else 1
	var tier_name: String = GameManager.get_company_tier_name() if GameManager.has_method("get_company_tier_name") else "Sede Aziendale"
	talent_stats_label.text = "🏢 Sede: %s (Scrivanie: %d/%d) | 👥 Team: %d | Buste Paga: € %0.2f/g | Ricavi: +€ %0.2f/g | Netto: +€ %0.2f/g" % [
		tier_name, hired.size(), max_slots, hired.size(), payroll, revenue, net
	]

	for child in candidates_list.get_children():
		child.queue_free()

	if GameManager.company_tier < 4:
		var exp_check: Dictionary = GameManager.can_upgrade_company_tier()
		var target_tier: int = GameManager.company_tier + 1
		var target_name: String = GameManager.get_company_tier_name(target_tier)

		var exp_card = _make_hub_card(Color(0.14, 0.18, 0.26, 0.94), Color(0.35, 0.55, 0.85, 0.8))
		var exp_hbox = HBoxContainer.new()
		exp_hbox.add_theme_constant_override("separation", 12)

		var exp_vbox = VBoxContainer.new()
		exp_vbox.size_flags_horizontal = SIZE_EXPAND_FILL

		var exp_title = Label.new()
		exp_title.text = "🏢 Espansione Sede: %s (Livello %d)" % [target_name, target_tier]
		exp_title.add_theme_font_size_override("font_size", 15)
		exp_title.add_theme_color_override("font_color", Color(0.95, 0.82, 0.35, 1))
		exp_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		exp_vbox.add_child(exp_title)

		var exp_desc = Label.new()
		var target_slots: int = 1 if target_tier == 2 else (3 if target_tier == 3 else 6)
		exp_desc.text = "Espandi l'ufficio per ospitare fino a %d dipendenti e sbloccare nuove opportunità commerciali a Torino." % target_slots
		exp_desc.add_theme_font_size_override("font_size", 12)
		exp_desc.add_theme_color_override("font_color", Color(0.75, 0.8, 0.85, 1))
		exp_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		exp_vbox.add_child(exp_desc)

		var exp_req = Label.new()
		var cost_val = float(exp_check.get("cost", 950.0 if target_tier == 2 else (3500.0 if target_tier == 3 else 8000.0)))
		exp_req.text = "Costo Espansione: € %0.2f | Reputazione Richiesta: %s" % [cost_val, "65" if target_tier == 2 else ("120" if target_tier == 3 else "250")]
		exp_req.add_theme_font_size_override("font_size", 11)
		exp_req.add_theme_color_override("font_color", Color(0.4, 0.9, 0.6, 1))
		exp_req.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		exp_vbox.add_child(exp_req)

		if not exp_check.get("allowed", false):
			var exp_blocked_lbl = Label.new()
			exp_blocked_lbl.text = "🔒 " + str(exp_check.get("reason", "Requisiti non soddisfatti"))
			exp_blocked_lbl.add_theme_font_size_override("font_size", 11)
			exp_blocked_lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45, 1))
			exp_blocked_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			exp_vbox.add_child(exp_blocked_lbl)

		exp_hbox.add_child(exp_vbox)

		var exp_btn = Button.new()
		exp_btn.custom_minimum_size = Vector2(150, 40)
		exp_btn.size_flags_vertical = SIZE_SHRINK_CENTER
		exp_btn.text = "Espandi (€ %0.0f)" % cost_val
		exp_btn.disabled = not exp_check.get("allowed", false)
		if exp_check.get("allowed", false):
			exp_btn.add_theme_color_override("font_color", Color(1, 0.85, 0.2, 1))
		exp_btn.pressed.connect(func():
			if GameManager.upgrade_company_tier():
				_update_talent_display()
		)
		exp_hbox.add_child(exp_btn)
		exp_card.add_child(exp_hbox)
		candidates_list.add_child(exp_card)

	var candidates = EmployeeManager.get_all_candidates()
	for cand in candidates:
		var card = _make_hub_card(Color(0.15, 0.18, 0.25, 0.94), Color(0.30, 0.45, 0.68, 0.65))
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)

		var vbox = VBoxContainer.new()
		vbox.size_flags_horizontal = SIZE_EXPAND_FILL

		var name_lbl = Label.new()
		name_lbl.text = "%s — %s" % [cand["name"], cand["role"]]
		name_lbl.add_theme_font_size_override("font_size", 15)
		name_lbl.add_theme_color_override("font_color", Color(0.3, 0.9, 1, 1))
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(name_lbl)

		var desc_lbl = Label.new()
		desc_lbl.text = cand["avatar_desc"]
		desc_lbl.add_theme_font_size_override("font_size", 12)
		desc_lbl.add_theme_color_override("font_color", Color(0.75, 0.8, 0.85, 1))
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(desc_lbl)

		var perk_lbl = Label.new()
		perk_lbl.text = "★ Specializzazione: " + cand["perk"]
		perk_lbl.add_theme_font_size_override("font_size", 12)
		perk_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.4, 1))
		perk_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(perk_lbl)

		var salary_lbl = Label.new()
		salary_lbl.text = "Stipendio: € %0.2f/g | Valore: € %0.2f/g | Rep. Req: %d" % [cand["daily_salary"], cand["daily_revenue"], cand["reputation_req"]]
		salary_lbl.add_theme_font_size_override("font_size", 12)
		salary_lbl.add_theme_color_override("font_color", Color(0.4, 1, 0.6, 1))
		salary_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(salary_lbl)

		var is_hired = EmployeeManager.is_employee_hired(cand["id"])
		var action_btn = Button.new()
		action_btn.custom_minimum_size = Vector2(135, 40)
		action_btn.size_flags_vertical = SIZE_SHRINK_CENTER

		if is_hired:
			var auto_lbl := Label.new()
			auto_lbl.text = EmployeeManager.get_employee_task_status_text(cand["id"])
			auto_lbl.add_theme_font_size_override("font_size", 11)
			auto_lbl.add_theme_color_override("font_color", Color(0.55, 0.95, 1.0))
			auto_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			vbox.add_child(auto_lbl)

			var sk_row := HFlowContainer.new()
			sk_row.add_theme_constant_override("h_separation", 6)
			sk_row.add_theme_constant_override("v_separation", 4)
			for track_id in ["speed", "value", "quality"]:
				var tdef: Dictionary = EmployeeManager.SKILL_TRACKS[track_id]
				var cur_rk: int = int(EmployeeManager.get_employee_skill(str(cand["id"]), str(track_id)))
				var chk: Dictionary = EmployeeManager.can_upgrade_employee_skill(str(cand["id"]), str(track_id))
				var sbtn := Button.new()
				sbtn.focus_mode = Control.FOCUS_NONE
				if cur_rk >= int(EmployeeManager.MAX_SKILL_RANK):
					sbtn.text = "✔ %s Lv.3/3" % str(tdef["title"]).split(" ")[0]
					sbtn.disabled = true
				else:
					var ucost := float(chk.get("cost", 0.0))
					sbtn.text = "%s %s Lv.%d/3 (€ %0.0f)" % [str(tdef["icon"]), str(tdef["title"]).split(" ")[0], cur_rk, ucost]
					sbtn.disabled = not bool(chk.get("allowed", false))
					if bool(chk.get("allowed", false)):
						sbtn.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
					var emp_copy: String = str(cand["id"])
					var tr_copy: String = str(track_id)
					sbtn.pressed.connect(func():
						if EmployeeManager.upgrade_employee_skill(emp_copy, tr_copy):
							_update_talent_display()
							_update_top_bar()
					)
				sk_row.add_child(sbtn)
			vbox.add_child(sk_row)


			action_btn.text = "Licenzia"
			action_btn.add_theme_color_override("font_color", Color(1, 0.4, 0.4, 1))
			var cid = cand["id"]
			action_btn.pressed.connect(func(): EmployeeManager.fire_employee(cid); _update_talent_display())

		else:
			var hire_check: Dictionary = EmployeeManager.can_hire_employee(cand["id"])
			var can_hire: bool = hire_check.get("allowed", false)
			action_btn.text = "Assumi (€ %0.0f)" % cand["daily_salary"]
			action_btn.disabled = not can_hire
			if can_hire:
				action_btn.add_theme_color_override("font_color", Color(0.3, 1, 0.6, 1))
			else:
				action_btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))
				var block_lbl = Label.new()
				block_lbl.text = "🔒 " + str(hire_check.get("reason", "Assunzione non consentita"))
				block_lbl.add_theme_font_size_override("font_size", 11)
				block_lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45, 1))
				block_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				vbox.add_child(block_lbl)

			var cid = cand["id"]
			action_btn.pressed.connect(func(): EmployeeManager.hire_employee(cid); _update_talent_display())

		hbox.add_child(vbox)
		hbox.add_child(action_btn)
		card.add_child(hbox)
		candidates_list.add_child(card)

func _render_talent_hub() -> void:
	_update_talent_display()
