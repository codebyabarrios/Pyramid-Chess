extends Control

@onready var white_score_label: Label = $RightControl/WhitePoints
@onready var black_score_label: Label = $RightControl/BlackPoints
@onready var white_history: VBoxContainer = $RightControl/WhiteHistory
@onready var black_history: VBoxContainer = $RightControl/BlackHistory

var white_clock_label: Label = null
var black_clock_label: Label = null
var white_hearts_box: HBoxContainer = null
var black_hearts_box: HBoxContainer = null
var white_energy_bar: ProgressBar = null
var black_energy_bar: ProgressBar = null

var smooth_white_energy: float = 100.0
var smooth_black_energy: float = 100.0

var prev_w_frenzy: bool = false
var prev_b_frenzy: bool = false
var prev_w_stun: bool = false
var prev_b_stun: bool = false
var prev_w_energy: float = 100.0
var prev_b_energy: float = 100.0

func _ready():
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	self.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	white_score_label = find_child("WhitePoints", true, false)
	black_score_label = find_child("BlackPoints", true, false)
	white_history = find_child("WhiteHistory", true, false)
	black_history = find_child("BlackHistory", true, false)

	white_clock_label = _create_ui_clock()
	black_clock_label = _create_ui_clock()
	white_hearts_box = _create_ui_hearts()
	black_hearts_box = _create_ui_hearts()
	white_energy_bar = _create_energy_bar()
	black_energy_bar = _create_energy_bar()
	
	add_child(white_clock_label)
	add_child(black_clock_label)
	add_child(white_hearts_box)
	add_child(black_hearts_box)
	add_child(white_energy_bar)
	add_child(black_energy_bar)
	
	_update_energy_bar_colors() 
	
	await get_tree().process_frame
	_reposition_ui()
	update_score_labels()
	update_hearts()
	
	smooth_white_energy = Gamemanager.white_energy
	smooth_black_energy = Gamemanager.black_energy
	prev_w_energy = Gamemanager.white_energy
	prev_b_energy = Gamemanager.black_energy

func _process(delta: float) -> void:
	if is_instance_valid(white_clock_label):
		var w_time = max(0, Gamemanager.white_time_left)
		var w_min = int(w_time) / 60
		var w_sec = int(w_time) % 60
		white_clock_label.text = "TIME: %02d:%02d" % [w_min, w_sec]
		
		if w_time <= 0.0: white_clock_label.label_settings.font_color = Color("#ff0000")
		elif w_time < 30.0: white_clock_label.label_settings.font_color = Color("#ff4d4d")
		else: white_clock_label.label_settings.font_color = Color("#e0e0e0")
	
	if is_instance_valid(black_clock_label):
		var b_time = max(0, Gamemanager.black_time_left)
		var b_min = int(b_time) / 60
		var b_sec = int(b_time) % 60
		black_clock_label.text = "TIME: %02d:%02d" % [b_min, b_sec]
		
		if b_time <= 0.0: black_clock_label.label_settings.font_color = Color("#ff0000")
		elif b_time < 30.0: black_clock_label.label_settings.font_color = Color("#ff4d4d")
		else: black_clock_label.label_settings.font_color = Color("#ffd700")

	smooth_white_energy = lerpf(smooth_white_energy, Gamemanager.white_energy, delta * 6.0)
	smooth_black_energy = lerpf(smooth_black_energy, Gamemanager.black_energy, delta * 6.0)
	
	if is_instance_valid(white_energy_bar): 
		white_energy_bar.value = smooth_white_energy
		if Global.difficulty == "easy" and Gamemanager.white_is_frenzy:
			var fg = white_energy_bar.get_theme_stylebox("fill")
			if fg:
				var pulse = (sin(Time.get_ticks_msec() * 0.02) + 1.0) / 2.0
				fg.bg_color = Color("#ffd700").lerp(Color("#ffffff"), pulse)

	if is_instance_valid(black_energy_bar): 
		black_energy_bar.value = smooth_black_energy
		if Global.difficulty == "easy" and Gamemanager.black_is_frenzy:
			var fg = black_energy_bar.get_theme_stylebox("fill")
			if fg:
				var pulse = (sin(Time.get_ticks_msec() * 0.02) + 1.0) / 2.0
				fg.bg_color = Color("#ffd700").lerp(Color("#ffffff"), pulse)

	_check_status_popups("white", Gamemanager.white_is_frenzy, Gamemanager.white_is_stunned, Gamemanager.white_energy, prev_w_frenzy, prev_w_stun, prev_w_energy)
	_check_status_popups("black", Gamemanager.black_is_frenzy, Gamemanager.black_is_stunned, Gamemanager.black_energy, prev_b_frenzy, prev_b_stun, prev_b_energy)
	
	prev_w_frenzy = Gamemanager.white_is_frenzy
	prev_w_stun = Gamemanager.white_is_stunned
	prev_w_energy = Gamemanager.white_energy
	
	prev_b_frenzy = Gamemanager.black_is_frenzy
	prev_b_stun = Gamemanager.black_is_stunned
	prev_b_energy = Gamemanager.black_energy

