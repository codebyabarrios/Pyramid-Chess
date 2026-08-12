extends Node

var white_points: float = 10.0
var black_points: float = 10.0

var tiempo_inicial_seleccionado: float = 180.0 
var incremento_seleccionado: float = 0.0 

var active_game: bool = false
var current_board: int = 1
const MAX_BOARDS: int = 3

var _tiempo_real_blancas: float = 180.0
var _tiempo_real_negras: float = 180.0

var white_time_left: float:
	get: return _tiempo_real_blancas
	set(_val): pass 

var black_time_left: float:
	get: return _tiempo_real_negras
	set(_val): pass

var white_clock_active: bool = true
var black_clock_active: bool = true

var kings_captured_this_round: int = 0
var is_changing_board: bool = false
var is_game_over_triggered: bool = false

var total_points_p1: float = 0.0
var total_points_p2: float = 0.0
var rounds_won_p1: int = 0
var rounds_won_p2: int = 0	
var best_time_p1: float = 0.0
var best_time_p2: float = 0.0

var _timer_acumulador: float = 0.0

func _ready() -> void:
	if get_parent() != get_tree().root:
		queue_free()
		return
		
	for child in get_children():
		if child is Timer:
			child.queue_free()

func _process(delta: float) -> void:
	if not active_game or is_game_over_triggered:
		_timer_acumulador = 0.0
		return
		
	_timer_acumulador += delta
	
	if _timer_acumulador >= 1.0:
		_timer_acumulador -= 1.0 
		
		var time_ended = false
		if white_clock_active and _tiempo_real_blancas > 0:
			_tiempo_real_blancas -= 1.0
			if _tiempo_real_blancas <= 0:
				_tiempo_real_blancas = 0
				white_clock_active = false
				time_ended = true

		if black_clock_active and _tiempo_real_negras > 0:
			_tiempo_real_negras -= 1.0
			if _tiempo_real_negras <= 0:
				_tiempo_real_negras = 0
				black_clock_active = false
				time_ended = true

		if time_ended and not is_game_over_triggered:
			_time_ran_out()

func _time_ran_out() -> void:
	if is_game_over_triggered: return
	is_game_over_triggered = true
	active_game = false
	
	for i in range(1, 4):
		var board_node = get_tree().current_scene.get_node_or_null("Board2D_" + str(i))
		if board_node: board_node.process_mode = Node.PROCESS_MODE_DISABLED
	
	if white_points > black_points: rounds_won_p1 += 1
	elif black_points > white_points: rounds_won_p2 += 1
	else:
		if _tiempo_real_blancas > _tiempo_real_negras: rounds_won_p1 += 1
		elif _tiempo_real_negras > _tiempo_real_blancas: rounds_won_p2 += 1
	
	if _tiempo_real_blancas > best_time_p1: best_time_p1 = _tiempo_real_blancas
	if _tiempo_real_negras > best_time_p2: best_time_p2 = _tiempo_real_negras
	
	total_points_p1 += white_points
	total_points_p2 += black_points
	
	_trigger_panel_display("Time Out!")

func process_capture(piece_type: String, same_color: bool, rider_color: String, _rider_node: Node2D = null):
	if rider_color == "white":
		_tiempo_real_blancas += incremento_seleccionado
	else:
		_tiempo_real_negras += incremento_seleccionado

	var current_points: float = white_points if rider_color == "white" else black_points
	var text_to_display: String = ""
	var visual_color = Color("#ffffff")
	
	match piece_type:
		"pawn":
			if not same_color: 
				current_points += 1; text_to_display = "+1"; visual_color = Color("#00ff00")
			else:
				current_points -= 1; text_to_display = "-1"; visual_color = Color("#ff4d4d")
		"knight":
			if not same_color:
				current_points *= 2; text_to_display = "x2"; visual_color = Color("#00ffff")
			else:
				current_points /= 2; text_to_display = "÷2"; visual_color = Color("#ff4d4d") 
		"bishop":
			if not same_color:
				current_points *= 3; text_to_display = "x3"; visual_color = Color("#e2925b")
			else:
				current_points /= 3; text_to_display = "÷3"; visual_color = Color("#ff4d4d")
		"rook":
			if not same_color:
				current_points = pow(current_points, 2); text_to_display = "X²"; visual_color = Color("#ffd700")
			else:
				current_points = sqrt(current_points); text_to_display = "√"; visual_color = Color("#ff00ff")
		"queen":
			if not same_color:
				current_points = pow(current_points, 3); text_to_display = "X³"; visual_color = Color("#ffd700")
			else:
				current_points = pow(current_points, 1.0 / 3.0); text_to_display = "³√"; visual_color = Color("#ff00ff")
		"king":
			if not same_color:
				if is_changing_board or is_game_over_triggered: return
				current_points += 100; text_to_display = "FINISH!"; visual_color = Color("#ffd700")
				if rider_color == "white":
					white_points = current_points; white_clock_active = false
				else:
					black_points = current_points; black_clock_active = false
				
				kings_captured_this_round += 1
				
				var required_captures = 1 if Global.total_players == 1 else 2
				
				if kings_captured_this_round >= required_captures:
					kings_captured_this_round = 0
					is_game_over_triggered = true
					active_game = false
					total_points_p1 += white_points
					total_points_p2 += black_points
					
					if white_points > black_points: rounds_won_p1 += 1
					elif black_points > white_points: rounds_won_p2 += 1
					else:
						if _tiempo_real_blancas > _tiempo_real_negras: rounds_won_p1 += 1
						elif _tiempo_real_negras > _tiempo_real_blancas: rounds_won_p2 += 1
					
					if _tiempo_real_blancas > best_time_p1: best_time_p1 = _tiempo_real_blancas
					if _tiempo_real_negras > best_time_p2: best_time_p2 = _tiempo_real_negras
					
					for i in range(1, 4):
						var board_node = get_tree().current_scene.get_node_or_null("Board2D_" + str(i))
						if board_node: board_node.process_mode = Node.PROCESS_MODE_DISABLED
					
					_trigger_panel_display("Kings Captured")
					return
	
	if current_points < 0: current_points = 0.0
	if rider_color == "white": white_points = current_points
	else: black_points = current_points
	
	var score_interface = get_tree().current_scene.find_child("ScoreInterface", true, false)
	if score_interface and score_interface.has_method("update_score_labels"):
		score_interface.update_score_labels()
		if text_to_display != "" and score_interface.has_method("add_operation_to_history"):
			current_points = round(current_points)
			var formatted_history = text_to_display + " -> " + format_points(current_points)
			score_interface.add_operation_to_history(rider_color, formatted_history, visual_color)
	
	if text_to_display != "": _spawn_floating_text(text_to_display, visual_color, rider_color)

