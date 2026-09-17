extends Node2D

const BOARD_SIZE = 8
const TILE_SIZE = 64
const MAX_X_POSITION = 8 * 64
const TOTAL_BOARD_PIXELS_WITH_BORDERS = 592.0
const BORDER_OFFSET = 40.0
const PortalScript = preload("res://portal.gd")
const STEP_DELAY = 0.75

var movement_speed = 100.0
var board = []
var is_movement_active: bool = false
var paused_ranks = {}
var clock_label: Label = null
var board_color_side: String = "white"

var portal_timer: Timer
var active_portals: Array = []
var portal_spawn_timer: Timer
var portal_wait_states = {}

@onready var pawn_scene = preload("res://scenes/pawn/pawn.tscn")
@onready var knight_scene = preload("res://scenes/knight/knight.tscn")
@onready var bishop_scene = preload("res://scenes/bishop/bishop.tscn")
@onready var rook_scene = preload("res://scenes/rook/rook.tscn")
@onready var queen_scene = preload("res://scenes/queen/queen.tscn")
@onready var king_scene = preload("res://scenes/king/king.tscn")
@onready var main_character_scene = preload("res://scenes/main character/main character.tscn")

@onready var white_main_character_tex = "res://scenes/main character/White Rider.png"
@onready var black_main_character_tex = "res://scenes/main character/Black Rider.png"

func _ready():
	process_mode = Node.PROCESS_MODE_INHERIT
	await get_tree().process_frame
	
	if Global.selected_side == "black":
		board_color_side = "black"
	else:
		board_color_side = "white"
	
	if "2" in name:
		board_color_side = "black" if Global.total_players == 2 else "white"
	
	create_board()
	_setup_portal_timer()
	
	if get_tree().root:
		if get_tree().root.size_changed.is_connected(_adapt_to_viewport):
			get_tree().root.size_changed.disconnect(_adapt_to_viewport)
		get_tree().root.size_changed.connect(_adapt_to_viewport)
	
	_adapt_to_viewport()
	is_movement_active = false
	set_process(false)

func _spawn_piece(scene: PackedScene, type: String, is_white: bool, active_set: Dictionary) -> Node2D:
	var piece = scene.instantiate()
	piece.type_piece = type
	var tex_key = ""
	
	match type:
		"king": tex_key = "white_king" if is_white else "black_king"
		"queen": tex_key = "white_queen" if is_white else "black_queen"
		"rook": tex_key = "white_rook" if is_white else "black_rook"
		"bishop": tex_key = "white_bishop" if is_white else "black_bishop"
		"knight": tex_key = "white_knight" if is_white else "black_knight"
		"pawn": tex_key = "white_pawn" if is_white else "black_pawn"
		
	if active_set.has(tex_key):
		piece.set_side(is_white, active_set[tex_key])
	return piece

