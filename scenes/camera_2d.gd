extends Camera2D

@export var mask_container: ColorRect
@export var board_focus_pos: Vector2 = Vector2(252.0, 310.0)
@export var board_zoom: Vector2 = Vector2(1.48, 1.48)

func _ready() -> void:
	limit_left = -1000000
	limit_top = -1000000
	limit_right = 1000000
	limit_bottom = 1000000
	
	make_current()
	enabled = true
	anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	
	global_position = board_focus_pos
	zoom = board_zoom
	
	var score_interface = get_tree().current_scene.find_child("ScoreInterface", true, false)
	if score_interface:
		score_interface.visible = false
		score_interface.modulate.a = 0.0
		
		var points_panel = score_interface.find_child("ControlDerecha", true, false)
		if points_panel == null:
			points_panel = score_interface.find_child("RightControl", true, false)
		if points_panel:
			points_panel.visible = false
			points_panel.modulate.a = 0.0
	
	if mask_container:
		mask_container.modulate.a = 1.0
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	if mask_container:
		tween.tween_property(mask_container, "modulate:a", 0.0, 0.5)
	else:
		tween.tween_interval(0.5)
	
	if score_interface:
		var points_panel = score_interface.find_child("ControlDerecha", true, false)
		if points_panel == null:
			points_panel = score_interface.find_child("RightControl", true, false)
		
		tween.tween_callback(func():
			score_interface.visible = true
			score_interface.modulate.a = 1.0
			
			if "white_clock_label" in score_interface and is_instance_valid(score_interface.white_clock_label): score_interface.white_clock_label.visible = false
			if "black_clock_label" in score_interface and is_instance_valid(score_interface.black_clock_label): score_interface.black_clock_label.visible = false
			if "white_hearts_box" in score_interface and is_instance_valid(score_interface.white_hearts_box): score_interface.white_hearts_box.visible = false
			if "black_hearts_box" in score_interface and is_instance_valid(score_interface.black_hearts_box): score_interface.black_hearts_box.visible = false
			if "white_energy_bar" in score_interface and is_instance_valid(score_interface.white_energy_bar): score_interface.white_energy_bar.visible = false
			if "black_energy_bar" in score_interface and is_instance_valid(score_interface.black_energy_bar): score_interface.black_energy_bar.visible = false
			
			if points_panel:
				points_panel.visible = false
		)
		
		var round_label = score_interface.find_child("RoundLabel", true, false)
		if round_label:
			tween.tween_callback(func():
				round_label.text = "3 ROUNDS\nBoard resets each round"
				round_label.modulate.a = 0.0
				round_label.visible = true
				round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				round_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				round_label.anchors_preset = Control.PRESET_CENTER
				round_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
				round_label.grow_vertical = Control.GROW_DIRECTION_BOTH
			)
			tween.tween_property(round_label, "modulate:a", 1.0, 0.25)
			tween.tween_interval(2.0)
			tween.tween_property(round_label, "modulate:a", 0.0, 0.25)
			
			_append_round_and_countdown(tween, round_label, 1)
		
		tween.tween_callback(func():
			if score_interface.has_method("_reposition_ui"):
				score_interface._reposition_ui()
		)
		
		if points_panel:
			tween.tween_callback(func():
				points_panel.visible = true
				points_panel.modulate.a = 0.0
			)
			tween.tween_property(points_panel, "modulate:a", 1.0, 0.5)
		
		tween.tween_callback(func():
			_activate_round_gameplay(score_interface, points_panel, 1)
		)

func _append_round_and_countdown(tween: Tween, round_label: Control, board_index: int) -> void:
	tween.tween_callback(func():
		round_label.text = "ROUND %d" % board_index
		round_label.modulate.a = 0.0
		round_label.visible = true
		round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		round_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		round_label.anchors_preset = Control.PRESET_CENTER
		round_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
		round_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	)
	
	tween.tween_property(round_label, "modulate:a", 1.0, 0.2)
	tween.tween_interval(1.2)
	tween.tween_property(round_label, "modulate:a", 0.0, 0.2)
	
	tween.tween_callback(func():
		AudioManager.play_countdown()
		round_label.text = "3"
		round_label.modulate.a = 0.0
	)
	tween.tween_property(round_label, "modulate:a", 1.0, 0.1)
	tween.tween_interval(0.75)
	tween.tween_property(round_label, "modulate:a", 0.0, 0.1)
	
	tween.tween_callback(func(): round_label.text = "2"; round_label.modulate.a = 0.0)
	tween.tween_property(round_label, "modulate:a", 1.0, 0.1)
	tween.tween_interval(0.75)
	tween.tween_property(round_label, "modulate:a", 0.0, 0.1)
	
	tween.tween_callback(func(): round_label.text = "1"; round_label.modulate.a = 0.0)
	tween.tween_property(round_label, "modulate:a", 1.0, 0.1)
	tween.tween_interval(0.75)
	tween.tween_property(round_label, "modulate:a", 0.0, 0.1)
	
	tween.tween_callback(func(): round_label.text = "PLAY!"; round_label.modulate.a = 0.0)
	tween.tween_property(round_label, "modulate:a", 1.0, 0.1)
	tween.tween_interval(0.6)
	tween.tween_property(round_label, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): round_label.visible = false)

