extends Node2D

var grid_position = Vector2i.ZERO
var is_white = true
var direction = 1

var type_piece: String = "king"


var health: int = 1

func _ready() -> void:
	_initialize_health()

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

func _exit_tree() -> void:
	if is_inside_tree() and get_node_or_null("/root/Main/CanvasLayer2/UIRoot/ScoreInterface"):
		var interfaz_score = get_node("/root/Main/CanvasLayer2/UIRoot/ScoreInterface")
		if interfaz_score != null:
			interfaz_score.show_end_game()
