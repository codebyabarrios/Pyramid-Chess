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
var cont_same_color = 0

var initial_position_d1 = Vector2 ((4 * TILE_SIZE) + (TILE_SIZE / 2), (7 * TILE_SIZE) + (TILE_SIZE / 2))
var initial_position_e1 = Vector2 ((3 * TILE_SIZE) + (TILE_SIZE / 2), (7 * TILE_SIZE) + (TILE_SIZE / 2))

const STEP_DELAY = 0.75
const TILE_SIZE = 64
const FLOATING_TEXT_SCENE = preload("res://FloatingText.tscn")

func _ready():
	$Area2D.area_entered.connect(_on_area_entered)
	add_to_group("players")
	
func set_side(white: bool, texture_path: String):
	is_white = white
	is_player_one = !white
	$Sprite2D.texture = load(texture_path)

func _process(delta):
	if is_riding_rank:
		auto_movement_timer += delta
		if auto_movement_timer >= STEP_DELAY:
			auto_movement_timer = 0.0
			position.x += TILE_SIZE * direction
	
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
				
				if new_pos_x > max_limit_x:
					new_pos_x = (0 * TILE_SIZE) + (TILE_SIZE / 2)
				
				elif new_pos_x < min_limit_x:
					new_pos_x = (7 * TILE_SIZE) + (TILE_SIZE / 2)
				
				var allowed_movement = true
				var all_main_characters = get_tree().get_nodes_in_group("players")
				
				for player in all_main_characters:
					if player != self:
						if abs(player.position.x - new_pos_x) < 5 and abs(player.position.y - new_pos_y) < 5:
							allowed_movement = false
							break
				
				if allowed_movement:
					if new_pos_y > min_limit_y and new_pos_y < max_limit_y:
						if board_node and board_node.has_method("remove_rider_from_matrix"):
							board_node.remove_rider_from_matrix(self)
						position.x = new_pos_x
						position.y = new_pos_y
					
					buffered_move_direction = Vector2.ZERO
	
