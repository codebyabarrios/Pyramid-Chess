extends Node

var white_points: float = 10.0
var black_points: float = 10.0

const FLOATING_TEXT_SCENE = preload("res://FloatingText.tscn")

var active_game: bool = false
var current_board: int = 1
const MAX_BOARDS: int = 3

var white_time_left: float = 180.0
var black_time_left: float = 180.0

var white_clock_active: bool = true
var black_clock_active: bool = true

var kings_captured_this_round: int = 0

var is_changing_board: bool = false

func _ready() -> void:
	pass

func reset_game() -> void:
	white_points = 10.0
	black_points = 10.0
	active_game = true
	current_board = 1
	
	white_time_left = 180.0
	black_time_left = 180.0
	white_clock_active = true
	black_clock_active = true
	
	kings_captured_this_round = 0
	is_changing_board = false

func process_capture(piece_type: String, same_color: bool, rider_color: String, rider_node: Node2D = null):
	var current_points: float = white_points if rider_color == "white" else black_points
	var text_to_display: String = ""
	var visual_color = Color("#ffffff")
	
	match piece_type:
		"pawn":
			if not same_color: 
				current_points += 1
				text_to_display = "+1"
				visual_color = Color("#00ff00")
			else:
				current_points -= 1
				text_to_display = "-1"
				visual_color = Color("#ff4d4d")
		"knight":
			if not same_color:
				current_points *= 2
				text_to_display = "x2"
				visual_color = Color("#00ffff")
			else:
				current_points /= 2
				text_to_display = "÷2"
				visual_color = Color("#ff4d4d") 
		"bishop":
			if not same_color:
				current_points *= 3
				text_to_display = "x3"
				visual_color = Color("#e2925b")
			else:
				current_points /= 3
				text_to_display = "÷3"
				visual_color = Color("#ff4d4d")
		"rook":
			if not same_color:
				current_points = pow(current_points, 2)
				text_to_display = "X²"
				visual_color = Color("#ffd700")
			else:
				current_points = sqrt(current_points)
				text_to_display = "√"
				visual_color = Color("#ff00ff")
		"queen":
			if not same_color:
				current_points = pow(current_points, 3)
				text_to_display = "X³"
				visual_color = Color("#ffd700")
			else:
				current_points = pow(current_points, 1.0 / 3.0)
				text_to_display = "³√"
				visual_color = Color("#ff00ff")
		"king":
			if not same_color:
				if is_changing_board:
					return
				
				current_points += 100
				text_to_display = "FINISH!"
				visual_color = Color("#ffd700")
				
				if rider_color == "white":
					white_points = current_points
				else:
					black_points = current_points
				
				kings_captured_this_round += 1
				
				if kings_captured_this_round >= 2:
					kings_captured_this_round = 0
					
					active_game = false
						
					if rider_color == "white":
						white_points = current_points
					else:
						black_points = current_points
						
					var score_interface = get_tree().current_scene.find_child("ScoreInterface", true, false)
					if score_interface:
						if score_interface.has_method("update_score_labels"):
							score_interface.update_score_labels()
							
						if text_to_display != "" and score_interface.has_method("add_operation_to_history"):
							var formatted_history = text_to_display + " ->" + format_points(round(current_points))
							score_interface.add_operation_to_history(rider_color, formatted_history, visual_color)
							
						if score_interface.has_method("trigger_game_over"):
							score_interface.trigger_game_over("Kings Captured")
					return
					
					is_changing_board = true
					if current_board < MAX_BOARDS:
						white_points = 10.0
						black_points = 10.0
						white_time_left = 180.0
						black_time_left = 180.0
						white_clock_active = true
						black_clock_active = true
						
						var all_riders = get_tree().get_nodes_in_group("players")
						for rider in all_riders:
							if is_instance_valid(rider):
								rider.has_finished = false
								rider.is_riding_rank = false
								rider.direction = 0
						
						_teleport_rider_to_next_board()
						
						if score_interface:
							score_interface.set_process(true)
							if score_interface.has_method("update_score_labels"):
								score_interface.update_score_labels()
						
						get_tree().create_timer(0.5).timeout.connect(func():
							is_changing_board = false
						)
					
					else:
						active_game = false
						if score_interface and score_interface.has_method("trigger_game_over"):
							score_interface.trigger_game_over("Kings Captured")
	
	if current_points < 0:
		current_points = 0.0
	
	if rider_color == "white":
		white_points = current_points
	else:
		black_points = current_points
	
	var score_interface = get_tree().current_scene.find_child("ScoreInterface", true, false)
	if score_interface and score_interface.has_method("update_score_labels"):
		score_interface.update_score_labels()
		
		if text_to_display != "" and score_interface.has_method("add_operation_to_history"):
			current_points = round(current_points)
			var formatted_history = text_to_display + " -> " + format_points(current_points)
			score_interface.add_operation_to_history(rider_color, formatted_history, visual_color)
	
	if text_to_display != "":
		_spawn_floating_text(text_to_display, visual_color, rider_color)

