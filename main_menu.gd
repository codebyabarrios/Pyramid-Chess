extends Control

@export var main_game_path : String = "res://scenes/main.tscn"

@onready var start_menu = $HomeMenu
@onready var player_count_menu = $MenuQuantity
@onready var side_selection_menu = $SideMenu

var time_menu: CenterContainer
var difficulty_menu: CenterContainer # 🔴 Nuevo contenedor para la dificultad
var pixel_font = preload("res://PressStart2P.ttf") 

func _ready() -> void:
	AudioManager.play_main_menu()
	
	if start_menu != null: start_menu.show()
	if player_count_menu != null: player_count_menu.hide()
	if side_selection_menu != null: side_selection_menu.hide()
		
	_build_difficulty_ui() # 🔴 Construimos el nuevo menú
	_build_time_selection_ui()

func _on_play_button_pressed() -> void:
	start_menu.visible = false
	player_count_menu.visible = true

func _on_exit_button_pressed() -> void:
	get_tree().quit()

func _on_btn_2_players_pressed() -> void:
	Global.total_players = 2
	# 🔴 Ahora 2 Jugadores te lleva primero a la dificultad
	_show_difficulty_menu(player_count_menu) 

func _on_btn_1_player_pressed() -> void:
	Global.total_players = 1
	player_count_menu.visible = false
	side_selection_menu.visible = true

func _on_btn_white_rider_pressed() -> void:
	Global.selected_side = "white"
	_show_time_menu(side_selection_menu) 

func _on_btn_black_rider_pressed() -> void:
	Global.selected_side = "black"
	_show_time_menu(side_selection_menu)

func _on_btn_back_pressed() -> void:
	side_selection_menu.visible = false
	player_count_menu.visible = true


# --- MENÚ DE DIFICULTAD ---

func _show_difficulty_menu(menu_to_hide: Control) -> void:
	if menu_to_hide: menu_to_hide.visible = false
	difficulty_menu.visible = true

func _build_difficulty_ui():
	difficulty_menu = CenterContainer.new()
	difficulty_menu.hide()
	difficulty_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(difficulty_menu)
	
	var panel = PanelContainer.new()
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color("#111111", 0.95)
	panel_style.border_width_left = 4
	panel_style.border_width_top = 4
	panel_style.border_width_right = 4
	panel_style.border_width_bottom = 4
	panel_style.border_color = Color("#ffffff")
	panel_style.set_corner_radius_all(6)
	panel_style.content_margin_left = 30
	panel_style.content_margin_right = 30
	panel_style.content_margin_top = 25
	panel_style.content_margin_bottom = 25
	panel.add_theme_stylebox_override("panel", panel_style)
	difficulty_menu.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "CHOOSE DIFFICULTY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var title_settings = LabelSettings.new()
	title_settings.font = pixel_font
	title_settings.font_size = 22
	title_settings.font_color = Color("#ffffff")
	title_settings.outline_size = 4
	title_settings.outline_color = Color(0,0,0)
	title.label_settings = title_settings
	vbox.add_child(title)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox)
	
	_add_difficulty_button(hbox, "EASY", "ARCADE\nBUFFS", "easy", Color("#00ffff"))
	_add_difficulty_button(hbox, "MEDIUM", "STAMINA\nTACTIC", "medium", Color("#00ff00"))
	_add_difficulty_button(hbox, "HARD", "SURVIVAL\nFRENZY", "hard", Color("#ff0000"))
	
	var back_btn = Button.new()
	back_btn.text = "BACK"
	back_btn.custom_minimum_size = Vector2(160, 40)
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_btn.add_theme_font_override("font", pixel_font)
	back_btn.add_theme_font_size_override("font_size", 14)
	back_btn.add_theme_color_override("font_color", Color("#a0a0a0"))
	
	var back_style = StyleBoxFlat.new()
	back_style.bg_color = Color("#1e1e1e")
	back_style.border_width_bottom = 4
	back_style.border_color = Color("#000000")
	back_btn.add_theme_stylebox_override("normal", back_style)
	
	var back_hover = back_style.duplicate()
	back_hover.bg_color = Color("#333333")
	back_hover.border_color = Color("#666666")
	back_btn.add_theme_stylebox_override("hover", back_hover)
	
	back_btn.pressed.connect(func():
		difficulty_menu.hide()
		player_count_menu.show() 
	)
	vbox.add_child(back_btn)

func _add_difficulty_button(container: HBoxContainer, diff_label: String, subtitle: String, level_value: String, color: Color):
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(150, 90)
	btn.text = diff_label + "\n\n" + subtitle
	
	btn.add_theme_font_override("font", pixel_font)
	btn.add_theme_font_size_override("font_size", 12)
	btn.add_theme_color_override("font_color", color)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color("#1a1a1a")
	normal_style.border_width_bottom = 4
	normal_style.border_color = color.darkened(0.4)
	normal_style.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", normal_style)
	
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = Color("#2a2a2a")
	hover_style.border_color = color
	btn.add_theme_stylebox_override("hover", hover_style)
	
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = color.darkened(0.6)
	pressed_style.border_width_bottom = 1
	pressed_style.border_width_top = 3
	btn.add_theme_stylebox_override("pressed", pressed_style)
	
	btn.pressed.connect(func():
		Global.difficulty = level_value
		_show_time_menu(difficulty_menu)
	)
	container.add_child(btn)


