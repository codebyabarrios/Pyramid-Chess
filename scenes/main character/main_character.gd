extends Node2D

@onready var game_manager_node = get_node("/root/Gamemanager")

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

func _ready() -> void:
	$Area2D.area_entered.connect(_on_area_entered)
	add_to_group("players")

func set_side(white: bool, texture_path: String):
	is_white = white
	is_player_one = !white
	$Sprite2D.texture = load(texture_path)

func _process(delta):
	var key_pressed_this_frame = false
	
	if is_player_one:
		if Input.is_action_just_pressed("p1_right"):
			buffered_move_direction.x = 1
			key_pressed_this_frame = true
		if Input.is_action_just_pressed("p1_left"):
			buffered_move_direction.x = -1
			key_pressed_this_frame = true
		if Input.is_action_just_pressed("p1_up"):
			buffered_move_direction.y = -1
			key_pressed_this_frame = true
	else:
		if Input.is_action_just_pressed("p2_right"):
			buffered_move_direction.x = 1
			key_pressed_this_frame = true
		if Input.is_action_just_pressed("p2_left"):
			buffered_move_direction.x = -1
			key_pressed_this_frame = true
		if Input.is_action_just_pressed("p2_up"):
			buffered_move_direction.y = -1
			key_pressed_this_frame = true
	
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
									if is_border_jump:
										if abs(child.global_position.x - real_target_global_pos.x) < (5 * global_scale.x) and abs(child.global_position.y - real_target_global_pos.y) < (5 * global_scale.y):
											allowed_movement = false
											break
									else:
										if abs(child.global_position.x - real_target_global_pos.x) < (5 * global_scale.x) and abs(child.global_position.y - real_target_global_pos.y) < (5 * global_scale.y):
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
						if board_node and board_node.has_method("remove_rider_from_matrix"):
							board_node.remove_rider_from_matrix(self)
						
						if is_border_jump:
							$Area2D.monitoring = false
						
						previous_move_position = position
						has_captured_this_turn = false 
						
						position.x = new_pos_x
						position.y = new_pos_y
						
						if is_border_jump:
							await get_tree().physics_frame
							$Area2D.monitoring = true
						
						is_riding_rank = false
						var current_grid_y = clamp(int(position.y / TILE_SIZE), 0, 7)
						
						if current_grid_y == 0:
							var spawn_pos = global_position
							get_tree().create_timer(0.05).timeout.connect(func():
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
						
						if board_node and "board" in board_node:
							for x in range(8):
								var piece = board_node.board[current_grid_y][x]
								if is_instance_valid(piece) and piece != self and not piece.is_in_group("players"):
									is_riding_rank = true
									direction = -1 if (current_grid_y % 2 != 0) else 1
									break
					
					buffered_move_direction = Vector2.ZERO
				else:
					buffered_move_direction = Vector2.ZERO
				
func _on_area_entered(touched_area: Area2D) -> void:
	var piece = touched_area.get_parent()
	if piece != null:
		has_captured_this_turn = true 
		
		if "type_piece" in piece and piece.type_piece == "king":
			if "color" in piece and my_color == piece.color:
				call_deferred("_damage_piece", piece)
				return
		
		if "is_white" in piece:
			if piece.is_white == is_white:
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
	var board_node = get_parent()
	
	if piece.type_piece == "king":
		if piece.is_white == is_white:
			var reset_triggered = _check_capture_penalty()
			if reset_triggered:
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
	var board_node = get_parent()
	is_riding_rank = false
	var current_grid_y = clamp(int(position.y / TILE_SIZE), 0, 7)
	
	if board_node and "board" in board_node:
		for x in range(8):
			var current_piece = board_node.board[current_grid_y][x]
			
			if is_instance_valid(current_piece) and current_piece != self and not current_piece.is_in_group("players"):
				is_riding_rank = true
				direction = -1 if (current_grid_y % 2 != 0) else 1
				break

func _handle_piece_destruction(piece: Node) -> void:
	var board_node = get_parent()
	var rider_color = "white" if is_white else "black"
	
	if "type_piece" in piece and piece.type_piece == "king":
		if piece.is_white != is_white:
			capture_pieces(piece, rider_color)
			return
			
	if piece.is_white == is_white:
		var reset_triggered = _check_capture_penalty()
		capture_pieces(piece, rider_color)
		if reset_triggered:
			return
	else:
		capture_pieces(piece, rider_color)
		direction = piece.direction
		is_riding_rank = true
		if board_node and board_node.has_method("register_rider_in_matrix"):
			board_node.register_rider_in_matrix(self, piece.grid_position.x, piece.grid_position.y)
	
	
func _check_capture_penalty() -> bool:
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

		var players = get_tree().get_nodes_in_group("players")
		for player in players:
			if is_instance_valid(player):
				if board_node.has_method("remove_rider_from_matrix"):
					board_node.remove_rider_from_matrix(player)
				
				if player.is_white:
					player.position = player.initial_position_e1
					player.grid_position = Vector2i(4, 7)
					if board_node.has_method("register_rider_in_matrix"):
						board_node.register_rider_in_matrix(player, 4, 7)
				else:
					player.position = player.initial_position_d1
					player.grid_position = Vector2i(3, 7)
					if board_node.has_method("register_rider_in_matrix"):
						board_node.register_rider_in_matrix(player, 3, 7)
		
		cont_same_color = 0
		return true
	
	return false

func capture_pieces(captured_piece: Node, rider_color_that_captures: String) -> void:
	if is_instance_valid(captured_piece):
		var same_color = (captured_piece.is_white == is_white)
		Gamemanager.process_capture(captured_piece.type_piece, same_color, rider_color_that_captures)
		captured_piece.queue_free()

func _update_life_bar(life_bar: TextureProgressBar, current_health: float, max_health: float) -> void:
	var health_percentage = current_health / max_health
	
	life_bar.nine_patch_stretch = true
	life_bar.custom_minimum_size = Vector2(44, 10)
	life_bar.size = Vector2(44, 10)
	
	var transparent = Color(0, 0, 0, 0)
	var black = Color("#000000")
	
	var gradient_resource = Gradient.new()
	var left_color = Color.from_hsv(0.0, 0.9, 0.9)
	var current_hue = health_percentage * 0.33
	var right_color = Color.from_hsv(current_hue, 0.9, 0.9)
	gradient_resource.set_color(0, left_color)
	gradient_resource.set_color(1, right_color)
	
	var base_gradient = GradientTexture2D.new()
	base_gradient.gradient = gradient_resource
	base_gradient.width = 44
	base_gradient.height = 10
	base_gradient.fill_from = Vector2(0, 0)
	base_gradient.fill_to = Vector2(1, 0)
	
	var grad_img = base_gradient.get_image()
	_apply_borders_and_corners(grad_img, black, transparent)
	life_bar.texture_progress = ImageTexture.create_from_image(grad_img)
	
	if life_bar.texture_under == null:
		var bg_img = Image.create(44, 10, false, Image.FORMAT_RGBA8)
		bg_img.fill(Color("#1a1a1a"))
		_apply_borders_and_corners(bg_img, black, transparent)
		life_bar.texture_under = ImageTexture.create_from_image(bg_img)
	
	life_bar.texture_over = null
	life_bar.stretch_margin_left = 0
	life_bar.stretch_margin_right = 0
	life_bar.stretch_margin_top = 0
	life_bar.stretch_margin_bottom = 0
	
	life_bar.max_value = max_health
	life_bar.value = current_health
	life_bar.tint_progress = Color.WHITE
	life_bar.tint_under = Color.WHITE
	
	life_bar.visible = true
	life_bar.z_index = 10

func _apply_borders_and_corners(img: Image, black: Color, transparent: Color) -> void:
	for x in range(44):
		for y in range(10):
			if x == 0 or x == 43 or y == 0 or y == 9:
				img.set_pixel(x, y, black)
	
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
