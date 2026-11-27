extends Node2D

@onready var game_manager_node = get_node("/root/Gamemanager")

var my_lantern: PointLight2D
var is_frozen: bool = false
var grid_position = Vector2i.ZERO
var is_white = true
var direction = 1
var is_player_one = true
var is_riding_rank = false
var auto_movement_timer = 0.0

var input_buffer_timer = 0.0
const INPUT_BUFFER_DELAY = 0.08
var buffered_move_direction = Vector2.ZERO
var is_waiting_for_input = false

var initial_position_d1 = Vector2((3 * TILE_SIZE) + (TILE_SIZE / 2), (7 * TILE_SIZE) + (TILE_SIZE / 2))
var initial_position_e1 = Vector2((4 * TILE_SIZE) + (TILE_SIZE / 2), (7 * TILE_SIZE) + (TILE_SIZE / 2))

static var cont_same_color: int = 0
const STEP_DELAY = 0.75
const TILE_SIZE = 64
const FLOATING_TEXT_SCENE = preload("res://FloatingText.tscn")

@export_enum("White", "Black") var my_color: String = "White"

var previous_move_position = Vector2.ZERO
var has_captured_this_turn: bool = false
var has_finished: bool = false

var _broken_heart_texture: Texture2D = null
var _critical_pulse_tween: Tween = null

func _ready() -> void:
	$Area2D.area_entered.connect(_on_area_entered)
	add_to_group("players")
	
	if Global.is_dark_mode_active:
		my_lantern = PointLight2D.new()
		my_lantern.energy = 1.2
		my_lantern.blend_mode = Light2D.BLEND_MODE_MIX 
		var grad = Gradient.new()
		grad.colors = PackedColorArray([Color(1.0, 0.85, 0.5, 1.0), Color(0.9, 0.55, 0.15, 0.8), Color(0.7, 0.3, 0.05, 0.35), Color(0.0, 0.0, 0.0, 0.0)])
		grad.offsets = PackedFloat32Array([0.0, 0.25, 0.65, 1.0])
		var tex = GradientTexture2D.new()
		tex.gradient = grad
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(1.0, 0.5)
		tex.width = 280  
		tex.height = 280 
		my_lantern.texture = tex
		my_lantern.z_index = -1 
		add_child(my_lantern)
		my_lantern.enabled = false

func set_side(white: bool, texture_path: String):
	is_white = white
	is_player_one = !white
	$Sprite2D.texture = load(texture_path)

func _get_rank_dir_for_row(row_y: int, board_node: Node) -> int:
	if row_y == 0:
		return 0
	if board_node and board_node.has_method("get_rank_direction"):
		var dir_from_board: int = board_node.get_rank_direction(row_y)
		if dir_from_board != 0:
			return 1 if dir_from_board > 0 else -1
	return -1 if (row_y % 2 != 0) else 1