func _show_time_menu(menu_to_hide: Control) -> void:
	if menu_to_hide: menu_to_hide.visible = false
	time_menu.visible = true

func _build_time_selection_ui():
	time_menu = CenterContainer.new()
	time_menu.hide()
	time_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(time_menu)
	
	var panel = PanelContainer.new()
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color("#111111", 0.95)
	panel_style.border_width_left = 4
	panel_style.border_width_top = 4
	panel_style.border_width_right = 4
	panel_style.border_width_bottom = 4
	panel_style.border_color = Color("#ffffff")
	panel_style.set_corner_radius_all(6)
	panel_style.content_margin_left = 30
	panel_style.content_margin_right = 30
	panel_style.content_margin_top = 25
	panel_style.content_margin_bottom = 25
	panel.add_theme_stylebox_override("panel", panel_style)
	time_menu.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "SELECT TIME"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var title_settings = LabelSettings.new()
	title_settings.font = pixel_font
	title_settings.font_size = 22
	title_settings.font_color = Color("#ffd700")
	title_settings.outline_size = 4
	title_settings.outline_color = Color(0,0,0)
	title.label_settings = title_settings
	vbox.add_child(title)
	
	var grid = GridContainer.new()
	grid.columns = 3 
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(grid)
	
	_add_time_button(grid, "15 SEC", "BULLET", 15.0, 0.0, Color("#ff4d4d"))
	_add_time_button(grid, "30 SEC", "BULLET", 30.0, 0.0, Color("#ff4d4d"))
	_add_time_button(grid, "1 MIN", "BULLET", 60.0, 0.0, Color("#ff4d4d"))
	_add_time_button(grid, "3 MIN", "BLITZ", 180.0, 0.0, Color("#ffd700"))
	_add_time_button(grid, "3 + 2", "BLITZ", 180.0, 2.0, Color("#ffd700")) 
	_add_time_button(grid, "5 MIN", "BLITZ", 300.0, 0.0, Color("#ffd700"))
	_add_time_button(grid, "5 + 3", "RAPID", 300.0, 3.0, Color("#00ff00")) 
	_add_time_button(grid, "10 MIN", "RAPID", 600.0, 0.0, Color("#00ff00"))
	_add_time_button(grid, "30 MIN", "CLASSIC", 1800.0, 0.0, Color("#00ffff"))
	
	var dark_mode_btn = CheckButton.new()
	dark_mode_btn.text = "DARK MODE"
	dark_mode_btn.button_pressed = Global.is_dark_mode_active
	var dm_settings = LabelSettings.new()
	dm_settings.font = load("res://PressStart2P.ttf")
	
	var temp_label = Label.new()
	temp_label.label_settings = dm_settings
	dark_mode_btn.add_theme_font_override("font", temp_label.label_settings.font)
	dark_mode_btn.add_theme_font_size_override("font_size", 18)
	
	dark_mode_btn.toggled.connect(func(toggled_on: bool):
		Global.is_dark_mode_active = toggled_on
	)
	vbox.add_child(dark_mode_btn)
	
	var back_btn = Button.new()
	back_btn.text = "BACK"
	back_btn.custom_minimum_size = Vector2(160, 40)
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_btn.add_theme_font_override("font", pixel_font)
	back_btn.add_theme_font_size_override("font_size", 14)
	back_btn.add_theme_color_override("font_color", Color("#a0a0a0"))
	
	var back_style = StyleBoxFlat.new()
	back_style.bg_color = Color("#1e1e1e")
	back_style.border_width_bottom = 4
	back_style.border_color = Color("#000000")
	back_btn.add_theme_stylebox_override("normal", back_style)
	
	var back_hover = back_style.duplicate()
	back_hover.bg_color = Color("#333333")
	back_hover.border_color = Color("#666666")
	back_btn.add_theme_stylebox_override("hover", back_hover)
	
	back_btn.pressed.connect(func():
		time_menu.hide()
		# 🔴 Volvemos al menú correcto dependiendo del modo
		if Global.total_players == 1:
			side_selection_menu.show()
		else:
			difficulty_menu.show() 
	)
	vbox.add_child(back_btn)

func _add_time_button(grid: GridContainer, time_label: String, category: String, seconds: float, increment: float, color: Color):
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(130, 75)
	btn.text = time_label + "\n\n" + category
	
	btn.add_theme_font_override("font", pixel_font)
	btn.add_theme_font_size_override("font_size", 12)
	btn.add_theme_color_override("font_color", color)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color("#1a1a1a")
	normal_style.border_width_bottom = 4
	normal_style.border_color = color.darkened(0.4)
	normal_style.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", normal_style)
	
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = Color("#2a2a2a")
	hover_style.border_color = color
	btn.add_theme_stylebox_override("hover", hover_style)
	
	var pressed_style = normal_style.duplicate()
	pressed_style.bg_color = color.darkened(0.6)
	pressed_style.border_width_bottom = 1
	pressed_style.border_width_top = 3
	btn.add_theme_stylebox_override("pressed", pressed_style)
	
	btn.pressed.connect(_start_game_with_time.bind(seconds, increment))
	grid.add_child(btn)

func _start_game_with_time(seconds: float, increment: float):
	Gamemanager.tiempo_inicial_seleccionado = seconds
	Gamemanager.incremento_seleccionado = increment
	Gamemanager.reset_game() 
	get_tree().change_scene_to_file(main_game_path)
