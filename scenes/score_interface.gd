extends Control

@onready var white_label: Label = $PanelContainer/HBoxContainer/WhiteLabel
@onready var black_label: Label = $PanelContainer/HBoxContainer/BlackLabel
@onready var game_over_menu = $GameOverMenu

var is_transitioning: bool = false

func _ready():
	if game_over_menu != null:
		game_over_menu.process_mode = Node.PROCESS_MODE_ALWAYS
		game_over_menu.visible = false
		
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

func show_end_game(attacking_rider: Node2D):
	if is_transitioning:
		return
	
	if Gamemanager.current_board < Gamemanager.MAX_BOARDS:
		Gamemanager.current_board += 1
		call_deferred("advance_to_next_board_with_rider", attacking_rider)
		return 
		
	if not Gamemanager.active_game:
		return 
	
	is_transitioning = true
	await get_tree().create_timer(1.5).timeout
	if game_over_menu != null:
		game_over_menu.visible = true
		for i in range(1, 4):
			var board_node = get_node_or_null("/root/Main/Board2D_" + str(i))
			if board_node:
				board_node.process_mode = Node.PROCESS_MODE_DISABLED

func advance_to_next_board_with_rider(rider: Node2D):
	var old_board = get_node_or_null("/root/Main/Board2D_" + str(Gamemanager.current_board - 1))
	var new_board = get_node_or_null("/root/Main/Board2D_" + str(Gamemanager.current_board))
	
	if old_board and new_board and is_instance_valid(rider):
		if old_board.has_method("remove_rider_from_matrix"):
			old_board.remove_rider_from_matrix(rider)
			
		rider.reparent(new_board)
		
		new_board.receive_rider(rider) 
		
		new_board.activate_piece_movement()
	
	is_transitioning = false
		
func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	Gamemanager.reset_game()
	get_tree().call_deferred("change_scene_to_file", "res://scenes/main.tscn")
	queue_free()
