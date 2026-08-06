extends Camera2D

@onready var mask_container: Control = $"../ScreenMask/MaskContainer"

func _ready() -> void:
	limit_left = -1000000
	limit_top = -1000000
	limit_right = 1000000
	limit_bottom = 1000000
	
	make_current()
	enabled = true
	anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	
	var board_1_pos = Vector2(252.0, 310.0)
	var board_2_pos = Vector2(762.0, 310.0)
	var board_3_pos = Vector2(1272.0, 310.0)
	
	var overview_pos_x: float = 762.0
	var overview_pos_y: float = 310.0
	
	var close_zoom = Vector2(1.48, 1.48)
	var far_zoom = Vector2(1.11, 1.11)
	
	global_position = board_1_pos
	zoom = close_zoom
	
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
	
	tween.tween_interval(1.0)
	
	tween.tween_property(self, "global_position", board_2_pos, 2.0)
	tween.tween_interval(0.4)
	
	tween.tween_property(self, "global_position", board_3_pos, 2.0)
	tween.tween_interval(0.4)
	
	tween.tween_property(self, "global_position:x", overview_pos_x, 1.5)
	tween.parallel().tween_property(self, "global_position:y", overview_pos_y, 1.5)
	tween.tween_interval(0.4)
	
	if mask_container:
		tween.tween_property(mask_container, "modulate:a", 0.0, 0.5)
		tween.parallel().tween_property(self, "zoom", far_zoom, 3.0)
	else:
		tween.tween_property(self, "zoom", far_zoom, 3.0)
	
	tween.tween_interval(3.0)
	
	if mask_container:
		tween.tween_property(mask_container, "modulate:a", 1.0, 0.4)
		tween.parallel().tween_property(self, "global_position", board_1_pos, 1.2)
		tween.parallel().tween_property(self, "zoom", close_zoom, 1.2)
	else:
		tween.tween_property(self, "global_position", board_1_pos, 1.2)
		tween.parallel().tween_property(self, "zoom", close_zoom, 1.2)
		
	if score_interface:
		var points_panel = score_interface.find_child("ControlDerecha", true, false)
		if points_panel == null:
			points_panel = score_interface.find_child("RightControl", true, false)
		
		tween.tween_callback(func():
			score_interface.visible = true
			score_interface.modulate.a = 1.0
			
			if "white_clock_label" in score_interface and score_interface.white_clock_label:
				score_interface.white_clock_label.visible = false
			if "black_clock_label" in score_interface and score_interface.black_clock_label:
				score_interface.black_clock_label.visible = false
			
			if points_panel:
				points_panel.visible = false
		)
		
		var round_label = score_interface.find_child("RoundLabel", true, false)
		if round_label:
			tween.tween_callback(func():
				round_label.text = "ROUND 1"
				round_label.modulate.a = 0.0
				round_label.visible = true
				round_label.horizontal_alignment = 1
				round_label.vertical_alignment = 1
				
				round_label.anchors_preset = Control.PRESET_CENTER
				round_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
				round_label.grow_vertical = Control.GROW_DIRECTION_BOTH
			)
			
			tween.tween_property(round_label, "modulate:a", 1.0, 0.2)
			tween.tween_interval(1.5)
			tween.tween_property(round_label, "modulate:a", 0.0, 0.2)
			
			tween.tween_callback(func():
				round_label.text = "3"
				round_label.modulate.a = 0.0
				round_label.horizontal_alignment = 1
				round_label.vertical_alignment = 1
				
				round_label.anchors_preset = Control.PRESET_CENTER
				round_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
				round_label.grow_vertical = Control.GROW_DIRECTION_BOTH
			)
			
			tween.tween_property(round_label, "modulate:a", 1.0, 0.1)
			tween.tween_interval(0.8)
			tween.tween_property(round_label, "modulate:a", 0.0, 0.1)
			
			tween.tween_callback(func():
				round_label.text = "2"
				round_label.modulate.a = 0.0
				round_label.horizontal_alignment = 1
				round_label.vertical_alignment = 1
				
				round_label.anchors_preset = Control.PRESET_CENTER
				round_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
				round_label.grow_vertical = Control.GROW_DIRECTION_BOTH
			)
			tween.tween_property(round_label, "modulate:a", 1.0, 0.1)
			tween.tween_interval(0.8)
			tween.tween_property(round_label, "modulate:a", 0.0, 0.1)
			
			tween.tween_callback(func():
				round_label.text = "1"
				round_label.modulate.a = 0.0
				round_label.horizontal_alignment = 1
				round_label.vertical_alignment = 1
				
				round_label.anchors_preset = Control.PRESET_CENTER
				round_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
				round_label.grow_vertical = Control.GROW_DIRECTION_BOTH
			)
			tween.tween_property(round_label, "modulate:a", 1.0, 0.1)
			tween.tween_interval(0.8)
			tween.tween_property(round_label, "modulate:a", 0.0, 0.1)
			
			tween.tween_callback(func():
				round_label.text = "PLAY!"
				round_label.modulate.a = 0.0
				round_label.horizontal_alignment = 1
				round_label.vertical_alignment = 1
				
				round_label.anchors_preset = Control.PRESET_CENTER
				round_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
				round_label.grow_vertical = Control.GROW_DIRECTION_BOTH
			)
			tween.tween_property(round_label, "modulate:a", 1.0, 0.1)
			tween.tween_interval(0.6)
			tween.tween_property(round_label, "modulate:a", 0.0, 0.2)
			tween.tween_callback(func(): round_label.visible = false)
		
		tween.tween_callback(func():
			if score_interface.has_method("_reposition_clocks"):
				score_interface._reposition_clocks()
		)
		
		if points_panel:
			tween.tween_callback(func():
				points_panel.visible = true
				points_panel.modulate.a = 0.0
			)
			tween.tween_property(points_panel, "modulate:a", 1.0, 0.5)
		
		tween.tween_callback(func():
			Gamemanager.active_game = true
			
			var board_1 = get_tree().current_scene.get_node_or_null("Board2D_1")
			if board_1:
				board_1.is_movement_active = true
				board_1.set_process(true)
			
			score_interface.set_process(true)
		)
		
