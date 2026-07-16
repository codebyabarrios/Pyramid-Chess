extends Node

var white_points: float = 10.0
var black_points: float = 10.0

const FLOATING_TEXT_SCENE = preload("res://FloatingText.tscn")

var active_game: bool = false

func _ready() -> void:
	active_game = false

func reset_game() -> void:
	white_points = 10.0
	black_points = 10.0
	active_game = true

func process_capture(tipe_piece: String, same_color: bool, rider_color: String):
	var current_points: float = white_points if rider_color == "white" else black_points
	
	var text_to_display: String = ""
	var visual_color = Color("#ffffff")
	
	match tipe_piece:
		"pawn":
			if not same_color: 
				current_points += 1
				text_to_display = "+1"
				visual_color = Color("#00ff00")
			else:
				current_points -= 1
				text_to_display = "-1"
				visual_color = Color("#ff4d4d")
		"knight":
			if not same_color:
				current_points *= 2
				text_to_display = "x2"
				visual_color = Color("#00ffff")
			else:
				current_points /= 2
				text_to_display = "÷2"
				visual_color = Color("#ff4d4d") 
		"bishop":
			if not same_color:
				current_points *= 3
				text_to_display = "x3"
				visual_color = Color("#e2925b")
			else:
				current_points /= 3
				text_to_display = "÷3"
				visual_color = Color("#ff4d4d")
		"rook":
			if not same_color:
				current_points = pow(current_points, 2)
				text_to_display = "X²"
				visual_color = Color("#ffd700")
			else:
				current_points = sqrt(current_points)
				text_to_display = "√"
				visual_color = Color("#ff00ff")
		"queen":
			if not same_color:
				current_points = pow(current_points, 3)
				text_to_display = "X³"
				visual_color = Color("#ffd700")
			else:
				current_points = pow(current_points, 1.0 / 3.0)
				text_to_display = "³√"
				visual_color = Color("#ff00ff")
		"king":
			if not same_color:
				current_points += 100
				text_to_display = "FINISH!"
				visual_color = Color("#ffd700")
	
	if current_points < 0:
		current_points = 0.0
	
	if rider_color == "white":
		white_points = current_points
	else:
		black_points = current_points
	
	var score_interface = get_tree().current_scene.find_child("ScoreInterface", true, false)
	if score_interface and score_interface.has_method("update_score_labels"):
		score_interface.update_score_labels()
	
	if text_to_display != "":
		var players = get_tree().get_nodes_in_group("players")
		var spawn_position = Vector2.ZERO
		for player in players:
			if "is_white" in player and player.is_white == (rider_color == "white"):
				spawn_position = player.global_position
				break
		
		var text_nodo = Label.new()
		text_nodo.text = text_to_display
		text_nodo.modulate = visual_color
		
		var settings = LabelSettings.new()
		settings.font = load("res://PressStart2P.ttf")
		settings.font_size = 30
		settings.font_color = visual_color
		settings.outline_size = 6
		settings.outline_color = Color(0, 0, 0)
		text_nodo.label_settings = settings
		
		text_nodo.top_level = true
		text_nodo.z_index = 100
		text_nodo.global_position = spawn_position + Vector2(-50, -40) 
		
		get_tree().current_scene.add_child(text_nodo)
		
		var tween = get_tree().create_tween().set_parallel(true)
		tween.tween_property(text_nodo, "global_position:y", text_nodo.global_position.y - 60, 0.8)
		tween.tween_property(text_nodo, "modulate:a", 0.0, 0.8)
		tween.chain().tween_callback(text_nodo.queue_free)
		
		
func format_points(points: float) -> String:
	if is_nan(points) or points < 0.0:
		return "0"
	if is_inf(points):
		return "MAX"

	if points < 1000.0:
		return str(int(points))

	var suffixes = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]
	var index_suffix = 0
	var reduced_value = points

	while reduced_value >= 1000.0 and index_suffix < suffixes.size() - 1:
		reduced_value /= 1000.0
		index_suffix += 1

	return "%.1f" % reduced_value + suffixes[index_suffix]