func _on_area_entered(touched_area: Area2D) -> void:
	var piece = touched_area.get_parent()
	
	if piece != null:
		var board_node = get_parent()
		var rider_color = "white" if is_white else "black"
		
		var max_health = 1.0
		match piece.type_piece:
			"pawn": max_health = 1.0
			"knight", "horse", "bishop": max_health = 3.0
			"rook": max_health = 5.0
			"queen": max_health = 8.0
		
		piece.health -= 1
		
		if piece.health > 0:
			var life_bar = piece.get_node_or_null("Area2D/VisualLife")
			if life_bar != null:
				var health_percentage = float(piece.health) / max_health
				
				life_bar.nine_patch_stretch = true
				life_bar.custom_minimum_size = Vector2(44, 10)
				life_bar.size = Vector2(44, 10)
				
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
				
				var transparent = Color(0, 0, 0, 0)
				var black = Color("#000000")
				
				for x in range(44):
					for y in range(10):
						if x == 0 or x == 43 or y == 0 or y == 9:
							grad_img.set_pixel(x, y, black)
				
				grad_img.set_pixel(0, 0, transparent)
				grad_img.set_pixel(1, 0, transparent)
				grad_img.set_pixel(2, 0, transparent)
				grad_img.set_pixel(0, 1, transparent)
				grad_img.set_pixel(0, 2, transparent)
				grad_img.set_pixel(1, 1, black)
				grad_img.set_pixel(2, 1, black)
				grad_img.set_pixel(1, 2, black)
				
				grad_img.set_pixel(43, 0, transparent)
				grad_img.set_pixel(42, 0, transparent)
				grad_img.set_pixel(41, 0, transparent)
				grad_img.set_pixel(43, 1, transparent)
				grad_img.set_pixel(43, 2, transparent)
				grad_img.set_pixel(42, 1, black)
				grad_img.set_pixel(41, 1, black)
				grad_img.set_pixel(42, 2, black)
				
				grad_img.set_pixel(0, 9, transparent)
				grad_img.set_pixel(1, 9, transparent)
				grad_img.set_pixel(2, 9, transparent)
				grad_img.set_pixel(0, 8, transparent)
				grad_img.set_pixel(0, 7, transparent)
				grad_img.set_pixel(1, 8, black)
				grad_img.set_pixel(2, 8, black)
				grad_img.set_pixel(1, 7, black)
				
				grad_img.set_pixel(43, 9, transparent)
				grad_img.set_pixel(42, 9, transparent)
				grad_img.set_pixel(41, 9, transparent)
				grad_img.set_pixel(43, 8, transparent)
				grad_img.set_pixel(43, 7, transparent)
				grad_img.set_pixel(42, 8, black)
				grad_img.set_pixel(41, 8, black)
				grad_img.set_pixel(42, 7, black)
				
				life_bar.texture_progress = ImageTexture.create_from_image(grad_img)
				
				if life_bar.texture_under == null:
					var bg_img = Image.create(44, 10, false, Image.FORMAT_RGBA8)
					bg_img.fill(Color("#1a1a1a")) 
					
					for x in range(44):
						for y in range(10):
							if x == 0 or x == 43 or y == 0 or y == 9:
								bg_img.set_pixel(x, y, black)
					
					bg_img.set_pixel(0, 0, transparent)
					bg_img.set_pixel(1, 0, transparent)
					bg_img.set_pixel(2, 0, transparent)
					bg_img.set_pixel(0, 1, transparent)
					bg_img.set_pixel(0, 2, transparent)
					bg_img.set_pixel(1, 1, black)
					bg_img.set_pixel(2, 1, black)
					bg_img.set_pixel(1, 2, black)
					
					bg_img.set_pixel(43, 0, transparent)
					bg_img.set_pixel(42, 0, transparent)
					bg_img.set_pixel(41, 0, transparent)
					bg_img.set_pixel(43, 1, transparent)
					bg_img.set_pixel(43, 2, transparent)
					bg_img.set_pixel(42, 1, black)
					bg_img.set_pixel(41, 1, black)
					bg_img.set_pixel(42, 2, black)
					
					bg_img.set_pixel(0, 9, transparent)
					bg_img.set_pixel(1, 9, transparent)
					bg_img.set_pixel(2, 9, transparent)
					bg_img.set_pixel(0, 8, transparent)
					bg_img.set_pixel(0, 7, transparent)
					bg_img.set_pixel(1, 8, black)
					bg_img.set_pixel(2, 8, black)
					bg_img.set_pixel(1, 7, black)
					
					bg_img.set_pixel(43, 9, transparent)
					bg_img.set_pixel(42, 9, transparent)
					bg_img.set_pixel(41, 9, transparent)
					bg_img.set_pixel(43, 8, transparent)
					bg_img.set_pixel(43, 7, transparent)
					bg_img.set_pixel(42, 8, black)
					bg_img.set_pixel(41, 8, black)
					bg_img.set_pixel(42, 7, black)
					
					life_bar.texture_under = ImageTexture.create_from_image(bg_img)
				
				life_bar.texture_over = null
				
				life_bar.stretch_margin_left = 0
				life_bar.stretch_margin_right = 0
				life_bar.stretch_margin_top = 0
				life_bar.stretch_margin_bottom = 0
				
				life_bar.max_value = max_health
				life_bar.value = piece.health
				life_bar.tint_progress = Color.WHITE
				life_bar.tint_under = Color.WHITE
				
				life_bar.visible = true
				life_bar.z_index = 10 
			
			position.y += TILE_SIZE
			
			if piece.is_white == is_white:
				cont_same_color += 1
				if cont_same_color >= 3:
					if board_node and board_node.has_method("remove_rider_from_matrix"):
						board_node.remove_rider_from_matrix(self)
					
					if is_player_one: position = initial_position_e1
					else: position = initial_position_d1
					cont_same_color = 0
		else:
			if piece.is_white == is_white:
				capture_pieces(piece, rider_color)
				
				cont_same_color += 1
				if cont_same_color >= 3:
					if board_node and board_node.has_method("remove_rider_from_matrix"):
						board_node.remove_rider_from_matrix(self)
					
					if is_player_one: position = initial_position_e1
					else: position = initial_position_d1
					cont_same_color = 0
			else:
				capture_pieces(piece, rider_color)
				direction = piece.direction
				if board_node and board_node.has_method("register_rider_in_matrix"):
					board_node.register_rider_in_matrix(self, piece.grid_position.x, piece.grid_position.y)
					
func capture_pieces(captured_piece: Node, rider_color_that_captures: String) -> void:
	var same_color = (captured_piece.is_white == is_white)
	
	Gamemanager.process_capture(captured_piece.type_piece, same_color, rider_color_that_captures)
	
	captured_piece.queue_free()