func _check_status_popups(side: String, is_frenzy: bool, is_stunned: bool, current_energy: float, p_frenzy: bool, p_stunned: bool, p_energy: float):
	var diff = Global.difficulty
	
	if diff == "easy":
		if is_frenzy and not p_frenzy:
			_show_ui_popup("⚡ FRENZY ACTIVE! (2X PTS) ⚡", side, Color("#ffd700"))
			
	elif diff in ["medium", "hard"]:
		if is_stunned and not p_stunned:
			_show_ui_popup("STUNNED!", side, Color("#ff0000"))
		elif not is_stunned and p_stunned:
			_show_ui_popup("RECOVERED!", side, Color("#00ff00"))
			
		if current_energy >= 100.0 and p_energy < 100.0 and not is_stunned:
			_show_ui_popup("MAX STAMINA", side, Color("#ffffff"))

func _show_ui_popup(msg: String, side: String, color: Color):
	var lbl = Label.new()
	lbl.text = msg
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.custom_minimum_size = Vector2(300, 30)
	
	var settings = LabelSettings.new()
	settings.font = load("res://PressStart2P.ttf")
	settings.font_size = 12
	settings.font_color = color
	settings.outline_size = 4
	settings.outline_color = Color.BLACK
	lbl.label_settings = settings
	
	lbl.top_level = true
	lbl.z_index = 100
	add_child(lbl)
	
	var start_pos = Vector2.ZERO
	if side == "white" and is_instance_valid(white_energy_bar):
		start_pos = white_energy_bar.global_position + Vector2(white_energy_bar.size.x / 2.0 - 150, -25)
	elif side == "black" and is_instance_valid(black_energy_bar):
		start_pos = black_energy_bar.global_position + Vector2(black_energy_bar.size.x / 2.0 - 150, -25)
	else:
		lbl.queue_free()
		return
		
	lbl.global_position = start_pos
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(lbl, "global_position:y", start_pos.y - 45, 1.8).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(lbl, "modulate:a", 0.0, 1.8).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(lbl.queue_free)

func update_score_labels() -> void:
	if is_instance_valid(white_score_label) and is_instance_valid(black_score_label):
		white_score_label.text = Gamemanager.format_points(Gamemanager.white_points) + " PTS"
		black_score_label.text = Gamemanager.format_points(Gamemanager.black_points) + " PTS"

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
		for child in white_history.get_children(): child.queue_free()
	if is_instance_valid(black_history):
		for child in black_history.get_children(): child.queue_free()
	update_hearts() 

func _create_ui_hearts() -> HBoxContainer:
	var box = HBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in range(3):
		var heart = Label.new()
		heart.text = "♥" 
		var settings = LabelSettings.new()
		settings.font = load("res://PressStart2P.ttf")
		settings.font_size = 22
		settings.font_color = Color("#ff2222") 
		settings.outline_size = 4
		settings.outline_color = Color.BLACK
		heart.label_settings = settings
		box.add_child(heart)
	return box

func update_hearts():
	_update_heart_box(white_hearts_box, Gamemanager.white_health)
	_update_heart_box(black_hearts_box, Gamemanager.black_health)

func _update_heart_box(box: HBoxContainer, health: int):
	if not is_instance_valid(box): return
	for i in range(box.get_child_count()):
		var heart = box.get_child(i) as Label
		if i < health: heart.modulate = Color(1.0, 1.0, 1.0, 1.0) 
		else: heart.modulate = Color(0.2, 0.2, 0.2, 1.0) 

func _create_ui_clock() -> Label:
	var label = Label.new()
	label.text = "TIME: 03:00"
	label.process_mode = Node.PROCESS_MODE_ALWAYS
	var settings = LabelSettings.new()
	settings.font = load("res://PressStart2P.ttf")
	settings.font_size = 18 
	settings.font_color = Color.WHITE
	settings.outline_size = 4
	settings.outline_color = Color.BLACK
	label.label_settings = settings
	return label

func _create_energy_bar() -> ProgressBar:
	var bar = ProgressBar.new()
	bar.custom_minimum_size = Vector2(180, 20)
	bar.show_percentage = false
	bar.min_value = 0
	bar.max_value = 100
	bar.value = 100
	
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color("#222222") 
	bg_style.border_width_left = 3
	bg_style.border_width_top = 3
	bg_style.border_width_right = 3
	bg_style.border_width_bottom = 3
	bg_style.border_color = Color("#000000") 
	bar.add_theme_stylebox_override("background", bg_style)
	
	var fg_style = StyleBoxFlat.new()
	fg_style.bg_color = Color("#ffffff") 
	bar.add_theme_stylebox_override("fill", fg_style)
	return bar

