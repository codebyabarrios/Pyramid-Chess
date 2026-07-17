extends Node2D

var grid_position = Vector2i.ZERO
var is_white = true
var direction = 1

var type_piece: String = "rook"

var health: int = 1

const TILE_SIZE = 64

func _ready() -> void:
	_initialize_health()
	
	add_to_group("chess_pieces")
	
	var grid_real_pos = position - Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
	grid_position = Vector2i(round(grid_real_pos.x / TILE_SIZE), round(grid_real_pos.y / TILE_SIZE))
	
func _initialize_health() -> void:
	match type_piece:
		"pawn": health = 1
		"knight": health = 3
		"bishop": health = 3
		"rook": health = 5
		"queen": health = 9
		
func set_side(white: bool, texture_path: String) -> void:
	is_white = white
	$Sprite2D.texture = load(texture_path)
