extends Node2D

var grid_position = Vector2i.ZERO
var is_white = true
var direction = 1

# Interruptor para saber si es el Jugador 1 (WASD) o el Jugador 2 (Flechas)
var is_player_one = true

const TILE_SIZE = 64

func _ready():
	# Conectamos la colisión para comer piezas
	$Area2D.area_entered.connect(_on_area_entered)

func set_side(white: bool, texture_path: String):
	is_white = white
	# Si se configura como blanco (true), será el Jugador 2 (Flechas)
	# Si se configura como negro (false), será el Jugador 1 (WASD)
	is_player_one = !white
	$Sprite2D.texture = load(texture_path)

func _process(delta):
	var move_direction = Vector2.ZERO
	
	if is_player_one:
		if Input.is_action_just_pressed("p1_right"): 
			move_direction.x = 1
		if Input.is_action_just_pressed("p1_left"):  
			move_direction.x = -1
		if Input.is_action_just_pressed("p1_up"):    
			move_direction.y = -1
	else:
		if Input.is_action_just_pressed("p2_right"): 
			move_direction.x = 1
		if Input.is_action_just_pressed("p2_left"):  
			move_direction.x = -1
		if Input.is_action_just_pressed("p2_up"):    
			move_direction.y = -1
	
	if move_direction != Vector2.ZERO:
		position.x += move_direction.x * TILE_SIZE
		position.y += move_direction.y * TILE_SIZE
	
func _on_area_entered(area_que_tocamos: Area2D):
	var piece = area_que_tocamos.get_parent()
	if piece != null:
		piece.queue_free()