func _trigger_panel_display(reason: String):
	var main_scene = get_tree().current_scene
	var panel = main_scene.find_child("*GameOverPan*", true, false)
	
	if panel != null:
		var winner_text = "Tiebreak Victory!"
		if white_points > black_points: winner_text = "Winner: White (By Points)"
		elif black_points > white_points: winner_text = "Winner: Black (By Points)"
		
		var stats = {
			"points_j1": white_points, "points_j2": black_points,
			"time_j1": _tiempo_real_blancas, "time_j2": _tiempo_real_negras,
			"current_board": current_board
		}
		
		panel.process_mode = Node.PROCESS_MODE_ALWAYS
		panel.visible = true
		if panel.has_method("show_game_over"):
			panel.show_game_over(winner_text, reason, stats)
	get_tree().paused = true

func _on_next_round_pressed() -> void:
	get_tree().paused = false
	
	var main_scene = get_tree().current_scene
	var panel = main_scene.find_child("*GameOverPan*", true, false)
	if panel != null:
		panel.hide()
	
	if current_board >= MAX_BOARDS:
		var final_panel = main_scene.find_child("*FinalWinnerPan*", true, false)
		if final_panel:
			final_panel.process_mode = Node.PROCESS_MODE_ALWAYS
			final_panel.visible = true
			if final_panel.has_method("show_final_stats"):
				final_panel.show_final_stats()
			get_tree().paused = true
		return
	
	is_changing_board = true
	active_game = false
	white_points = 10.0
	black_points = 10.0
	
	_tiempo_real_blancas = tiempo_inicial_seleccionado
	_tiempo_real_negras = tiempo_inicial_seleccionado
	
	white_clock_active = true
	black_clock_active = true
	kings_captured_this_round = 0 
	_timer_acumulador = 0.0
	
	var all_riders = get_tree().get_nodes_in_group("players")
	for rider in all_riders:
		if is_instance_valid(rider):
			rider.has_finished = false
			rider.is_riding_rank = false
			rider.direction = 0
			
	var score_interface = get_tree().current_scene.find_child("ScoreInterface", true, false)
	if is_instance_valid(score_interface):
		if score_interface.has_method("clear_history"):
			score_interface.clear_history()
		if score_interface.has_method("update_score_labels"):
			score_interface.update_score_labels()
			
	_teleport_rider_to_next_board()
	
	get_tree().create_timer(0.5).timeout.connect(func():
		is_changing_board = false
		is_game_over_triggered = false
	)

func _on_menu_button_pressed() -> void:
	get_tree().paused = false
	reset_game()
	get_tree().change_scene_to_file("res://MainMenu.tscn")

func _teleport_rider_to_next_board(_rider_color_target: String = ""):
	var main_scene = get_tree().current_scene
	var old_board = main_scene.get_node_or_null("Board2D_" + str(current_board))
	current_board += 1
	var new_board = main_scene.get_node_or_null("Board2D_" + str(current_board))
	
	if old_board and new_board:
		var riders = get_tree().get_nodes_in_group("players")
		for rider in riders:
			if is_instance_valid(rider) and rider.get_parent() == old_board:
				if old_board.has_method("remove_rider_from_matrix"): old_board.remove_rider_from_matrix(rider)
				rider.reparent(new_board)
				new_board.receive_rider(rider)
				
		var camera = main_scene.get_node_or_null("Camera2D")
		if camera and camera.has_method("move_to_board"): 
			camera.move_to_board(current_board)

func reset_game() -> void:
	white_points = 10.0
	black_points = 10.0
	active_game = false
	current_board = 1
	
	_tiempo_real_blancas = tiempo_inicial_seleccionado
	_tiempo_real_negras = tiempo_inicial_seleccionado
	
	white_clock_active = true
	black_clock_active = true
	kings_captured_this_round = 0
	is_changing_board = false
	is_game_over_triggered = false
	total_points_p1 = 0.0
	total_points_p2 = 0.0
	rounds_won_p1 = 0
	rounds_won_p2 = 0
	best_time_p1 = 0.0
	best_time_p2 = 0.0
	_timer_acumulador = 0.0

func restart_game_scene():
	get_tree().paused = false
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
	if is_nan(points) or points < 0.0: return "0"
	if is_inf(points): return "MAX"
	if points < 1000.0: return str(int(points))
	var suffixes = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]
	var index_suffix = 0
	var reduced_value = points
	while reduced_value >= 1000.0 and index_suffix < suffixes.size() - 1:
		reduced_value /= 1000.0
		index_suffix += 1
	return "%.1f" % reduced_value + suffixes[index_suffix]
