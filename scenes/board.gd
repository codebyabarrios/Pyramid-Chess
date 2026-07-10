extends Node2D

const BOARD_SIZE = 8
const TILE_SIZE = 64
const MAX_X_POSITION = 8 * 64 

var movement_speed = 100.0
var board = []

@onready var white_tile_texture = preload("res://Game assets/tile_white.png")
@onready var black_tile_texture = preload("res://Game assets/tile_black.png")

@onready var pawn_scene = preload("res://scenes/pawn/pawn.tscn")
@onready var white_pawn_tex = "res://scenes/pawn/white_pawn.png"
@onready var black_pawn_tex = "res://scenes/pawn/black_pawn.png"

@onready var knight_scene = preload("res://scenes/knight/knight.tscn")
@onready var black_knight_tex = "res://scenes/knight/black_knight.png"
@onready var white_knight_tex = "res://scenes/knight/white_horse.png"

@onready var bishop_scene = preload("res://scenes/bishop/bishop.tscn")
@onready var white_bishop_tex = "res://scenes/bishop/white_bishop.png"
@onready var black_bishop_tex = "res://scenes/bishop/black_bishop.png"

@onready var rook_scene = preload("res://scenes/rook/rook.tscn")
@onready var white_rook_tex = "res://scenes/rook/white_rook.png"
@onready var black_rook_tex = "res://scenes/rook/black_rook.png"

@onready var queen_scene = preload("res://scenes/queen/queen.tscn")
@onready var white_queen_tex = "res://scenes/queen/white_queen.png"
@onready var black_queen_tex = "res://scenes/queen/black_queen.png"

@onready var king_scene = preload("res://scenes/king/king.tscn")
@onready var white_king_tex = "res://scenes/king/white_king.png"
@onready var black_king_tex = "res://scenes/king/black_king.png"

@onready var main_character_scene = preload("res://scenes/main character/main character.tscn")
@onready var white_main_character_tex = "res://scenes/main character/white-main_character.png"
@onready var black_main_character_tex = "res://scenes/main character/black_main_character.png"

func _ready():
	create_board()
	print_board()

func create_board():
	board.clear()
	for y in range(BOARD_SIZE):
		board.append([])
		for x in range(BOARD_SIZE):
			
			var current_piece = null
			var is_valid_column = (x >= 2 and x <= 5)
			var should_be_white = ((x + y) % 2 == 0)
			
			if y == 0 and is_valid_column:
				current_piece = king_scene.instantiate()
				current_piece.type_piece = "king"
				if should_be_white: 
					current_piece.set_side(true, white_king_tex)
				else: 
					current_piece.set_side(false, black_king_tex)
					
			elif y == 1 and is_valid_column:
				current_piece = queen_scene.instantiate()
				current_piece.type_piece = "queen"
				if should_be_white: 
					current_piece.set_side(true, white_queen_tex)
				else: 
					current_piece.set_side(false, black_queen_tex)
						
			elif y == 2 and is_valid_column:
				current_piece = rook_scene.instantiate()
				current_piece.type_piece = "rook"
				if should_be_white: 
					current_piece.set_side(true, white_rook_tex)
				else: 
					current_piece.set_side(false, black_rook_tex)
								
			elif y == 3 and is_valid_column:
				current_piece = bishop_scene.instantiate()
				current_piece.type_piece = "bishop"
				if should_be_white: 
					current_piece.set_side(true, white_bishop_tex)
				else: 
					current_piece.set_side(false, black_bishop_tex)

			elif y == 4 and is_valid_column:
				current_piece = knight_scene.instantiate()
				current_piece.type_piece = "horse"
				if should_be_white: 
					current_piece.set_side(true, white_knight_tex)
				else: 
					current_piece.set_side(false, black_knight_tex)
				
			elif y == 5 or y == 6:
				current_piece = pawn_scene.instantiate()
				current_piece.type_piece = "pawn"
				if should_be_white: 
					current_piece.set_side(true, white_pawn_tex)
				else: 
					current_piece.set_side(false, black_pawn_tex)
			
			elif y == 7:
					if x == 3:
						current_piece = main_character_scene.instantiate()
						current_piece.is_white = false
						current_piece.set_side(false, black_main_character_tex)
					elif x == 4:
						current_piece = main_character_scene.instantiate()
						current_piece.is_white = true
						current_piece.set_side(true, white_main_character_tex)
			else:
				current_piece = null
			
			if current_piece != null:
				current_piece.grid_position = Vector2i(x, y)
				
				if y % 2 != 0:
					current_piece.direction = -1
				else:
					current_piece.direction = 1
					
			board[y].append(current_piece)
			
			var new_tile = Sprite2D.new()
			if (x + y) % 2 == 0: new_tile.texture = white_tile_texture
			else: new_tile.texture = black_tile_texture
			new_tile.position = Vector2((x * TILE_SIZE) + (TILE_SIZE / 2), (y * TILE_SIZE) + (TILE_SIZE / 2))
			add_child(new_tile)
			
			if current_piece != null:
				current_piece.position = new_tile.position
				add_child(current_piece)


var movement_timer = 0.0
const STEP_DELAY = 0.75

func _process(delta):
	movement_timer += delta
	
	if movement_timer >= STEP_DELAY:
		movement_timer = 0.0
		
		for y in range(7):
			for x in range(BOARD_SIZE):
				var target = board[y][x]
				
				if target != null:
					var move_dir = target.direction
					target.position.x += TILE_SIZE * move_dir
				
					if move_dir == 1:
						if target.position.x > MAX_X_POSITION:
							target.position.x -= MAX_X_POSITION
					
					elif move_dir == -1:
						if target.position.x < 0:
							target.position.x += MAX_X_POSITION

func register_rider_in_matrix(rider_node: Node2D, x_pos: int, y_pos: int):
	if y_pos >= 0 and y_pos < 7 and x_pos >= 0 and x_pos < BOARD_SIZE:
		board[y_pos][x_pos] = rider_node
		
func remove_rider_from_matrix(rider_node: Node2D):
	for y in range(7):
		for x in range(BOARD_SIZE):
			if board[y][x] == rider_node:
				board[y][x] = null


func print_board():
	for row in board:
		print(row)