func _update_energy_bar_colors():
	var diff = Global.difficulty
	var w_color = Color("#00ffff") 
	var b_color = Color("#ff9900") 
	
	if diff == "medium":
		w_color = Color("#00ff00") 
		b_color = Color("#aa00ff") 
	elif diff == "hard":
		w_color = Color("#ffff00") 
		b_color = Color("#ff0000") 
		
	if is_instance_valid(white_energy_bar):
		var fg = white_energy_bar.get_theme_stylebox("fill").duplicate()
		fg.bg_color = w_color
		white_energy_bar.add_theme_stylebox_override("fill", fg)
		
	if is_instance_valid(black_energy_bar):
		var fg = black_energy_bar.get_theme_stylebox("fill").duplicate()
		fg.bg_color = b_color
		black_energy_bar.add_theme_stylebox_override("fill", fg)

func _reposition_ui() -> void:
	var clock_y = size.y - 80.0 
	var hearts_offset_y = 100.0 
	var energy_offset_y = 145.0 

	if Global.total_players == 1:
		if Global.selected_side == "white":
			if is_instance_valid(white_score_label):
				var center_x = white_score_label.global_position.x + (white_score_label.size.x / 2.0)
				if is_instance_valid(white_clock_label):
					white_clock_label.position = Vector2(center_x - 70.0, clock_y)
					white_clock_label.visible = true
				if is_instance_valid(white_hearts_box):
					var half_w = white_hearts_box.get_minimum_size().x / 2.0
					white_hearts_box.position = Vector2(center_x - half_w, white_score_label.global_position.y - hearts_offset_y)
					white_hearts_box.visible = true
				if is_instance_valid(white_energy_bar):
					var half_bar = white_energy_bar.custom_minimum_size.x / 2.0
					white_energy_bar.position = Vector2(center_x - half_bar, white_score_label.global_position.y - energy_offset_y)
					white_energy_bar.visible = true
					
			if is_instance_valid(black_clock_label): black_clock_label.queue_free() 
			if is_instance_valid(black_hearts_box): black_hearts_box.queue_free() 
			if is_instance_valid(black_energy_bar): black_energy_bar.queue_free()
		else:
			if is_instance_valid(black_score_label):
				var center_x = black_score_label.global_position.x + (black_score_label.size.x / 2.0)
				if is_instance_valid(black_clock_label):
					black_clock_label.position = Vector2(center_x - 70.0, clock_y)
					black_clock_label.visible = true
				if is_instance_valid(black_hearts_box):
					var half_w = black_hearts_box.get_minimum_size().x / 2.0
					black_hearts_box.position = Vector2(center_x - half_w, black_score_label.global_position.y - hearts_offset_y)
					black_hearts_box.visible = true
				if is_instance_valid(black_energy_bar):
					var half_bar = black_energy_bar.custom_minimum_size.x / 2.0
					black_energy_bar.position = Vector2(center_x - half_bar, black_score_label.global_position.y - energy_offset_y)
					black_energy_bar.visible = true
					
			if is_instance_valid(white_clock_label): white_clock_label.queue_free() 
			if is_instance_valid(white_hearts_box): white_hearts_box.queue_free() 
			if is_instance_valid(white_energy_bar): white_energy_bar.queue_free() 
	else:
		if is_instance_valid(white_score_label):
			var center_x1 = white_score_label.global_position.x + (white_score_label.size.x / 2.0)
			if is_instance_valid(white_clock_label):
				white_clock_label.position = Vector2(center_x1 - 70.0, clock_y)
				white_clock_label.visible = true
			if is_instance_valid(white_hearts_box):
				var half_w1 = white_hearts_box.get_minimum_size().x / 2.0
				white_hearts_box.position = Vector2(center_x1 - half_w1, white_score_label.global_position.y - hearts_offset_y)
				white_hearts_box.visible = true
			if is_instance_valid(white_energy_bar):
				var half_bar1 = white_energy_bar.custom_minimum_size.x / 2.0
				white_energy_bar.position = Vector2(center_x1 - half_bar1, white_score_label.global_position.y - energy_offset_y)
				white_energy_bar.visible = true
			
		if is_instance_valid(black_score_label):
			var center_x2 = black_score_label.global_position.x + (black_score_label.size.x / 2.0)
			if is_instance_valid(black_clock_label):
				black_clock_label.position = Vector2(center_x2 - 70.0, clock_y)
				black_clock_label.visible = true
			if is_instance_valid(black_hearts_box):
				var half_w2 = black_hearts_box.get_minimum_size().x / 2.0
				black_hearts_box.position = Vector2(center_x2 - half_w2, black_score_label.global_position.y - hearts_offset_y)
				black_hearts_box.visible = true
			if is_instance_valid(black_energy_bar):
				var half_bar2 = black_energy_bar.custom_minimum_size.x / 2.0
				black_energy_bar.position = Vector2(center_x2 - half_bar2, black_score_label.global_position.y - energy_offset_y)
				black_energy_bar.visible = true
