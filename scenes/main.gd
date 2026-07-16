extends Node2D

@onready var container = $CanvasLayer2/HBoxContainer/SubViewportContainer
@onready var viewport = $CanvasLayer2/HBoxContainer/SubViewportContainer/SubViewport

func _ready():
	Gamemanager.game_active = false
	
	container.stretch = false
	
	if get_tree().root:
		get_tree().root.size_changed.connect(_on_window_resized)
	
	_on_window_resized()
	
	await get_tree().create_timer(0.1).timeout
	
	Gamemanager.game_active = true

func _on_window_resized():
	await get_tree().process_frame
	
	viewport.size = container.size
