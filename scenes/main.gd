extends Node2D

@onready var container = $CanvasLayer2/HBoxContainer/SubViewportContainer
@onready var viewport = $CanvasLayer2/HBoxContainer/SubViewportContainer/SubViewport

func _ready():
	container.stretch = false
	
	if get_tree().root:
		get_tree().root.size_changed.connect(_on_window_resized)
	
	_on_window_resized()

func _on_window_resized():
	await get_tree().process_frame
	
	viewport.size = container.size
