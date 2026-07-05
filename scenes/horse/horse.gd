extends Node2D

var grid_position = Vector2i.ZERO
var is_white = true
var direction = 1 

const TILE_SIZE = 64
const MAX_X_POSITION = 8 * 64
const MOVEMENT_SPEED = 100.0

func _process(delta):
	position.x += MOVEMENT_SPEED * delta * direction
	
	var left_limit = TILE_SIZE / 2                
	var right_limit = MAX_X_POSITION - (TILE_SIZE / 2) 
	
	if position.x >= right_limit:
		position.x = right_limit
		direction = -1
		
	elif position.x <= left_limit:
		position.x = left_limit
		direction = 1

func set_side(white: bool, texture_path: String):
	is_white = white
	$Sprite2D.texture = load(texture_path)
