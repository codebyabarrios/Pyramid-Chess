extends Node2D

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

func _on_area_entered(touched_area: Area2D):
	var piece = touched_area.get_parent()
	
	if piece != null:
		var board_node = get_parent()
		var rider_color = "white" if is_white else "black"
		
		if piece.is_white == is_white:
			capture_pieces(piece, rider_color)
			
			cont_same_color += 1
			position.y += TILE_SIZE
			if cont_same_color >= 3:
				
				if board_node and board_node.has_method("remove_rider_from_matrix"):
					board_node.remove_rider_from_matrix(self)
				
				if is_player_one:
					position = initial_position_e1
				else:
					position = initial_position_d1
				
				cont_same_color = 0
		else:
			capture_pieces(piece, rider_color)
			direction = piece.direction
			if board_node and board_node.has_method("register_rider_in_matrix"):
				board_node.register_rider_in_matrix(self, piece.grid_position.x, piece.grid_position.y)
			

func capture_pieces(captured_piece: Node, rider_color_that_captures: String):
	var same_color = (captured_piece.is_white == is_white)
	
	Gamemanager.process_capture(captured_piece.type_piece, same_color, rider_color_that_captures)
	
	captured_piece.queue_free()