func move_to_board(board_index: int) -> Signal:
	var target_position = global_position
	
	match board_index:
		1:
			target_position = Vector2(252.0, 310.0)
		2:
			target_position = Vector2(762.0, 310.0)
		3:
			target_position = Vector2(1272.0, 310.0)
	
	var tween = create_tween()
	tween.tween_property(self, "global_position", target_position, 1.5)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
	
	tween.finished.connect(func(): play_round_countdown(board_index))
	
	return tween.finished

func play_round_countdown(board_index: int) -> void:
	var score_interface = get_tree().current_scene.find_child("ScoreInterface", true, false)
	if not score_interface:
		return
	
	var round_label = score_interface.find_child("RoundLabel", true, false)
	var points_panel = score_interface.find_child("ControlDerecha", true, false)
	if points_panel == null:
		points_panel = score_interface.find_child("RightControl", true, false)
	
	if round_label:
		var tween = create_tween()
		
		tween.tween_callback(func():
			round_label.text = "ROUND %d" % board_index
			round_label.modulate.a = 0.0
			round_label.visible = true
			round_label.horizontal_alignment = 1
			round_label.vertical_alignment = 1
			round_label.anchors_preset = Control.PRESET_CENTER
			round_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
			round_label.grow_vertical = Control.GROW_DIRECTION_BOTH
		)
		
		tween.tween_property(round_label, "modulate:a", 1.0, 0.2)
		tween.tween_interval(1.5)
		tween.tween_property(round_label, "modulate:a", 0.0, 0.2)
		
		tween.tween_callback(func():
			round_label.text = "3"
			round_label.modulate.a = 0.0
		)
		tween.tween_property(round_label, "modulate:a", 1.0, 0.1)
		tween.tween_interval(0.8)
		tween.tween_property(round_label, "modulate:a", 0.0, 0.1)
		
		tween.tween_callback(func():
			round_label.text = "2"
			round_label.modulate.a = 0.0
		)
		tween.tween_property(round_label, "modulate:a", 1.0, 0.1)
		tween.tween_interval(0.8)
		tween.tween_property(round_label, "modulate:a", 0.0, 0.1)
		
		tween.tween_callback(func():
			round_label.text = "PLAY!"
			round_label.modulate.a = 0.0
		)
		tween.tween_property(round_label, "modulate:a", 1.0, 0.1)
		tween.tween_interval(0.6)
		tween.tween_property(round_label, "modulate:a", 0.0, 0.2)
		tween.tween_callback(func(): round_label.visible = false)
		
		tween.tween_callback(func():
			if score_interface.has_method("_reposition_clocks"):
				score_interface._reposition_clocks
		)
		
		if points_panel:
			tween.tween_callback(func():
				points_panel.visible = true
				points_panel.modulate.a = 0.0
			)
			tween.tween_property(points_panel, "modulate:a", 1.0,  0.5)
		
		tween.tween_callback(func():
			Gamemanager.active_game = true
			
			var board_node = get_tree().current_scene.get_node_or_null("Board2D_" + str(board_index))
			if board_node:
				if "is_movement_active" in board_node:
					board_node.is_movement_active = true
				if board_node.has_method("activate_piece_movement"):
					board_node.activate_piece_movement()
				board_node.set_process(true)
			
			score_interface.set_process(true)
		)
		