func create_board():
	board.clear()
	var active_set = Global.piece_sets[Global.current_set_name]
	var current_white_tile = load(active_set["white_tile"])
	var current_black_tile = load(active_set["black_tile"])
	
	for y in range(BOARD_SIZE):
		board.append([])
		for x in range(BOARD_SIZE):
			var current_piece = null
			var valid_column_king_queen = (x > 2 and x < 5)
			var is_valid_column = (x >= 2 and x <= 5)
			var should_be_white = ((x + y) % 2 == 0)

			if y == 0 and valid_column_king_queen:
				current_piece = _spawn_piece(king_scene, "king", should_be_white, active_set)
			elif y == 1 and valid_column_king_queen:
				current_piece = _spawn_piece(queen_scene, "queen", should_be_white, active_set)
			elif y == 2 and is_valid_column:
				current_piece = _spawn_piece(rook_scene, "rook", should_be_white, active_set)
			elif y == 3 and is_valid_column:
				current_piece = _spawn_piece(bishop_scene, "bishop", should_be_white, active_set)
			elif y == 4 and is_valid_column:
				current_piece = _spawn_piece(knight_scene, "knight", should_be_white, active_set)
			elif y == 5 or y == 6:
				current_piece = _spawn_piece(pawn_scene, "pawn", should_be_white, active_set)
			elif y == 7:
				if name == "Board2D_1":
					if x == 3:
						if Global.total_players == 2 or Global.selected_side == "black":
							current_piece = main_character_scene.instantiate()
							current_piece.is_white = false
							current_piece.set_side(false, black_main_character_tex)
					elif x == 4:
						if Global.total_players == 2 or Global.selected_side == "white":
							current_piece = main_character_scene.instantiate()
							current_piece.is_white = true
							current_piece.set_side(true, white_main_character_tex)

			if current_piece != null:
				current_piece.grid_position = Vector2i(x, y)
				if y % 2 != 0:
					current_piece.direction = -1
				else:
					current_piece.direction = 1

			board[y].append(current_piece)
			var new_tile = Sprite2D.new()
			if should_be_white:
				new_tile.texture = current_white_tile
			else:
				new_tile.texture = current_black_tile

			new_tile.position = Vector2((x * TILE_SIZE) + (TILE_SIZE / 2), (y * TILE_SIZE) + (TILE_SIZE / 2))
			add_child(new_tile)

			if current_piece != null:
				current_piece.position = new_tile.position
				add_child(current_piece)

func _wrap_x(pos_x: int) -> int:
	var max_pixel = BOARD_SIZE * TILE_SIZE 
	var wrapped = pos_x % max_pixel
	if wrapped < 0:
		wrapped += max_pixel
	return wrapped

var movement_timer = 0.0

func _process(delta):
	if not is_movement_active:
		return

	if is_movement_active and Gamemanager.active_game:
		var all_riders = get_tree().get_nodes_in_group("players")
		for rider in all_riders:
			if is_instance_valid(rider):
				if "is_white" in rider and rider.is_white and Gamemanager.white_clock_active:
					Gamemanager.white_time_left -= delta
					if Gamemanager.white_time_left <= 0:
						Gamemanager.white_time_left = 0.0
						Gamemanager.white_clock_active = false
				elif "is_white" in rider and not rider.is_white and Gamemanager.black_clock_active:
					Gamemanager.black_time_left -= delta
					if Gamemanager.black_time_left <= 0:
						Gamemanager.black_time_left = 0.0
						Gamemanager.black_clock_active = false
		
		if not Gamemanager.white_clock_active and not Gamemanager.black_clock_active:
			Gamemanager.active_game = false
			_trigger_global_game_over()

	movement_timer += delta

	if movement_timer >= STEP_DELAY:
		movement_timer = 0.0
		var next_positions = {}
		var casillas_ocupadas = {}

		var entidades_moviles = []
		for child in get_children():
			if is_instance_valid(child) and not child.is_queued_for_deletion():
				if "type_piece" in child and not child.is_in_group("players"):
					entidades_moviles.append(child)
					
		var players = get_tree().get_nodes_in_group("players")
		for player in players:
			if is_instance_valid(player) and "is_riding_rank" in player and player.is_riding_rank:
				if player.get_parent() == self:
					entidades_moviles.append(player)

		# 2. Todos respetan las mismas leyes (portales, límites y tráfico)
		for child in entidades_moviles:
			if not "direction" in child or child.direction == 0:
				continue
				
			var move_dir = child.direction
			var current_x = int(round(child.position.x))
			var current_y = int(round(child.position.y))
			
			var next_x = _wrap_x(current_x + (TILE_SIZE * move_dir))
			
			if child.get("type_piece") == "king":
				for player in players:
					if is_instance_valid(player) and "has_finished" in player and player.has_finished:
						if abs(next_x - player.position.x) < 5 and abs(current_y - player.position.y) < 5:
							next_x = _wrap_x(next_x + (TILE_SIZE * move_dir))
							break
							
			var attempts = 0
			while _is_portal_at(next_x, current_y) and attempts < 8:
				next_x = _wrap_x(next_x + (TILE_SIZE * move_dir))
				attempts += 1
			
			var casilla_destino = Vector2(next_x, current_y)
			
			if casillas_ocupadas.has(casilla_destino):
				next_positions[child] = current_x
				casillas_ocupadas[Vector2(current_x, current_y)] = true
			else:
				next_positions[child] = next_x
				casillas_ocupadas[casilla_destino] = true
			
		# 3. Aplicamos el movimiento asegurando la matriz
		for target in next_positions:
			if is_instance_valid(target) and not target.is_queued_for_deletion():
				var is_player = target.is_in_group("players")
				
				if is_player:
					remove_rider_from_matrix(target)
					if "previous_move_position" in target:
						target.previous_move_position = target.position

				target.position.x = next_positions[target]
				
				if "grid_position" in target:
					var new_grid_x = clamp(int(target.position.x / TILE_SIZE), 0, 7)
					target.grid_position = Vector2i(new_grid_x, target.grid_position.y)
				
				if is_player:
					register_rider_in_matrix(target, target.grid_position.x, target.grid_position.y)

