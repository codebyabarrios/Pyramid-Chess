extends Control

@export var main_game_path : String = "res://scenes/main.tscn"

@onready var start_menu = $HomeMenu
@onready var player_count_menu = $MenuQuantity
@onready var side_selection_menu = $SideMenu


func _on_play_button_pressed() -> void:
	start_menu.visible = false
	player_count_menu.visible = true

func _on_exit_button_pressed() -> void:
	get_tree().quit()

func _on_btn_2_players_pressed() -> void:
	Global.total_players = 2
	start_game()


func _on_btn_1_player_pressed() -> void:
	Global.total_players = 1
	player_count_menu.visible = false
	side_selection_menu.visible = true


func _on_btn_white_rider_pressed() -> void:
	Global.selected_side = "white"
	start_game()


func _on_btn_black_rider_pressed() -> void:
	Global.selected_side = "black"
	start_game()


func _on_btn_back_pressed() -> void:
	side_selection_menu.visible = false
	player_count_menu.visible = true

func start_game() -> void:
	get_tree().change_scene_to_file(main_game_path)
