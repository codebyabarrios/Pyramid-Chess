extends Node2D

const BOARD_SIZE = 8
const TILE_SIZE = 64

@onready var white_tile_texture=preload("res://Assets juego/tile_white.png")
@onready var black_tile_texture=preload("res://Assets juego/tile_black.png")
var board = []

func _ready():
	create_board()
	print_board()

func create_board():
	board.clear()
	for y in range(BOARD_SIZE):
		board.append([])
		for x in range(BOARD_SIZE):
			board[y].append(null)
			
			var new_tile = Sprite2D.new()
			if(x+ y)%2==0:
				new_tile.texture = white_tile_texture
			else:
				new_tile.texture=black_tile_texture
			
			new_tile.scale = Vector2(1, 1) 
			
			
			new_tile.position = Vector2(
				(x * TILE_SIZE) + (TILE_SIZE / 2),
				(y * TILE_SIZE) + (TILE_SIZE / 2)
			)
			
			add_child(new_tile)

func print_board():
	for row in board:
		print(row)
