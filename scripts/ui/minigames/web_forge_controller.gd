extends Control
## WebForgeController - Interactive visual website builder minigame

@onready var ide_label: Label = $Main/Header/HBox/IDELabel
@onready var quality_progress: ProgressBar = $Main/Header/HBox/QualityProgress
@onready var quality_label: Label = $Main/Header/HBox/QualityLabel
@onready var preview_scroll: ScrollContainer = $Main/Body/PreviewArea/Scroll
@onready var preview_vbox: VBoxContainer = $Main/Body/PreviewArea/Scroll/VBox
@onready var compile_btn: Button = $Main/Footer/CompileButton
@onready var exit_btn: Button = $Main/Header/HBox/ExitButton

# Component checkboxes / buttons in the left palette
@onready var chk_header: CheckButton = $Main/Body/Palette/VBox/ChkHeader
@onready var chk_hero: CheckButton = $Main/Body/Palette/VBox/ChkHero
@onready var chk_menu: CheckButton = $Main/Body/Palette/VBox/ChkMenu
@onready var chk_hours: CheckButton = $Main/Body/Palette/VBox/ChkHours
@onready var chk_booking: CheckButton = $Main/Body/Palette/VBox/ChkBooking

# Theme OptionButton
@onready var theme_picker: OptionButton = $Main/Body/Palette/VBox/ThemePicker

var current_theme_color: Color = Color(0.85, 0.25, 0.2, 1) # Classic Pizza Red

func _ready() -> void:
	visible = false
	EventBus.minigame_started.connect(_on_minigame_started)
	
	exit_btn.pressed.connect(_on_exit_pressed)
	compile_btn.pressed.connect(_on_compile_pressed)
	
	chk_header.toggled.connect(func(_b): _on_component_toggled())
	chk_hero.toggled.connect(func(_b): _on_component_toggled())
	chk_menu.toggled.connect(func(_b): _on_component_toggled())
	chk_hours.toggled.connect(func(_b): _on_component_toggled())
	chk_booking.toggled.connect(func(_b): _on_component_toggled())
	
	theme_picker.item_selected.connect(_on_theme_selected)
	
	_update_website_preview()

func _on_minigame_started(type: String) -> void:
	if type == "web_forge":
		var tut = ContractManager.get_tutorial_contract()
		var status = tut.get("status", "available")
		if status == "available":
			visible = false
			EventBus.notification_posted.emit(
				"WebForge Bloccato",
				"Nessun progetto attivo! Raggiungi prima Mario alla Pizzeria in Via Po per accettare la commissione.",
				"warning"
			)
			return
			
		visible = true
		ide_label.text = "⚡ WebForge IDE — Progetto: %s (Budget: € %0.2f)" % [tut.get("title", "Sito Web"), tut.get("budget", 650.0)]
		_update_website_preview()

func _on_exit_pressed() -> void:
	visible = false
	EventBus.computer_opened.emit()

func _on_theme_selected(index: int) -> void:
	match index:
		0: current_theme_color = Color(0.85, 0.25, 0.2, 1)  # Rosso Tradizionale
		1: current_theme_color = Color(0.15, 0.65, 0.35, 1) # Verde Basilico
		2: current_theme_color = Color(0.25, 0.28, 0.35, 1) # Antracite Gourmet
	SoundManager.play_ui_click()
	_update_website_preview()

func _on_component_toggled() -> void:
	SoundManager.play_ui_click()
	_update_website_preview()

