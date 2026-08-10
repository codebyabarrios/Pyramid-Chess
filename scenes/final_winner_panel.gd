extends CanvasLayer

@onready var title_label = $PanelContainer/VBoxContainer/TitleLabel
@onready var motif_label = $PanelContainer/VBoxContainer/MotifLabel
@onready var time_record_label = $PanelContainer/VBoxContainer/TimeManagementLabel

@onready var points_j1_node = $PanelContainer/VBoxContainer/GridContainer.get_child(0) as Label
@onready var points_j2_node = $PanelContainer/VBoxContainer/GridContainer.get_child(1) as Label
@onready var rounds_j1_node = $PanelContainer/VBoxContainer/GridContainer.get_child(2) as Label
@onready var rounds_j2_node = $PanelContainer/VBoxContainer/GridContainer.get_child(3) as Label

@onready var menu_btn = $PanelContainer/VBoxContainer/HBoxContainer/MenuButton

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide() 
	
	if is_instance_valid(menu_btn):
		menu_btn.process_mode = Node.PROCESS_MODE_ALWAYS
		menu_btn.text = "MAIN MENU"
		if not menu_btn.pressed.is_connected(_on_menu_pressed):
			menu_btn.pressed.connect(_on_menu_pressed)

func show_final_stats():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	var panel = $PanelContainer
	if is_instance_valid(panel):
		panel.custom_minimum_size = Vector2(340, 240)
		panel.size = Vector2(340, 240)
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color("#222222")
		style.border_width_left = 3
		style.border_width_top = 3
		style.border_width_right = 3
		style.border_width_bottom = 3
		style.border_color = Color("#ffffff")
		style.set_corner_radius_all(4)
		panel.add_theme_stylebox_override("panel", style)
		
		panel.anchor_left = 0.5
		panel.anchor_top = 0.5
		panel.anchor_right = 0.5
		panel.anchor_bottom = 0.5
		
		panel.offset_left = -(panel.size.x / 2)
		panel.offset_right = (panel.size.x / 2)
		panel.offset_top = -(panel.size.y / 2)
		panel.offset_bottom = (panel.size.y / 2)
		
	var vbox = find_child("VBoxContainer", true, false) as VBoxContainer
	if is_instance_valid(vbox):
		vbox.add_theme_constant_override("separation", 35) 
		
	var grid = find_child("GridContainer", true, false)
	if is_instance_valid(grid):
		grid.add_theme_constant_override("h_separation", 60) 
		grid.add_theme_constant_override("v_separation", 25) 
	var pixel_font = load("res://PressStart2P.ttf")
	
	if is_instance_valid(title_label):
		title_label.text = "THE GRAND FINAL"
		var settings = LabelSettings.new()
		settings.font = pixel_font
		settings.font_size = 36 
		settings.font_color = Color("#ffd700") 
		settings.outline_size = 6
		settings.outline_color = Color(0,0,0)
		title_label.label_settings = settings
		
	var r1 = Gamemanager.rounds_won_p1
	var r2 = Gamemanager.rounds_won_p2
	var grand_winner = "PLAYER 1" if r1 > r2 else "PLAYER 2"
	
	if r1 == r2:
		if Gamemanager.total_points_p1 > Gamemanager.total_points_p2:
			grand_winner = "PLAYER 1"
		elif Gamemanager.total_points_p2 > Gamemanager.total_points_p1:
			grand_winner = "PLAYER 2"
		else:
			grand_winner = "PERFECT TIE"

	if is_instance_valid(motif_label):
		motif_label.text = "🏆 FINAL WINNER: %s 🏆\n(THREE ROUNDS COMPLETED)" % grand_winner
		var settings = LabelSettings.new()
		settings.font = pixel_font
		settings.font_size = 20 
		settings.font_color = Color("#00ff00") 
		settings.outline_size = 4
		settings.outline_color = Color(0,0,0)
		motif_label.label_settings = settings
		
	var labels_medio = [points_j1_node, points_j2_node, rounds_j1_node, rounds_j2_node]
	for lbl in labels_medio:
		if is_instance_valid(lbl):
			var settings = LabelSettings.new()
			settings.font = pixel_font
			settings.font_size = 18 
			settings.font_color = Color("#ffffff") 
			settings.outline_size = 4
			settings.outline_color = Color(0,0,0)
			lbl.label_settings = settings
	
	if is_instance_valid(points_j1_node): points_j1_node.text = "P1 TOTAL: %s PTS" % Gamemanager.format_points(Gamemanager.total_points_p1)
	if is_instance_valid(points_j2_node): points_j2_node.text = "P2 TOTAL: %s PTS" % Gamemanager.format_points(Gamemanager.total_points_p2)
	if is_instance_valid(rounds_j1_node): rounds_j1_node.text = "P1 ROUNDS: %d" % r1
	if is_instance_valid(rounds_j2_node): rounds_j2_node.text = "P2 ROUNDS: %d" % r2
	
	if is_instance_valid(time_record_label):
		var t1 = Gamemanager.best_time_p1
		var t2 = Gamemanager.best_time_p2
		var speed_king = "PLAYER 1" if t1 > t2 else "PLAYER 2"
		var record_time = t1 if t1 > t2 else t2
		
		time_record_label.text = "⚡ SPEED RECORD: %s (%s)" % [speed_king, format_time(record_time)]
		var settings = LabelSettings.new()
		settings.font = pixel_font
		settings.font_size = 16
		settings.font_color = Color("#00ffff")
		settings.outline_size = 4
		settings.outline_color = Color(0,0,0)
		time_record_label.label_settings = settings
		
	show()
	animate_entry()

func format_time(seconds: float) -> String:
	var minutes := int(seconds) / 60
	var segs := int(seconds) % 60
	return "%02d:%02d" % [minutes, segs]

func animate_entry():
	var panel = $PanelContainer
	if is_instance_valid(panel):
		panel.pivot_offset = panel.size / 2
		panel.scale = Vector2(1.2, 1.2)
		
		var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.bind_node(self)
		tween.tween_property(panel, "scale", Vector2(1.5, 1.5), 0.4)

func _on_menu_pressed():
	Gamemanager._on_menu_button_pressed()