func _process(delta):
	if has_finished or is_frozen:
		return
		
	var rider_color = "white" if is_white else "black"
	Gamemanager.apply_idle_drain(rider_color, delta)
	
	if my_lantern:
		my_lantern.enabled = Gamemanager.is_board_dark
		if my_lantern.enabled:
			var time_ms = Time.get_ticks_msec()
			var flicker = (sin(time_ms * 0.01) * 0.04) + (cos(time_ms * 0.02) * 0.02)
			my_lantern.energy = 1.2 + flicker
			my_lantern.texture_scale = 1.0 + (flicker * 0.4)
	
	if not Gamemanager.can_rider_move(rider_color):
		buffered_move_direction = Vector2.ZERO
		is_waiting_for_input = false
		return
		
	var key_pressed_this_frame = false
	
	if is_player_one:
		if Input.is_action_just_pressed("p1_right"): buffered_move_direction.x = 1; key_pressed_this_frame = true
		if Input.is_action_just_pressed("p1_left"): buffered_move_direction.x = -1; key_pressed_this_frame = true
		if Input.is_action_just_pressed("p1_up"): buffered_move_direction.y = -1; key_pressed_this_frame = true
	else:
		if Input.is_action_just_pressed("p2_right"): buffered_move_direction.x = 1; key_pressed_this_frame = true
		if Input.is_action_just_pressed("p2_left"): buffered_move_direction.x = -1; key_pressed_this_frame = true
		if Input.is_action_just_pressed("p2_up"): buffered_move_direction.y = -1; key_pressed_this_frame = true
	
	if key_pressed_this_frame and not is_waiting_for_input:
		is_waiting_for_input = true
		input_buffer_timer = 0.0
	
	if is_waiting_for_input:
		input_buffer_timer += delta
		if input_buffer_timer >= INPUT_BUFFER_DELAY:
			is_waiting_for_input = false
			if buffered_move_direction != Vector2.ZERO:
				var board_node = get_parent()
				var new_pos_x = position.x + (buffered_move_direction.x * TILE_SIZE)
				var new_pos_y = position.y + (buffered_move_direction.y * TILE_SIZE)
				
				var min_limit_x = 0
				var max_limit_x = 8 * TILE_SIZE
				var min_limit_y = 0
				var max_limit_y = 8 * TILE_SIZE
				var is_border_jump = false
				
				if new_pos_x > max_limit_x:
					new_pos_x = (0 * TILE_SIZE) + (TILE_SIZE / 2)
					is_border_jump = true
				elif new_pos_x < min_limit_x:
					new_pos_x = (7 * TILE_SIZE) + (TILE_SIZE / 2)
					is_border_jump = true
				
				var allowed_movement = true
				var real_target_global_pos = global_position + (buffered_move_direction * TILE_SIZE * global_scale.x)
				if is_border_jump:
					var local_displacement = Vector2(new_pos_x, new_pos_y) - position
					real_target_global_pos = global_position + (local_displacement * global_scale)
				
				if buffered_move_direction.y == 0 and buffered_move_direction.x != 0:
					if board_node:
						for child in board_node.get_children():
							if child != self and not child.is_in_group("players") and is_instance_valid(child) and not child.is_queued_for_deletion():
								if "type_piece" in child and "global_position" in child:
									if abs(child.global_position.x - real_target_global_pos.x) < (5 * global_scale.x) and abs(child.global_position.y - real_target_global_pos.y) < (5 * global_scale.y):
										if child.type_piece != "lightbulb" and child.type_piece != "portal":
											allowed_movement = false
											break
				
				var all_main_characters = get_tree().get_nodes_in_group("players")
				for player in all_main_characters:
					if player != self:
						if abs(player.global_position.x - real_target_global_pos.x) < (5 * global_scale.x) and abs(player.global_position.y - real_target_global_pos.y) < (5 * global_scale.y):
							allowed_movement = false
							break
				
				if allowed_movement:
					if new_pos_y > min_limit_y and new_pos_y < max_limit_y:
						Gamemanager.consume_movement_energy(rider_color)
						AudioManager.play_jump() 
						
						if board_node and board_node.has_method("remove_rider_from_matrix"):
							board_node.remove_rider_from_matrix(self)
						if is_border_jump:
							$Area2D.monitoring = false
						
						previous_move_position = position
						has_captured_this_turn = false 
						position.x = new_pos_x
						position.y = new_pos_y
						grid_position = Vector2i(clamp(int(position.x / TILE_SIZE), 0, 7), clamp(int(position.y / TILE_SIZE), 0, 7))
						
						if is_border_jump:
							await get_tree().physics_frame
							$Area2D.monitoring = true
						
						is_riding_rank = false
						direction = 0
						var current_grid_y = clamp(int(position.y / TILE_SIZE), 0, 7)
						
						if current_grid_y == 0:
							var spawn_pos = global_position
							if is_inside_tree():
								get_tree().create_timer(0.05).timeout.connect(func():
									if has_finished:
										return
									if not has_captured_this_turn and is_instance_valid(self):
										if FLOATING_TEXT_SCENE:
											var text_instance = FLOATING_TEXT_SCENE.instantiate()
											if board_node:
												board_node.add_child(text_instance)
												text_instance.global_position = spawn_pos
												if text_instance.has_method("start"):
													text_instance.start("Coming Back!", Color.ORANGE)
												elif "label" in text_instance and text_instance.label != null:
													text_instance.label.text = "Coming Back!"
													text_instance.label.self_modulate = Color.ORANGE
										if board_node and board_node.has_method("remove_rider_from_matrix"):
											board_node.remove_rider_from_matrix(self)
										is_riding_rank = false
										direction = 0
										if is_white:
											position = initial_position_e1
											grid_position = Vector2i(4, 7)
											if board_node and board_node.has_method("register_rider_in_matrix"):
												board_node.register_rider_in_matrix(self, 4, 7)
										else:
											position = initial_position_d1
											grid_position = Vector2i(3, 7)
											if board_node and board_node.has_method("register_rider_in_matrix"):
												board_node.register_rider_in_matrix(self, 3, 7)
								)
						else:
							var has_pieces_in_rank = false
							for child in get_tree().get_nodes_in_group("chess_pieces"):
								if is_instance_valid(child) and not child.is_queued_for_deletion():
									if abs(child.position.y - position.y) < 10.0:
										has_pieces_in_rank = true
										break
							
							if has_pieces_in_rank:
								is_riding_rank = true
								direction = _get_rank_dir_for_row(current_grid_y, board_node)
					
					buffered_move_direction = Vector2.ZERO
				else:
					buffered_move_direction = Vector2.ZERO

