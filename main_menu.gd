extends Control

@export var main_game_path : String = "res://scenes/main.tscn"

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file(main_game_path)


func _on_exit_button_pressed() -> void:
	get_tree().quit()
