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

var movement_timer = 0.0
var _riders_spawned: bool = false

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
	sync_round_state()

func _is_current_round_board() -> bool:
	return name == "Board2D_1" and Gamemanager.current_board >= 1 and Gamemanager.current_board <= Gamemanager.MAX_BOARDS

func reset_for_new_round() -> void:
	var saved_riders: Array[Node] = []
	for rider in get_tree().get_nodes_in_group("players"):
		if is_instance_valid(rider) and not rider.is_queued_for_deletion():
			if rider.get_parent() == self:
				remove_child(rider)
			if not saved_riders.has(rider):
				saved_riders.append(rider)

	for p in active_portals:
		if is_instance_valid(p) and not p.is_queued_for_deletion():
			p.queue_free()
	active_portals.clear()

	for child in get_children():
		if not is_instance_valid(child) or child.is_queued_for_deletion():
			continue
		if child == portal_spawn_timer or child == portal_timer or child == clock_label:
			continue
		child.queue_free()

	movement_timer = 0.0
	paused_ranks.clear()

	create_board()

	for rider in saved_riders:
		if is_instance_valid(rider):
			if rider.get_parent() != self:
				add_child(rider)
			if "has_finished" in rider: rider.has_finished = false
			if "is_frozen" in rider: rider.is_frozen = false
			if "is_riding_rank" in rider: rider.is_riding_rank = false
			if "direction" in rider: rider.direction = 0
			if "buffered_move_direction" in rider: rider.buffered_move_direction = Vector2.ZERO
			if "is_waiting_for_input" in rider: rider.is_waiting_for_input = false
			if "input_buffer_timer" in rider: rider.input_buffer_timer = 0.0
			receive_rider(rider)

	_adapt_to_viewport()
	sync_round_state()

func sync_round_state() -> void:
	var es_este_tablero := _is_current_round_board()
	is_movement_active = es_este_tablero
	set_process(es_este_tablero)
	visible = es_este_tablero
	modulate = Color.WHITE

	if portal_spawn_timer:
		portal_spawn_timer.paused = not es_este_tablero
		if es_este_tablero and portal_spawn_timer.is_stopped():
			portal_spawn_timer.start(randf_range(5.0, 12.0))

	if portal_timer:
		portal_timer.paused = not es_este_tablero

	if not es_este_tablero:
		for p in active_portals:
			if is_instance_valid(p) and not p.is_queued_for_deletion():
				p.queue_free()
		active_portals.clear()

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
				if name == "Board2D_1" and not _riders_spawned:
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

	if name == "Board2D_1":
		_riders_spawned = true

func _wrap_x(pos_x: int) -> int:
	var max_pixel = BOARD_SIZE * TILE_SIZE
	var wrapped = pos_x % max_pixel
	if wrapped < 0:
		wrapped += max_pixel
	return wrapped

func _grid_to_pos(col: int, row: int) -> Vector2:
	return Vector2(col * TILE_SIZE + TILE_SIZE * 0.5, row * TILE_SIZE + TILE_SIZE * 0.5)

func _pos_to_grid(pos: Vector2) -> Vector2i:
	var col := wrapi(int(floor(pos.x / TILE_SIZE)), 0, BOARD_SIZE)
	var row := clampi(int(floor(pos.y / TILE_SIZE)), 0, BOARD_SIZE - 1)
	return Vector2i(col, row)

func _has_portal_at_cell(col: int, row: int) -> bool:
	var target_cell := Vector2i(wrapi(col, 0, BOARD_SIZE), clampi(row, 0, BOARD_SIZE - 1))
	for p in get_tree().get_nodes_in_group("portals"):
		if not is_instance_valid(p) or p.is_queued_for_deletion():
			continue
		if p.get_parent() != self:
			continue
		if p.get("is_despawning") == true:
			continue
		var portal_cell := target_cell
		if "grid_position" in p and p.grid_position != Vector2i(-1, -1):
			portal_cell = p.grid_position
		else:
			portal_cell = _pos_to_grid(p.position)
		if portal_cell == target_cell:
			return true
	return false

func _step_horizontal_movement() -> void:
	var movers: Array = []
	for child in get_children():
		if is_instance_valid(child) and not child.is_queued_for_deletion():
			if "type_piece" in child and not child.is_in_group("players"):
				if "direction" in child and child.direction != 0 and not movers.has(child):
					movers.append(child)

	for player in get_tree().get_nodes_in_group("players"):
		if is_instance_valid(player) and player.get_parent() == self:
			if "is_riding_rank" in player and player.is_riding_rank:
				if "direction" in player and player.direction != 0 and not movers.has(player):
					movers.append(player)

	var desired_cells := {}
	for mover in movers:
		var cell := _pos_to_grid(mover.position)
		var dir: int = 1 if mover.direction > 0 else -1
		var target_col := wrapi(cell.x + dir, 0, BOARD_SIZE)

		var safety := 0
		while _has_portal_at_cell(target_col, cell.y) and safety < BOARD_SIZE:
			target_col = wrapi(target_col + dir, 0, BOARD_SIZE)
			safety += 1

		desired_cells[mover] = Vector2i(target_col, cell.y)

	var occupied_targets := {}
	var final_cells := {}
	for mover in movers:
		var current_cell := _pos_to_grid(mover.position)
		var want_cell: Vector2i = desired_cells[mover]
		if not occupied_targets.has(want_cell):
			occupied_targets[want_cell] = true
			final_cells[mover] = want_cell
		else:
			occupied_targets[current_cell] = true
			final_cells[mover] = current_cell

	for mover in movers:
		var old_cell := _pos_to_grid(mover.position)
		var new_cell: Vector2i = final_cells[mover]
		var is_player: bool = mover.is_in_group("players")

		if is_player:
			remove_rider_from_matrix(mover)
			if "previous_move_position" in mover:
				mover.previous_move_position = mover.position
		elif old_cell.y >= 0 and old_cell.y < BOARD_SIZE and old_cell.x >= 0 and old_cell.x < BOARD_SIZE:
			if board[old_cell.y][old_cell.x] == mover:
				board[old_cell.y][old_cell.x] = null

		mover.position = _grid_to_pos(new_cell.x, new_cell.y)
		if "grid_position" in mover:
			mover.grid_position = new_cell

		if is_player:
			register_rider_in_matrix(mover, new_cell.x, new_cell.y)
		else:
			board[new_cell.y][new_cell.x] = mover

func _process(delta):
	if not is_movement_active or not _is_current_round_board():
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
		_step_horizontal_movement()

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
	sync_round_state()

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
	if not _is_current_round_board():
		return

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
			if p.get_parent() != self: continue
			if "is_despawning" in p and p.is_despawning: continue
			if abs(p.position.x - pos_x) < 15.0 and abs(p.position.y - pos_y) < 15.0:
				return true
	return false
