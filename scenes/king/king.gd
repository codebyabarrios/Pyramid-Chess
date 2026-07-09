extends Node2D

var grid_position = Vector2i.ZERO
var is_white = true
var direction = 1

var type_piece: String = "king"

func set_side(white: bool, texture_path: String):
	is_white = white
	$Sprite2D.texture = load(texture_path)