func _on_area_entered(touched_area: Area2D) -> void:
	if "has_finished" in self and has_finished:
		return
	
	if "type_piece" in touched_area:
		if touched_area.type_piece == "lightbulb":
			Gamemanager.eat_lightbulb(touched_area.is_on)
			touched_area.queue_free()
			return
		if touched_area.type_piece == "portal":
			if touched_area.has_method("trigger_teleport"):
				touched_area.trigger_teleport(self)
			return
	
	var piece = touched_area.get_parent()
	if piece == null or not ("type_piece" in piece):
		return
	if not is_instance_valid(piece) or piece.is_queued_for_deletion():
		return
	
	if piece.type_piece == "king":
		if "is_white" in piece and piece.is_white != is_white:
			$Area2D.monitoring = false
			$Area2D.monitorable = false
			has_captured_this_turn = true
			_handle_piece_destruction(piece)
			return
		if "color" in piece and my_color == piece.color:
			call_deferred("_damage_piece", piece)
			return
	
	if "is_white" in piece and piece.is_white == is_white:
		var board_node = get_parent()
		var rider_color = "white" if is_white else "black"
		Gamemanager.process_capture(piece.type_piece, true, rider_color)
		if board_node and board_node.has_method("remove_rider_from_matrix"):
			board_node.remove_rider_from_matrix(self)
		is_riding_rank = false
		direction = 0
		if is_white:
			position = initial_position_e1
			grid_position = Vector2i(4, 7)
			if board_node and board_node.has_method("register_rider_in_matrix"):
				board_node.register_rider_in_matrix(self, 4, 7)
		else:
			position = initial_position_d1
			grid_position = Vector2i(3, 7)
			if board_node and board_node.has_method("register_rider_in_matrix"):
				board_node.register_rider_in_matrix(self, 3, 7)
		_check_capture_penalty()
		return
	
	call_deferred("_damage_piece", piece)

func _damage_piece(piece: Node) -> void:
	if not is_instance_valid(piece) or piece.is_queued_for_deletion():
		return
	var board_node = get_parent()
	if piece.type_piece == "king":
		if piece.is_white == is_white:
			if _check_capture_penalty():
				return
			_check_capture_penalty()
			var origin_rank = clamp(int(previous_move_position.y / TILE_SIZE), 0, 7)
			if board_node and board_node.has_method("pause_rank"):
				board_node.pause_rank(origin_rank, 0.15)
			position = previous_move_position
			_recalculate_rank_movement()
			return
		else:
			piece.health = 0
			_handle_piece_destruction(piece)
			return
	
	var max_health = 1.0
	match piece.type_piece:
		"pawn": max_health = 1.0
		"knight", "bishop": max_health = 3.0
		"rook": max_health = 5.0
		"queen": max_health = 9.0
	
	piece.health -= 1
	AudioManager.play_slash()
	if piece.health > 0:
		var life_bar = piece.get_node_or_null("Area2D/VisualLife")
		if life_bar != null:
			_update_life_bar(life_bar, piece.health, max_health)
		if piece.is_white == is_white:
			if _check_capture_penalty():
				return
		var origin_rank = clamp(int(previous_move_position.y / TILE_SIZE), 0, 7)
		if board_node and board_node.has_method("pause_rank"):
			board_node.pause_rank(origin_rank, 0.15)
		position = previous_move_position
		_recalculate_rank_movement()
	else:
		_handle_piece_destruction(piece)

