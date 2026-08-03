extends Control


@onready var game_over_menu = $GameOverMenu
@onready var white_score_label: Label = $RightControl/WhitePoints
@onready var black_score_label: Label = $RightControl/BlackPoints
@onready var white_history: VBoxContainer = $RightControl/WhiteHistory
@onready var black_history: VBoxContainer = $RightControl/BlackHistory

var is_transitioning: bool = false

var white_clock_label: Label = null
var black_clock_label: Label = null

func _ready():
	self.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	white_score_label = find_child("WhitePoints", true, false)
	black_score_label = find_child("BlackPoints", true, false)
	white_history = find_child("WhiteHistory", true, false)
	black_history = find_child("BlackHistory", true, false)

	if game_over_menu != null:
		game_over_menu.process_mode = Node.PROCESS_MODE_ALWAYS
		game_over_menu.visible = false
		
	var restart_button = game_over_menu.get_node_or_null("RestartButton")
	if restart_button and not restart_button.pressed.is_connected(_on_restart_button_pressed):
		restart_button.pressed.connect(_on_restart_button_pressed)
	
	white_clock_label = _create_ui_clock()
	black_clock_label = _create_ui_clock()
	add_child(white_clock_label)
	add_child(black_clock_label)
	
	move_child(white_clock_label, get_child_count() - 1)
	move_child(black_clock_label, get_child_count() - 1)
	
	await get_tree().process_frame
	update_score_labels()
	
	get_tree().root.size_changed.connect(_reposition_clocks)

func _process(_delta: float) -> void:
	if Gamemanager.active_game:
		
		if is_instance_valid(white_clock_label):
			var w_min = int(Gamemanager.white_time_left) / 60
			var w_sec = int(Gamemanager.white_time_left) % 60
			white_clock_label.text = "W: %02d:%02d" % [w_min, w_sec]
			
			if Gamemanager.white_time_left < 30.0:
				white_clock_label.label_settings.font_color = Color("#ff4d4d")
			else:
				white_clock_label.label_settings.font_color = Color("#e0e0e0")
		
		if is_instance_valid(black_clock_label):
			var b_min = int(Gamemanager.black_time_left) / 60
			var b_sec = int(Gamemanager.black_time_left) % 60
			black_clock_label.text = "B: %02d:%02d" % [b_min, b_sec]
			
			if Gamemanager.black_time_left < 30.0:
				black_clock_label.label_settings.font_color = Color("#ff4d4d")
			else:
				black_clock_label.label_settings.font_color = Color("#ffd700")
				
		if not Gamemanager.white_clock_active and not Gamemanager.black_clock_active and not is_transitioning:
			
			if Gamemanager.white_time_left <= 0.0 or Gamemanager.black_time_left <= 0.0:
				is_transitioning = true
				
				await get_tree().create_timer(2.5).timeout
				
				if Gamemanager.current_board < Gamemanager.MAX_BOARDS:
					Gamemanager.white_points = 10.0
					Gamemanager.black_points = 10.0
					
					Gamemanager.white_time_left = 180.0
					Gamemanager.black_time_left = 180.0 
					Gamemanager.white_clock_active = true
					Gamemanager.black_clock_active = true
					
					var all_riders = get_tree().get_nodes_in_group("players")
					for rider in all_riders:
						if is_instance_valid(rider):
							rider.has_finished = false
							rider.is_riding_rank = false
							rider.direction = 0
					
					set_process(false)
					
					Gamemanager._teleport_rider_to_next_board()
					
					update_score_labels()
					
					set_process(true)
					is_transitioning = false
					return
				
				else:
					get_tree().paused = true
					if game_over_menu != null:
						game_over_menu.process_mode = Node.PROCESS_MODE_ALWAYS
						game_over_menu.visible = true
		
func update_score_labels() -> void:
	if not is_instance_valid(white_score_label) or not is_instance_valid(black_score_label):
		return
		
	var white_text = Gamemanager.format_points(Gamemanager.white_points)
	var black_text = Gamemanager.format_points(Gamemanager.black_points)
	
	white_score_label.text = white_text + " pts"
	black_score_label.text = black_text + " pts"
	
		
func add_operation_to_history(rider_color: String, operation_text: String, text_color: Color) -> void:
	var target_container = white_history if rider_color == "white" else black_history
	if not is_instance_valid(target_container):
		return
		
	var history_item = Label.new()
	history_item.text = operation_text
	
	history_item.horizontal_alignment = 0
	history_item.grow_horizontal = 0
	
	var settings = LabelSettings.new()
	settings.font = load("res://PressStart2P.ttf")
	settings.font_size = 20 
	settings.font_color = text_color
	settings.outline_size = 4
	settings.outline_color = Color(0, 0, 0)
	history_item.label_settings = settings
	
	target_container.add_child(history_item)
	target_container.move_child(history_item, 0)
	
	if target_container.get_child_count() > 4:
		target_container.get_child(target_container.get_child_count() - 1).queue_free()

func show_end_game(attacking_rider: Node2D):
	pass

func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	Gamemanager.reset_game()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _create_ui_clock() -> Label:
	var label = Label.new()
	label.text = "03:00"
	
	var settings = LabelSettings.new()
	settings.font = load("res://PressStart2P.ttf")
	settings.font_size = 22
	settings.font_color = Color.WHITE
	settings.outline_size = 5
	settings.outline_color = Color.BLACK
	label.label_settings = settings
	
	return label

func _reposition_clocks() -> void:
	await get_tree().process_frame
	
	var ui_size = size
	var margin_left = 35.0
	var base_y = ui_size.y - 120.0
	
	if is_instance_valid(white_clock_label):
		white_clock_label.position = Vector2(margin_left, base_y)
		white_clock_label.visible = true
		white_clock_label.modulate.a = 1.0
		
	if is_instance_valid(black_clock_label):
		black_clock_label.position = Vector2(margin_left, base_y + 40.0)
		black_clock_label.visible = true
		black_clock_label.modulate.a = 1.0
	
	update_score_labels()