func remove_rider():
	for y in range(BOARD_SIZE):
		for x in range(BOARD_SIZE):
			var piece = board[y][x]
			if is_instance_valid(piece) and piece.is_in_group("players"):
				board[y][x] = null
				if piece.get_parent() == self:
					remove_child(piece)
				return piece
	for child in get_children():
		if is_instance_valid(child) and child.is_in_group("players"):
			if child.get_parent() == self:
				remove_child(child)
			return child
	return null

func receive_rider(rider_node):
	if rider_node == null: return
	var target_x = 4 if rider_node.is_white else 3
	var target_y = 7
	board[target_y][target_x] = rider_node
	
	if "is_riding_rank" in rider_node: rider_node.is_riding_rank = false
	if "direction" in rider_node: rider_node.direction = 0
	if "auto_movement_timer" in rider_node: rider_node.auto_movement_timer = 0.0
	
	var local_pixel_pos = Vector2((target_x * TILE_SIZE) + (TILE_SIZE / 2), (target_y * TILE_SIZE) + (TILE_SIZE / 2))
	rider_node.position = local_pixel_pos
	if "grid_position" in rider_node: rider_node.grid_position = Vector2i(target_x, target_y)
	rider_node.global_scale = scale
	
	if rider_node:
		if "has_finished" in rider_node: rider_node.has_finished = false
		if rider_node.has_node("Area2D"):
			var rider_area = rider_node.get_node("Area2D")
			rider_area.monitoring = true
			rider_area.monitorable = true

func activate_piece_movement():
	is_movement_active = true

func register_rider_in_matrix(rider_node, x_pos: int, y_pos: int):
	if y_pos >= 0 and y_pos < 7 and x_pos >= 0 and x_pos < BOARD_SIZE:
		board[y_pos][x_pos] = rider_node

func remove_rider_from_matrix(rider_node):
	for y in range(7):
		for x in range(BOARD_SIZE):
			if board[y][x] == rider_node: board[y][x] = null

func print_board():
	for row in board: print(row)

