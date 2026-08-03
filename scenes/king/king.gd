extends Node2D

var grid_position = Vector2i.ZERO
var is_white = true
var direction = 1

var type_piece: String = "king"

const TILE_SIZE = 64

var health: int = 1

var is_already_captured: bool = false

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

func mark_as_captured() -> bool:
	if is_already_captured:
		return false
	
	is_already_captured = true
	if is_in_group("chess_pieces"):
		remove_from_group("chess_pieces")
	return true
	

func _exit_tree() -> void:
	pass
