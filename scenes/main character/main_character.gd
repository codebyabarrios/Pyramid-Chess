extends Node2D

var grid_position = Vector2i.ZERO
var is_white = true
var direction = 1

# Interruptor para saber si es el Jugador 1 (WASD) o el Jugador 2 (Flechas)
var is_player_one = true

const SPEED = 200.0

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
	var input_vector = Vector2.ZERO
	
	if is_player_one:
		if Input.is_action_pressed("p1_right"): 
			input_vector.x += 1
		if Input.is_action_pressed("p1_left"):  
			input_vector.x -= 1
		if Input.is_action_pressed("p1_up"):    
			input_vector.y -= 1
	else:
		if Input.is_action_pressed("p2_right"): 
			input_vector.x += 1
		if Input.is_action_pressed("p2_left"):  
			input_vector.x -= 1
		if Input.is_action_pressed("p2_up"):    
			input_vector.y -= 1
		
	if input_vector != Vector2.ZERO:
		position += input_vector.normalized() * SPEED * delta

func _on_area_entered(area_que_tocamos: Area2D):
	var piece = area_que_tocamos.get_parent()
	if piece != null:
		piece.queue_free()