func _teleport_rider_to_next_board(rider_color_target: String = ""):
	var main_scene = get_tree().current_scene
	var old_board = main_scene.get_node_or_null("Board2D_" + str(current_board))
	
	current_board += 1
	var new_board = main_scene.get_node_or_null("Board2D_" + str(current_board))
	
	if old_board and new_board:
		var riders = old_board.get_tree().get_nodes_in_group("players")
		for rider in riders:
			if is_instance_valid(rider) and rider.get_parent() == old_board:
				if old_board.has_method("remove_rider_from_matrix"):
					old_board.remove_rider_from_matrix(rider)
				
				rider.reparent(new_board)
				new_board.receive_rider(rider)
		
		var camera = main_scene.get_node_or_null("Camera2D")
		if camera and camera.has_method("move_to_board"):
			camera.move_to_board(current_board)
		
		if new_board.has_method("activate_piece_movement"):
			new_board.activate_piece_movement()
		
		new_board.set_process(true)

func _trigger_victory_menu():
	await get_tree().create_timer(1.5).timeout
	var score_interface = get_tree().current_scene.find_child("ScoreInterface", true, false) 
	if score_interface:
		if score_interface.has_method("trigger_game_over"):
			score_interface.trigger_game_over("Kings Captured")
	
	for i in range(1, 4):
		var board_node = get_tree().current_scene.get_node_or_null("Board2D_" + str(i))
		if board_node:
			board_node.process_mode = Node.PROCESS_MODE_DISABLED

func restart_game_scene():
	reset_game()
	get_tree().reload_current_scene()

func _spawn_floating_text(text_to_display: String, visual_color: Color, rider_color: String):
	var players = get_tree().get_nodes_in_group("players")
	var spawn_position = Vector2.ZERO
	for player in players:
		if "is_white" in player and player.is_white == (rider_color == "white"):
			spawn_position = player.global_position
			break
			
	var text_nodo = Label.new()
	text_nodo.text = text_to_display
	text_nodo.modulate = visual_color
	var settings = LabelSettings.new()
	settings.font = load("res://PressStart2P.ttf")
	settings.font_size = 30
	settings.font_color = visual_color
	settings.outline_size = 6
	settings.outline_color = Color(0, 0, 0)
	text_nodo.label_settings = settings
	
	text_nodo.top_level = true
	text_nodo.z_index = 100
	text_nodo.global_position = spawn_position + Vector2(-50, -40)
	
	get_tree().current_scene.add_child(text_nodo)
	
	var tween = get_tree().create_tween().set_parallel(true)
	tween.tween_property(text_nodo, "global_position:y", text_nodo.global_position.y - 60, 0.8)
	tween.tween_property(text_nodo, "modulate:a", 0.0, 0.8)
	tween.chain().tween_callback(text_nodo.queue_free)

func format_points(points: float) -> String:
	if is_nan(points) or points < 0.0:
		return "0"
	if is_inf(points):
		return "MAX"
	if points < 1000.0:
		return str(int(points))

	var suffixes = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]
	var index_suffix = 0
	var reduced_value = points
	while reduced_value >= 1000.0 and index_suffix < suffixes.size() - 1:
		reduced_value /= 1000.0
		index_suffix += 1
	return "%.1f" % reduced_value + suffixes[index_suffix]
