extends Node2D

const BOARD_SIZE = 8
const TILE_SIZE = 64

@onready var white_tile_texture=preload("res://Game assets/tile_white.png")
@onready var black_tile_texture=preload("res://Game assets/tile_black.png")
@onready var pawn_scene=preload("res://scenes/pawn/pawn.tscn")
@onready var white_pawn_tex="res://scenes/pawn/white_pawn.png"
@onready var black_pawn_tex="res://scenes/pawn/black_pawn.png"
@onready var horse_scene=preload("res://scenes/horse/horse.tscn")
@onready var black_horse_tex="res://scenes/horse/black_horse.png"
@onready var white_horse_tex="res://scenes/horse/white_horse.png"
@onready var bishop_scene=preload("res://scenes/bishop/bishop.tscn")
@onready var white_bishop_tex="res://scenes/bishop/white_bishop.png"
@onready var black_bishop_tex="res://scenes/bishop/black_bishop.png"
@onready var tower_scene=preload("res://tower/tower.tscn")
@onready var white_tower_tex="res://tower/white_tower.png"
@onready var black_tower_tex="res://tower/black_tower.png"



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
						
						if y == 2:
							if x>= 2 and x<= 5:
								current_piece = bishop_scene.instantiate()
								current_piece.grid_position = Vector2i(x, y)
								if(x + y) % 2 == 0:
									current_piece.set_side(true, white_tower_tex)
								else:
									current_piece.set_side(false, black_tower_tex)
						elif y == 3:
							if x >= 2 and x <= 5:
								current_piece = bishop_scene.instantiate()
								current_piece.grid_position = Vector2i(x, y)
								if(x + y) % 2 == 0:
										current_piece.set_side(true, white_bishop_tex)
								else:
										current_piece.set_side(false, black_bishop_tex)
							else:
								current_piece = null
						elif y == 4:
							if x >= 2 and x <= 5:
								current_piece = horse_scene.instantiate()
								current_piece.grid_position = Vector2i(x, y)
								if(x + y) % 2 == 0:
										current_piece.set_side(true, white_horse_tex)
								else:
										current_piece.set_side(false, black_horse_tex)
					
						elif y == 5 or y == 6:
								current_piece = pawn_scene.instantiate()
								current_piece.grid_position = Vector2i(x, y)
								if (x + y) % 2 == 0:
										current_piece.set_side(true, white_pawn_tex)
								else:
										current_piece.set_side(false, black_pawn_tex)
						else:
								current_piece = null
					
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
