extends Control

@onready var white_label: Label = $PanelContainer/HBoxContainer/WhiteLabel
@onready var black_label: Label = $PanelContainer/HBoxContainer/BlackLabel
@onready var game_over_menu = $GameOverMenu

func _ready():
	if game_over_menu != null:
		game_over_menu.process_mode = Node.PROCESS_MODE_ALWAYS
		
	var restart_button = game_over_menu.get_node("RestartButton")
	if restart_button and not restart_button.pressed.is_connected(_on_restart_button_pressed):
		restart_button.pressed.connect(_on_restart_button_pressed)
	
	await get_tree().process_frame
	update_score_labels()
	
func update_score_labels() -> void:
	if not is_instance_valid(white_label) or not is_instance_valid(black_label):
		return
		
	var white_text = Gamemanager.format_points(Gamemanager.white_points)
	var black_text = Gamemanager.format_points(Gamemanager.black_points)
	
	white_label.text = "White Rider: " + white_text + " pts"
	black_label.text = "Black Rider: " + black_text + " pts"

func show_end_game():
	if not Gamemanager.active_game:
		return 
		
	if game_over_menu != null:
		game_over_menu.visible = true
		
		var board_node = get_tree().current_scene.get_node_or_null("Board2D")
		if board_node:
			board_node.process_mode = Node.PROCESS_MODE_DISABLED


func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	
	Gamemanager.white_points = 10.0
	Gamemanager.black_points = 10.0
	Gamemanager.active_game = false
	
	get_tree().call_deferred("change_scene_to_file", "res://scenes/main.tscn")
	
	queue_free()
