extends CanvasLayer

func _ready():
	hide()
	
	var boton_pausa = get_tree().root.find_child("PauseMenu2", true, false)
	if boton_pausa and not boton_pausa.pressed.is_connected(_on_pause_button_pressed):
		boton_pausa.pressed.connect(_on_pause_button_pressed)
	
	var boton_resume = find_child("ResumeButton", true, false)
	if boton_resume and not boton_resume.pressed.is_connected(_on_resume_button_pressed):
		boton_resume.pressed.connect(_on_resume_button_pressed)
	
	var boton_audio = find_child("AudioButton", true, false)
	if boton_audio and not boton_audio.pressed.is_connected(_on_audio_button_pressed):
		boton_audio.pressed.connect(_on_audio_button_pressed)
	
	var boton_menu = find_child("MenuButton", true, false)
	if boton_menu and not boton_menu.pressed.is_connected(_on_menu_button_pressed):
		boton_menu.pressed.connect(_on_menu_button_pressed)


func _on_pause_button_pressed():
	show()
	get_tree().paused = true

func _on_resume_button_pressed():
	hide()
	get_tree().paused = false

func _on_audio_button_pressed():
	var master_bus = AudioServer.get_bus_index("Master")
	var is_muted = AudioServer.is_bus_mute(master_bus)
	
	AudioServer.set_bus_mute(master_bus, not is_muted)

func _on_menu_button_pressed():
	get_tree().paused = false 
	get_tree().change_scene_to_file("res://MainMenu.tscn")
