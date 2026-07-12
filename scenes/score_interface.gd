extends Control

@onready var white_label: Label = $PanelContainer/HBoxContainer/WhiteLabel
@onready var black_label: Label = $PanelContainer/HBoxContainer/BlackLabel

func _process(_delta: float) -> void:
	var white_text = Gamemanager.format_points(Gamemanager.white_points)
	var black_text = Gamemanager.format_points(Gamemanager.black_points)
	
	white_label.text = "White Rider: " + white_text + " pts"
	black_label.text = "Black Rider: " + black_text + " pts"
