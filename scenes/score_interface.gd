extends Control

@onready var white_score_label: Label = $RightControl/WhitePoints
@onready var black_score_label: Label = $RightControl/BlackPoints
@onready var white_history: VBoxContainer = $RightControl/WhiteHistory
@onready var black_history: VBoxContainer = $RightControl/BlackHistory

var white_clock_label: Label = null
var black_clock_label: Label = null

func _ready():
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	self.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	white_score_label = find_child("WhitePoints", true, false)
	black_score_label = find_child("BlackPoints", true, false)
	white_history = find_child("WhiteHistory", true, false)
	black_history = find_child("BlackHistory", true, false)

	white_clock_label = _create_ui_clock()
	black_clock_label = _create_ui_clock()
	add_child(white_clock_label)
	add_child(black_clock_label)
	
	await get_tree().process_frame
	_reposition_clocks()
	update_score_labels()

func _process(_delta: float) -> void:
	if is_instance_valid(white_clock_label):
		var w_time = max(0, Gamemanager.white_time_left)
		var w_min = int(w_time) / 60
		var w_sec = int(w_time) % 60
		white_clock_label.text = "W: %02d:%02d" % [w_min, w_sec]
		
		if w_time <= 0.0: white_clock_label.label_settings.font_color = Color("#ff0000")
		elif w_time < 30.0: white_clock_label.label_settings.font_color = Color("#ff4d4d")
		else: white_clock_label.label_settings.font_color = Color("#e0e0e0")
	
	if is_instance_valid(black_clock_label):
		var b_time = max(0, Gamemanager.black_time_left)
		var b_min = int(b_time) / 60
		var b_sec = int(b_time) % 60
		black_clock_label.text = "B: %02d:%02d" % [b_min, b_sec]
		
		if b_time <= 0.0: black_clock_label.label_settings.font_color = Color("#ff0000")
		elif b_time < 30.0: black_clock_label.label_settings.font_color = Color("#ff4d4d")
		else: black_clock_label.label_settings.font_color = Color("#ffd700")

func update_score_labels() -> void:
	if is_instance_valid(white_score_label) and is_instance_valid(black_score_label):
		white_score_label.text = Gamemanager.format_points(Gamemanager.white_points) + " pts"
		black_score_label.text = Gamemanager.format_points(Gamemanager.black_points) + " pts"

func add_operation_to_history(rider_color: String, operation_text: String, text_color: Color) -> void:
	var target = white_history if rider_color == "white" else black_history
	if not is_instance_valid(target): return
	var item = Label.new()
	item.text = operation_text
	item.horizontal_alignment = 0
	item.grow_horizontal = 0
	var settings = LabelSettings.new()
	settings.font = load("res://PressStart2P.ttf")
	settings.font_size = 20 
	settings.font_color = text_color
	settings.outline_size = 4
	settings.outline_color = Color.BLACK
	item.label_settings = settings
	target.add_child(item)
	target.move_child(item, 0)
	if target.get_child_count() > 4: 
		target.get_child(target.get_child_count() - 1).queue_free()

func clear_history() -> void:
	if is_instance_valid(white_history):
		for child in white_history.get_children():
			child.queue_free()
	if is_instance_valid(black_history):
		for child in black_history.get_children():
			child.queue_free()

func _create_ui_clock() -> Label:
	var label = Label.new()
	label.text = "03:00"
	label.process_mode = Node.PROCESS_MODE_ALWAYS
	var settings = LabelSettings.new()
	settings.font = load("res://PressStart2P.ttf")
	settings.font_size = 22
	settings.font_color = Color.WHITE
	settings.outline_size = 5
	settings.outline_color = Color.BLACK
	label.label_settings = settings
	return label

func _reposition_clocks() -> void:
	var margin_left = 35.0
	var base_y = size.y - 120.0
	if is_instance_valid(white_clock_label):
		white_clock_label.position = Vector2(margin_left, base_y)
		white_clock_label.visible = true
	if is_instance_valid(black_clock_label):
		black_clock_label.position = Vector2(margin_left, base_y + 40.0)
		black_clock_label.visible = true