func _adapt_to_viewport() -> void:
	var viewport_size = get_viewport_rect().size
	var left_margin = 15.0
	var ui_bottom_margin = 50.0
	var available_width = viewport_size.x - left_margin
	var available_height = viewport_size.y - ui_bottom_margin
	var scale_factor_x = available_width / ((TOTAL_BOARD_PIXELS_WITH_BORDERS * 3.2))
	var scale_factor_y = available_height / TOTAL_BOARD_PIXELS_WITH_BORDERS
	var final_scale = min(scale_factor_x, scale_factor_y)
	scale = Vector2(final_scale, final_scale)
	
	var board_real_size = TOTAL_BOARD_PIXELS_WITH_BORDERS * final_scale
	var dynamic_offset_x = left_margin + (BORDER_OFFSET * final_scale)
	var dynamic_offset_y = ((available_height - board_real_size) / 2.0) + (BORDER_OFFSET * final_scale)
	
	if name == "Board2D_2": dynamic_offset_x += board_real_size * 1.1
	elif name == "Board2D_3": dynamic_offset_x += board_real_size * 2.2
	
	position = Vector2(dynamic_offset_x, dynamic_offset_y)
	queue_redraw()
	
	if is_instance_valid(clock_label):
		var clock_x = dynamic_offset_x - (BORDER_OFFSET * scale.x) - (90.0 * scale.x)
		var clock_y = dynamic_offset_y + (3.9 * TILE_SIZE * scale.y)
		clock_label.global_position = Vector2(clock_x, clock_y)

