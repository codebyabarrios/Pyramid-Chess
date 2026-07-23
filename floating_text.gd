extends Node2D

@onready var label = $Label
@onready var anim_player = $show

func _ready():
	if anim_player != null:
		if not anim_player.animation_finished.is_connected(_on_animation_player_animation_finished):
			anim_player.animation_finished.connect(_on_animation_player_animation_finished)
		anim_player.play("show")

func start(text_to_show: String, color: Color = Color.WHITE):
	if label != null:
		label.text = text_to_show
		label.self_modulate = color

func _on_animation_player_animation_finished(_anim_name):
	queue_free()