func _activate_round_gameplay(score_interface: Node, points_panel: Node, board_index: int) -> void:
	get_tree().paused = false
	Gamemanager.is_game_over_triggered = false
	Gamemanager.is_changing_board = false
	Gamemanager.active_game = true
	
	if points_panel:
		points_panel.visible = true
		points_panel.modulate.a = 1.0
	
	Gamemanager.active_game = true
	
	if Global.total_players == 1:
		AudioManager.play_training()
	else:
		if Global.difficulty == "easy": AudioManager.play_easy()
		elif Global.difficulty == "medium": AudioManager.play_medium()
		elif Global.difficulty == "hard": AudioManager.play_hard()
	
	if "white_clock_label" in score_interface and is_instance_valid(score_interface.white_clock_label): score_interface.white_clock_label.visible = true
	if "black_clock_label" in score_interface and is_instance_valid(score_interface.black_clock_label): score_interface.black_clock_label.visible = true
	if "white_hearts_box" in score_interface and is_instance_valid(score_interface.white_hearts_box): score_interface.white_hearts_box.visible = true
	if "black_hearts_box" in score_interface and is_instance_valid(score_interface.black_hearts_box): score_interface.black_hearts_box.visible = true
	if "white_energy_bar" in score_interface and is_instance_valid(score_interface.white_energy_bar): score_interface.white_energy_bar.visible = true
	if "black_energy_bar" in score_interface and is_instance_valid(score_interface.black_energy_bar): score_interface.black_energy_bar.visible = true
	
	var board_node = _get_active_board(board_index)
	if board_node:
		board_node.process_mode = Node.PROCESS_MODE_INHERIT
		if "is_movement_active" in board_node:
			board_node.is_movement_active = true
		if board_node.has_method("activate_piece_movement"):
			board_node.activate_piece_movement()
		board_node.set_process(true)
	
	score_interface.set_process(true)

func _get_active_board(board_index: int) -> Node:
	var main_scene = get_tree().current_scene
	if not main_scene:
		return null
	var target = main_scene.get_node_or_null("Board2D_" + str(board_index))
	if target:
		return target
	return main_scene.get_node_or_null("Board2D_1")

func play_round_countdown(board_index: int) -> void:
	var score_interface = get_tree().current_scene.find_child("ScoreInterface", true, false)
	if not score_interface:
		return
	
	score_interface.visible = true
	score_interface.modulate.a = 1.0
	
	var round_label = score_interface.find_child("RoundLabel", true, false)
	var points_panel = score_interface.find_child("ControlDerecha", true, false)
	if points_panel == null:
		points_panel = score_interface.find_child("RightControl", true, false)
	
	if points_panel:
		points_panel.visible = false
		points_panel.modulate.a = 0.0
	
	if "white_clock_label" in score_interface and is_instance_valid(score_interface.white_clock_label): score_interface.white_clock_label.visible = false
	if "black_clock_label" in score_interface and is_instance_valid(score_interface.black_clock_label): score_interface.black_clock_label.visible = false
	if "white_hearts_box" in score_interface and is_instance_valid(score_interface.white_hearts_box): score_interface.white_hearts_box.visible = false
	if "black_hearts_box" in score_interface and is_instance_valid(score_interface.black_hearts_box): score_interface.black_hearts_box.visible = false
	if "white_energy_bar" in score_interface and is_instance_valid(score_interface.white_energy_bar): score_interface.white_energy_bar.visible = false
	if "black_energy_bar" in score_interface and is_instance_valid(score_interface.black_energy_bar): score_interface.black_energy_bar.visible = false
	
	if round_label:
		var tween = create_tween()
		_append_round_and_countdown(tween, round_label, board_index)
		
		tween.tween_callback(func():
			if score_interface.has_method("_reposition_ui"):
				score_interface._reposition_ui()
		)
		
		if points_panel:
			tween.tween_callback(func():
				points_panel.visible = true
				points_panel.modulate.a = 0.0
			)
			tween.tween_property(points_panel, "modulate:a", 1.0, 0.5)
		
		tween.tween_callback(func():
			_activate_round_gameplay(score_interface, points_panel, board_index)
		)

func move_to_board(board_index: int) -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "global_position", board_focus_pos, 0.6)
	tween.tween_callback(func(): play_round_countdown(board_index))

func _on_pause_menu_2_pressed() -> void:
	pass