func _draw() -> void:
	var fondo_rect = Rect2(Vector2(-BORDER_OFFSET, -BORDER_OFFSET), Vector2(TOTAL_BOARD_PIXELS_WITH_BORDERS, TOTAL_BOARD_PIXELS_WITH_BORDERS))
	draw_rect(fondo_rect, Color.BLACK, true)
	var letras = ["A", "B", "C", "D", "E", "F", "G", "H"]
	var numeros = ["8", "7", "6", "5", "4", "3", "2", "1"]
	var font_size = 18
	var text_color = Color.WHITE
	
	var temp_label = Label.new()
	var default_font = temp_label.get_theme_font("font")
	temp_label.free()
	
	for i in range(8):
		var texto = letras[i]
		var centro_x = (i * TILE_SIZE) + (TILE_SIZE / 2.0)
		var string_size = default_font.get_string_size(texto, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var pos_arriba = Vector2(centro_x - (string_size.x / 2.0), -20.0 + (string_size.y / 4.0))
		draw_string(default_font, pos_arriba, texto, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, text_color)
		var pos_abajo = Vector2(centro_x - (string_size.x / 2.0), 532.0 + (string_size.y / 4.0))
		draw_string(default_font, pos_abajo, texto, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, text_color)
	
	for i in range(8):
		var texto = numeros[i]
		var centro_y = (i * TILE_SIZE) + (TILE_SIZE / 2.0)
		var string_size = default_font.get_string_size(texto, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var pos_izquierda = Vector2(-20.0 - (string_size.x / 2.0), centro_y + (string_size.y / 4.0))
		draw_string(default_font, pos_izquierda, texto, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, text_color)
		var pos_derecha = Vector2(532.0 - (string_size.x / 2.0), centro_y + (string_size.y / 4.0))
		draw_string(default_font, pos_derecha, texto, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, text_color)

func pause_rank(rank_index: int, duration: float) -> void:
	paused_ranks[rank_index] = true
	for child in get_children():
		if "current_grid_y" in child and child.current_grid_y == rank_index:
			if child.has_method("set_paused"):
				child.set_paused(true)
	await get_tree().create_timer(duration).timeout
	paused_ranks[rank_index] = false
	for child in get_children():
		if "current_grid_y" in child and child.current_grid_y == rank_index:
			if child.has_method("set_paused"):
				child.set_paused(false)

func _trigger_global_game_over():
	get_tree().paused = true
	var score_interface = get_tree().current_scene.find_child("ScoreInterface", true, false)
	if score_interface:
		var game_over_menu = score_interface.find_child("GameOverMenu", true, false)
		if game_over_menu:
			game_over_menu.process_mode = Node.PROCESS_MODE_ALWAYS
			game_over_menu.visible = true

func _start_portal_waiting_phase():
	for p in active_portals:
		if is_instance_valid(p) and not p.is_queued_for_deletion(): p.despawn()
	active_portals.clear()
	if portal_timer: portal_timer.start(randf_range(3.0, 8.0))

func _generate_random_portals():
	_spawn_single_portal_pair()

func _setup_portal_timer():
	portal_spawn_timer = Timer.new()
	portal_spawn_timer.timeout.connect(_on_portal_spawn_tick)
	add_child(portal_spawn_timer)
	
	portal_timer = Timer.new()
	portal_timer.one_shot = true
	add_child(portal_timer)
	_on_portal_spawn_tick()

func _on_portal_spawn_tick():
	for i in range(active_portals.size() - 1, -1, -1):
		if not is_instance_valid(active_portals[i]): active_portals.remove_at(i)
		
	if active_portals.size() < 6:
		var pairs_to_spawn = 1 if randf() > 0.5 else 2
		for i in range(pairs_to_spawn):
			if active_portals.size() >= 6: break
			_spawn_single_portal_pair()
	portal_spawn_timer.start(randf_range(5.0, 12.0))

func _spawn_single_portal_pair():
	var valid_tiles = []
	for r in range(1, 7):
		for c in range(8):
			if _is_tile_empty(c, r):
				valid_tiles.append(Vector2i(c, r))
	
	if valid_tiles.size() < 2: return
	
	var active_colors = []
	for p in active_portals:
		if is_instance_valid(p) and "galaxy_color" in p and not p.galaxy_color in active_colors:
			active_colors.append(p.galaxy_color)
	
	var all_colors = [Color.RED, Color.CYAN, Color.PURPLE]
	var available_colors = []
	for c in all_colors:
		if not c in active_colors: available_colors.append(c)
	
	if available_colors.is_empty(): return
	
	valid_tiles.shuffle()
	var source_grid = valid_tiles.pop_back()
	var target_grid = valid_tiles.pop_back()
	
	var pair_color = available_colors[randi() % available_colors.size()]
	var cycle_time = 8 * STEP_DELAY
	var lifetime = cycle_time * randi_range(3, 5)
	
	var entry_portal = PortalScript.new()
	entry_portal.galaxy_color = pair_color
	entry_portal.position = Vector2(source_grid.x * 64 + 32.0, source_grid.y * 64.0 + 32.0)
	entry_portal.grid_position = source_grid
	
	var exit_portal = PortalScript.new()
	exit_portal.galaxy_color = pair_color
	exit_portal.position = Vector2(target_grid.x * 64.0 + 32.0, target_grid.y * 64.0 + 32.0)
	exit_portal.grid_position = target_grid
	
	entry_portal.destination = exit_portal
	exit_portal.destination = entry_portal
	
	add_child(entry_portal)
	add_child(exit_portal)
	active_portals.append(entry_portal)
	active_portals.append(exit_portal)
	
	entry_portal.set_lifetime(lifetime)
	exit_portal.set_lifetime(lifetime)
	
func _is_tile_empty(col: int, row: int) -> bool:
	var target_pos = Vector2(col * 64.0 + 32.0, row * 64.0 + 32.0)
	for p in active_portals:
		if is_instance_valid(p) and not p.is_queued_for_deletion():
			if p.position.distance_to(target_pos) < 32.0: return false
	for child in get_children():
		if is_instance_valid(child) and not child.is_queued_for_deletion() and not child.is_in_group("players"):
			if "type_piece" in child and "position" in child:
				if child.position.distance_to(target_pos) < 32.0: return false
	return true

func _is_position_occupied(pos_x: float, pos_y: float, exclude_piece) -> bool:
	var margin = 5.0
	for child in get_children():
		if is_instance_valid(child) and child != exclude_piece and "type_piece" in child and not child.is_in_group("players"):
			if abs(child.position.x - pos_x) < margin and abs(child.position.y - pos_y) < margin: return true
	return false

func _is_portal_at(pos_x: float, pos_y: float) -> bool:
	for p in get_tree().get_nodes_in_group("portals"):
		if is_instance_valid(p) and not p.is_queued_for_deletion():
			if "is_despawning" in p and p.is_despawning: continue 
			if abs(p.position.x - pos_x) < 15.0 and abs(p.position.y - pos_y) < 15.0:
				return true
	return false