func _recalculate_rank_movement() -> void:
	if has_finished:
		is_riding_rank = false
		direction = 0
		return
	var current_grid_y = clamp(int(position.y / TILE_SIZE), 0, 7)
	if current_grid_y == 0:
		is_riding_rank = false
		direction = 0
		return
	var board_node = get_parent()
	if is_riding_rank:
		direction = _get_rank_dir_for_row(current_grid_y, board_node)
		return
	var has_pieces_in_rank = false
	for child in get_tree().get_nodes_in_group("chess_pieces"):
		if is_instance_valid(child) and not child.is_queued_for_deletion():
			if abs(child.position.y - position.y) < 10.0:
				has_pieces_in_rank = true
				break
	if has_pieces_in_rank:
		is_riding_rank = true
		direction = _get_rank_dir_for_row(current_grid_y, board_node)
		if board_node and "movement_timer" in board_node:
			auto_movement_timer = board_node.movement_timer
		else:
			auto_movement_timer = 0.0

func _handle_piece_destruction(piece: Node) -> void:
	if has_finished:
		return
	if not is_instance_valid(piece) or piece.is_queued_for_deletion():
		return
	var board_node = get_parent()
	var rider_color = "white" if is_white else "black"
	
	if "type_piece" in piece and piece.type_piece == "king":
		if piece.is_white != is_white:
			if piece.has_method("mark_as_captured"):
				var is_first_capture = piece.mark_as_captured()
				if not is_first_capture:
					return
			position = piece.position
			grid_position = piece.grid_position if "grid_position" in piece else Vector2i(clamp(int(position.x / TILE_SIZE), 0, 7), clamp(int(position.y / TILE_SIZE), 0, 7))
			has_finished = true
			is_riding_rank = false
			direction = 0
			if has_node("Area2D"):
				$Area2D.monitoring = false
				$Area2D.monitorable = false
			if is_white:
				Gamemanager.white_clock_active = false
			else:
				Gamemanager.black_clock_active = false
			if board_node and board_node.has_method("register_frozen_rider"):
				board_node.register_frozen_rider(self)
			if board_node and board_node.has_method("remove_rider_from_matrix"):
				board_node.remove_rider_from_matrix(self)
			Gamemanager.process_capture(piece.type_piece, false, rider_color, self)
			piece.queue_free()
			return
	
	if piece.is_white == is_white:
		var reset_triggered = _check_capture_penalty()
		capture_pieces(piece, rider_color)
		if reset_triggered:
			return
	else:
		has_captured_this_turn = true
		buffered_move_direction = Vector2.ZERO
		is_waiting_for_input = false
		
		var target_pos = piece.position
		var target_grid = piece.grid_position if "grid_position" in piece else Vector2i(clamp(int(target_pos.x / TILE_SIZE), 0, 7), clamp(int(target_pos.y / TILE_SIZE), 0, 7))
		var current_grid_y = clamp(int(target_pos.y / TILE_SIZE), 0, 7)
		
		var inherited_dir := _get_rank_dir_for_row(current_grid_y, board_node)
		
		capture_pieces(piece, rider_color)
		position = target_pos
		grid_position = target_grid
		previous_move_position = position
		
		if current_grid_y == 0:
			is_riding_rank = false
			direction = 0
		else:
			is_riding_rank = true
			direction = inherited_dir
		
		if board_node and "movement_timer" in board_node:
			auto_movement_timer = board_node.movement_timer
		else:
			auto_movement_timer = 0.0
		
		if board_node and board_node.has_method("register_rider_in_matrix"):
			board_node.register_rider_in_matrix(self, grid_position.x, grid_position.y)

func _check_capture_penalty() -> bool:
	if has_finished:
		return false
	cont_same_color += 1
	if cont_same_color >= 3:
		var board_node = get_parent()
		if not board_node:
			cont_same_color = 0
			return true
		for child in board_node.get_children():
			if is_instance_valid(child) and not child.is_queued_for_deletion() and "grid_position" in child:
				if (child.grid_position.x == 3 or child.grid_position.x == 4) and child.grid_position.y == 7:
					if not ("is_player_one" in child):
						if board_node.has_method("remove_piece_from_matrix"):
							board_node.remove_piece_from_matrix(child)
						child.queue_free()
		if board_node.has_method("remove_rider_from_matrix"):
			board_node.remove_rider_from_matrix(self)
		is_riding_rank = false
		direction = 0
		buffered_move_direction = Vector2.ZERO
		is_waiting_for_input = false
		has_captured_this_turn = false
		if is_white:
			position = initial_position_e1
			grid_position = Vector2i(4, 7)
			if board_node.has_method("register_rider_in_matrix"):
				board_node.register_rider_in_matrix(self, 4, 7)
		else:
			position = initial_position_d1
			grid_position = Vector2i(3, 7)
			if board_node.has_method("register_rider_in_matrix"):
				board_node.register_rider_in_matrix(self, 3, 7)
		previous_move_position = position
		cont_same_color = 0
		return true
	return false

