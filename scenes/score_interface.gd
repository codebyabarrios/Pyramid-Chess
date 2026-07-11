extends Control

@onready var white_label: Label = $PanelContainer/VBoxContainer/WhiteLabel
@onready var black_label: Label = $PanelContainer/VBoxContainer/BlackLabel

func _process(_delta: float) -> void:
	white_label.text  = "White Rider: " + str(round(Gamemanager.white_points)) + " pts"
	black_label.text = "Black Rider: " + str(round(Gamemanager.black_points)) + " pts"
