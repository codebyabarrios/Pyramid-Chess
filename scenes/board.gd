extends Node2D

const BOARD_SIZE = 8
const TILE_SIZE = 64

@onready var white_tile_texture=preload("res://Assets juego/tile_white.png")
@onready var black_tile_texture=preload("res://Assets juego/tile_black.png")
@onready var pawn_scene=preload("res://scenes/pawn/pawn.tscn")
@onready var white_pawn_tex="res://scenes/pawn/white_pawn.png"
@onready var black_pawn_tex="res://scenes/pawn/black_pawn.png"

var board = []

func _ready():
	create_board()
	print_board()

func create_board():
	board.clear()
	for y in range(BOARD_SIZE):
		board.append([])
		
		for x in range(BOARD_SIZE):
			
			var current_piece = null
			
			if y == 1:
				current_piece = pawn_scene.instantiate()
				current_piece.set_side(false, black_pawn_tex)
				current_piece.grid_position = Vector2i(x, y)
			
			elif y == 6:
				current_piece = pawn_scene.instantiate()
				current_piece.set_side(true, white_pawn_tex)
				current_piece.grid_position = Vector2i(x, y)
				
			board[y].append(current_piece)
			
			var new_tile = Sprite2D.new()
			if(x + y) % 2 == 0:
				new_tile.texture = white_tile_texture
			else:
				new_tile.texture = black_tile_texture
			
			new_tile.position = Vector2(
				(x * TILE_SIZE) + (TILE_SIZE / 2),
				(y * TILE_SIZE) + (TILE_SIZE / 2)
			)
			
			add_child(new_tile)
			
			if board[y][x] != null:
				board[y][x].position = new_tile.position
				add_child(board[y][x])


func print_board():
	for row in board:
		print(row)