func teleport_to(target_pos: Vector2):
	var board_node = get_parent()
	if board_node and board_node.has_method("remove_rider_from_matrix"):
		board_node.remove_rider_from_matrix(self)
	position = target_pos
	previous_move_position = position
	buffered_move_direction = Vector2.ZERO
	is_waiting_for_input = false
	input_buffer_timer = 0.0
	var new_grid_x = clamp(int(target_pos.x / TILE_SIZE), 0, 7)
	var new_grid_y = clamp(int(target_pos.y / TILE_SIZE), 0, 7)
	grid_position = Vector2i(new_grid_x, new_grid_y)
	if board_node and board_node.has_method("register_rider_in_matrix"):
		board_node.register_rider_in_matrix(self, new_grid_x, new_grid_y)
	_recalculate_rank_movement()

func capture_pieces(captured_piece: Node, rider_color_that_captures: String) -> void:
	if is_instance_valid(captured_piece):
		var same_color = (captured_piece.is_white == is_white)
		Gamemanager.process_capture(captured_piece.type_piece, same_color, rider_color_that_captures)
		captured_piece.queue_free()

func _update_life_bar(life_bar: TextureProgressBar, current_health: float, max_health: float) -> void:
	var health_percentage = current_health / max_health
	life_bar.nine_patch_stretch = true; life_bar.custom_minimum_size = Vector2(44, 10); life_bar.size = Vector2(44, 10)
	var transparent = Color(0, 0, 0, 0); var black = Color("#000000")
	var gradient_resource = Gradient.new()
	var left_color = Color.from_hsv(0.0, 0.9, 0.9)
	var current_hue = health_percentage * 0.33
	var right_color = Color.from_hsv(current_hue, 0.9, 0.9)
	gradient_resource.set_color(0, left_color); gradient_resource.set_color(1, right_color)
	var base_gradient = GradientTexture2D.new(); base_gradient.gradient = gradient_resource
	base_gradient.width = 44; base_gradient.height = 10
	base_gradient.fill_from = Vector2(0, 0); base_gradient.fill_to = Vector2(1, 0)
	var grad_img = base_gradient.get_image()
	_apply_borders_and_corners(grad_img, black, transparent)
	life_bar.texture_progress = ImageTexture.create_from_image(grad_img)
	if life_bar.texture_under == null:
		var bg_img = Image.create(44, 10, false, Image.FORMAT_RGBA8)
		bg_img.fill(Color("#1a1a1a"))
		_apply_borders_and_corners(bg_img, black, transparent)
		life_bar.texture_under = ImageTexture.create_from_image(bg_img)
	life_bar.texture_over = null
	life_bar.stretch_margin_left = 0; life_bar.stretch_margin_right = 0
	life_bar.stretch_margin_top = 0; life_bar.stretch_margin_bottom = 0
	life_bar.max_value = max_health; life_bar.value = current_health
	life_bar.tint_progress = Color.WHITE; life_bar.tint_under = Color.WHITE
	life_bar.visible = true; life_bar.z_index = 10

