extends Node2D

@onready var label = $Label
@onready var anim_player = $show

func _ready():
	if anim_player != null:
		anim_player.play("show")

func start(text_to_show: String, color: Color = Color.WHITE):
	if label != null:
		label.text = text_to_show
		label.modulate = color

func _on_animation_player_animation_finished(_anim_name):
	queue_free()
