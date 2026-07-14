extends Control

@onready var white_label: Label = $PanelContainer/HBoxContainer/WhiteLabel
@onready var black_label: Label = $PanelContainer/HBoxContainer/BlackLabel
@onready var game_over_menu = $GameOverMenu

func _ready():
	var restart_button = game_over_menu.get_node("RestartButton")
	if restart_button and not restart_button.pressed.is_connected(_on_restart_button_pressed):
		restart_button.pressed.connect(_on_restart_button_pressed)

func _process(_delta: float) -> void:
	var white_text = Gamemanager.format_points(Gamemanager.white_points)
	var black_text = Gamemanager.format_points(Gamemanager.black_points)
	
	white_label.text = "White Rider: " + white_text + " pts"
	black_label.text = "Black Rider: " + black_text + " pts"

func show_end_game():
	if game_over_menu != null:
		game_over_menu.visible = true
		get_tree().paused = true


func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