func _apply_borders_and_corners(img: Image, black: Color, transparent: Color) -> void:
	for x in range(44):
		for y in range(10):
			if x == 0 or x == 43 or y == 0 or y == 9: img.set_pixel(x, y, black)
	img.set_pixel(0, 0, transparent); img.set_pixel(1, 0, transparent); img.set_pixel(2, 0, transparent)
	img.set_pixel(0, 1, transparent); img.set_pixel(0, 2, transparent)
	img.set_pixel(1, 1, black); img.set_pixel(2, 1, black); img.set_pixel(1, 2, black)
	img.set_pixel(43, 0, transparent); img.set_pixel(42, 0, transparent); img.set_pixel(41, 0, transparent)
	img.set_pixel(43, 1, transparent); img.set_pixel(43, 2, transparent)
	img.set_pixel(42, 1, black); img.set_pixel(41, 1, black); img.set_pixel(42, 2, black)
	img.set_pixel(0, 9, transparent); img.set_pixel(1, 9, transparent); img.set_pixel(2, 9, transparent)
	img.set_pixel(0, 8, transparent); img.set_pixel(0, 7, transparent)
	img.set_pixel(1, 8, black); img.set_pixel(2, 8, black); img.set_pixel(1, 7, black)
	img.set_pixel(43, 9, transparent); img.set_pixel(42, 9, transparent); img.set_pixel(41, 9, transparent)
	img.set_pixel(43, 8, transparent); img.set_pixel(43, 7, transparent)
	img.set_pixel(42, 8, black); img.set_pixel(41, 8, black); img.set_pixel(42, 7, black)

func _show_finish_banner() -> void:
	var canvas = CanvasLayer.new()
	get_tree().root.add_child(canvas)
	var label = Label.new()
	label.text = "FINISH"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var settings = LabelSettings.new()
	settings.font = load("res://PressStart2P.ttf") 
	settings.font_size = 55
	settings.font_color = Color("#ffd700") 
	settings.outline_size = 8
	settings.outline_color = Color.BLACK
	label.label_settings = settings
	canvas.add_child(label)
	await get_tree().create_timer(2.5).timeout
	canvas.queue_free()

func start_critical_pulse() -> void:
	if not has_node("Sprite2D"):
		return
	var spr := $Sprite2D as CanvasItem
	stop_critical_pulse()
	
	_critical_pulse_tween = create_tween()
	_critical_pulse_tween.set_loops()
	_critical_pulse_tween.tween_property(spr, "modulate", Color(1.0, 0.5, 0.5, 1.0), 1.0)
	_critical_pulse_tween.tween_property(spr, "modulate", Color.WHITE, 1.0)

func stop_critical_pulse() -> void:
	if _critical_pulse_tween != null and _critical_pulse_tween.is_valid():
		_critical_pulse_tween.kill()
	_critical_pulse_tween = null
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color.WHITE

func _get_or_create_broken_heart_texture() -> Texture2D:
	if _broken_heart_texture != null:
		return _broken_heart_texture
	
	var size := 24
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var fill_color := Color(1.0, 0.15, 0.25, 1.0)
	var border_color := Color(0.12, 0.02, 0.05, 1.0)
	
	for py in range(size):
		for px in range(size):
			var nx := (float(px) / float(size - 1)) * 2.6 - 1.3
			var ny := -((float(py) / float(size - 1)) * 2.6 - 1.2)
			
			var a := nx * nx + ny * ny - 1.0
			var inside := (a * a * a) - (nx * nx * ny * ny * ny) <= 0.0
			
			if inside:
				var gap_x := 0
				if absf(nx) < 0.08:
					continue
				if nx < 0.0:
					gap_x = -1
				else:
					gap_x = 1
				
				var target_x := clampi(px + gap_x, 0, size - 1)
				img.set_pixel(target_x, py, fill_color)
	
	for py in range(1, size - 1):
		for px in range(1, size -1):
			if img.get_pixel(px, py).a == 0.0:
				var near_heart := (
					img.get_pixel(px - 1, py).a > 0.0
					or img.get_pixel(px + 1, py).a > 0.0
					or img.get_pixel(px, py - 1).a > 0.0
					or img.get_pixel(px, py + 1).a > 0.0
				)
				if near_heart:
					img.set_pixel(px, py, border_color)
	
	_broken_heart_texture = ImageTexture.create_from_image(img)
	return _broken_heart_texture

func spawn_broken_heart() -> void:
	var parent_board := get_parent()
	if parent_board == null:
		return
	
	var broken := Sprite2D.new()
	broken.texture = _get_or_create_broken_heart_texture()
	broken.global_position = global_position + Vector2(0, -28)
	broken.modulate = Color(1.0, 1.0, 1.0, 1.0)
	broken.z_index = 90
	parent_board.add_child(broken)
	
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(broken, "position:y", broken.position.y - 20.0, 0.6)
	t.tween_property(broken, "modulate:a", 0.0, 0.6)
	t.chain().tween_callback(broken.queue_free)