func _update_website_preview() -> void:
	# Clear previous preview nodes
	for child in preview_vbox.get_children():
		child.queue_free()
		
	# 0. Browser Bar URL simulation
	var url_bar = PanelContainer.new()
	var url_style = StyleBoxFlat.new()
	url_style.bg_color = Color(0.18, 0.2, 0.26, 1)
	url_style.set_content_margin_all(8)
	url_style.set_corner_radius_all(4)
	url_bar.add_theme_stylebox_override("panel", url_style)
	var url_lbl = Label.new()
	url_lbl.text = "🔒 https://www.pizzeriadamario-torino.it [Local Preview]"
	url_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5, 1))
	url_lbl.add_theme_font_size_override("font_size", 12)
	url_bar.add_child(url_lbl)
	preview_vbox.add_child(url_bar)

	var active_count = 0
	
	# 1. Header / Logo
	if chk_header.button_pressed:
		active_count += 1
		var header_panel = PanelContainer.new()
		var h_style = StyleBoxFlat.new()
		h_style.bg_color = current_theme_color
		h_style.set_content_margin_all(14)
		h_style.set_corner_radius_all(6)
		header_panel.add_theme_stylebox_override("panel", h_style)
		
		var h_lbl = Label.new()
		h_lbl.text = "🏛 PIZZERIA DA MARIO - TORINO 🏛"
		h_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		h_lbl.add_theme_font_size_override("font_size", 20)
		header_panel.add_child(h_lbl)
		preview_vbox.add_child(header_panel)
		
	# 2. Hero Banner
	if chk_hero.button_pressed:
		active_count += 1
		var hero_panel = PanelContainer.new()
		var hero_style = StyleBoxFlat.new()
		hero_style.bg_color = Color(0.12, 0.14, 0.18, 1)
		hero_style.set_content_margin_all(18)
		hero_panel.add_theme_stylebox_override("panel", hero_style)
		
		var hero_lbl = Label.new()
		hero_lbl.text = "«La vera pizza napoletana con il cuore sabaudo, cotta nel nostro forno a legna dal 1994»\nIngredienti a km 0 e farina macinata a pietra."
		hero_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hero_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hero_panel.add_child(hero_lbl)
		preview_vbox.add_child(hero_panel)
		
	# 3. Pizza Menu Showcase
	if chk_menu.button_pressed:
		active_count += 1
		var menu_panel = PanelContainer.new()
		var m_style = StyleBoxFlat.new()
		m_style.bg_color = Color(0.16, 0.18, 0.24, 1)
		m_style.set_content_margin_all(14)
		menu_panel.add_theme_stylebox_override("panel", m_style)
		
		var m_text = RichTextLabel.new()
		m_text.bbcode_enabled = true
		m_text.fit_content = true
		m_text.text = "[center][b][color=#ffcc44]LE NOSTRE SPECIALITÀ[/color][/b][/center]\n\n"
		m_text.text += "• [b]Margherita Verace:[/b] Pomodoro San Marzano DOP, Mozzarella di Bufala, Basilico fresco - [b]€ 7,50[/b]\n"
		m_text.text += "• [b]Diavola del Po:[/b] Salame piccante, Fiordilatte, Peperoncino calabrese - [b]€ 9,00[/b]\n"
		m_text.text += "• [b]Piemontese DOC:[/b] Crema di tartufo, Funghi porcini trifolati, Salsiccia di Bra - [b]€ 12,00[/b]"
		menu_panel.add_child(m_text)
		preview_vbox.add_child(menu_panel)
		
	# 4. Opening Hours & Location
	if chk_hours.button_pressed:
		active_count += 1
		var hours_panel = PanelContainer.new()
		var hr_style = StyleBoxFlat.new()
		hr_style.bg_color = Color(0.12, 0.15, 0.20, 1)
		hr_style.set_content_margin_all(12)
		hours_panel.add_theme_stylebox_override("panel", hr_style)
		
		var hr_text = RichTextLabel.new()
		hr_text.bbcode_enabled = true
		hr_text.fit_content = true
		hr_text.text = "[center]📍 [b]Indirizzo:[/b] Via Po 18, Torino (Centro Storico) | 📞 Tel: 011 555 4321\n🕒 [b]Orari:[/b] Martedì - Domenica: 12:00 - 15:00 / 19:00 - 23:30 (Lunedì Chiuso)[/center]"
		hours_panel.add_child(hr_text)
		preview_vbox.add_child(hours_panel)
		
	# 5. Booking / Reservation CTA Button
	if chk_booking.button_pressed:
		active_count += 1
		var btn_panel = PanelContainer.new()
		var b_style = StyleBoxFlat.new()
		b_style.bg_color = current_theme_color
		b_style.set_content_margin_all(12)
		btn_panel.add_theme_stylebox_override("panel", b_style)
		
		var cta = Button.new()
		cta.text = "➔ PRENOTA UN TAVOLO O ORDINA PER ASPORTO ONLINE"
		cta.add_theme_font_size_override("font_size", 15)
		btn_panel.add_child(cta)
		preview_vbox.add_child(btn_panel)
		
	# Update Quality & Completion calculation
	var quality_percent = float(active_count) / 5.0 * 100.0
	quality_progress.value = quality_percent
	quality_label.text = "Completezza Requisiti: %d%% (%d / 5 Componenti)" % [int(quality_percent), active_count]
	
	if active_count == 5:
		compile_btn.disabled = false
		compile_btn.text = "✔ Compila Build e Prepara Consegna per Mario (€ 650,00)"
	else:
		compile_btn.disabled = true
		compile_btn.text = "Inserisci tutti i 5 requisiti richiesti da Mario (%d/5)" % active_count

func _on_compile_pressed() -> void:
	SoundManager.play_ui_success()
	var result_data = {
		"theme": current_theme_color.to_html(),
		"quality": 100.0,
		"components": ["header", "hero", "menu", "hours", "booking"]
	}
	ContractManager.mark_tutorial_website_built(result_data)
	visible = false
	EventBus.minigame_completed.emit(100.0, result_data)
