extends CanvasLayer

const FONT_PATH := "res://assets/fonts/upheavtt.ttf"

@onready var overlay: ColorRect = get_node_or_null("Overlay")
@onready var panel: Control = get_node_or_null("Panel")

var vbox: VBoxContainer
var title_label: Label
var resume_button: Button
var restart_button: Button
var audio_button: Button
var menu_button: Button

var _shared_font: Font = null
var _tween: Tween
var _is_closing: bool = false
var _audio_text: String = "AUDIO: ON"
var _saved_modulates: Dictionary = {}

const COLOR_WHITE := Color("#f8fafc")
const COLOR_GOLD_BORDER := Color("#ffd166")
const COLOR_GOLD_LIGHT := Color("#ffe082")
const COLOR_GOLD_SHADOW := Color("#9e6b1d")
const COLOR_PANEL_BG := Color("#262b3d")
const COLOR_PANEL_SHADOW := Color(0.02, 0.02, 0.05, 0.65)

const COLOR_RESUME_BG := Color("#e09f3e")
const COLOR_RESUME_HOVER := Color("#f0b454")
const COLOR_RESUME_PRESSED := Color("#c68628")
const COLOR_DARK_TEXT := Color("#161822")

const COLOR_SEC_BG := Color("#363d54")
const COLOR_SEC_HOVER := Color("#454e6b")
const COLOR_SEC_PRESSED := Color("#282d3f")
const COLOR_SEC_BORDER := Color("#556082")
const COLOR_SEC_SHADOW := Color("#1a1e2b")
const COLOR_AUDIO_FLASH := Color("#7ce8ff")

const BLUR_SHADER := """
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;

void fragment() {
	float strength = 2.2;
	vec2 step_size = SCREEN_PIXEL_SIZE * strength;

	vec3 total = vec3(0.0);
	total += texture(screen_texture, SCREEN_UV + vec2(-step_size.x, -step_size.y)).rgb;
	total += texture(screen_texture, SCREEN_UV + vec2(0.0, -step_size.y)).rgb;
	total += texture(screen_texture, SCREEN_UV + vec2(step_size.x, -step_size.y)).rgb;
	total += texture(screen_texture, SCREEN_UV + vec2(-step_size.x, 0.0)).rgb;
	total += texture(screen_texture, SCREEN_UV).rgb;
	total += texture(screen_texture, SCREEN_UV + vec2(step_size.x, 0.0)).rgb;
	total += texture(screen_texture, SCREEN_UV + vec2(-step_size.x, step_size.y)).rgb;
	total += texture(screen_texture, SCREEN_UV + vec2(0.0, step_size.y)).rgb;
	total += texture(screen_texture, SCREEN_UV + vec2(step_size.x, step_size.y)).rgb;

	vec3 blurred = total / 9.0;

	vec3 dark_color = vec3(0.05, 0.06, 0.10);
	float darkness = 0.58;
	vec3 result = mix(blurred, dark_color, darkness);

	COLOR = vec4(result, 1.0);
}
"""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 200
	hide()

	_ensure_ui_nodes()
	_setup_layout_and_styles()
	_apply_always_process_recursive(self)
	_connect_signals()
	_refresh_audio_label()
	_center_panel()

	var vp := get_viewport()
	if vp and not vp.size_changed.is_connected(_center_panel):
		vp.size_changed.connect(_center_panel)

func _mark_input_handled() -> void:
	var vp := get_viewport()
	if vp:
		vp.set_input_as_handled()

func _apply_always_process_recursive(node: Node) -> void:
	node.process_mode = Node.PROCESS_MODE_ALWAYS
	for child in node.get_children():
		_apply_always_process_recursive(child)

func _collect_canvas_modulates(node: Node, list: Array[CanvasModulate]) -> void:
	if node is CanvasModulate:
		list.append(node as CanvasModulate)
	for child in node.get_children():
		_collect_canvas_modulates(child, list)

func _set_scene_modulate_normal(enable: bool) -> void:
	var root := get_tree().root
	if root == null:
		return
	if enable:
		_saved_modulates.clear()
		var mods: Array[CanvasModulate] = []
		_collect_canvas_modulates(root, mods)
		for cm in mods:
			if cm and is_instance_valid(cm) and cm.color != Color.WHITE:
				_saved_modulates[cm.get_instance_id()] = {
					"node": cm,
					"color": cm.color
				}
				cm.color = Color.WHITE
	else:
		for id in _saved_modulates.keys():
			var entry: Dictionary = _saved_modulates[id]
			var cm: CanvasModulate = entry.get("node")
			var orig_color: Color = entry.get("color", Color.WHITE)
			if cm and is_instance_valid(cm):
				cm.color = orig_color
		_saved_modulates.clear()

func _ensure_ui_nodes() -> void:
	if overlay == null:
		overlay = ColorRect.new()
		overlay.name = "Overlay"
		add_child(overlay)

	if panel == null:
		panel = Panel.new()
		panel.name = "Panel"
		add_child(panel)

	if overlay.get_parent() == self and panel.get_parent() == self:
		move_child(overlay, 0)
		move_child(panel, 1)

	vbox = panel.find_child("VBoxContainer", true, false) as VBoxContainer
	if vbox == null:
		vbox = VBoxContainer.new()
		vbox.name = "VBoxContainer"
		panel.add_child(vbox)
	elif vbox.get_parent() != panel:
		vbox.reparent(panel)

	for lbl in find_children("*", "Label", true, false):
		var label_node := lbl as Label
		if label_node and label_node.text.strip_edges().to_upper() == "PAUSED":
			if title_label == null:
				title_label = label_node
			elif label_node != title_label:
				label_node.visible = false

	if title_label == null:
		title_label = Label.new()
		title_label.name = "Title"
		title_label.text = "PAUSED"

	if title_label.get_parent() != vbox:
		if title_label.get_parent():
			title_label.reparent(vbox)
		else:
			vbox.add_child(title_label)

	resume_button = _get_or_create_button("ResumeButton", "RESUME")
	restart_button = _get_or_create_button("RestartButton", "RESTART")
	audio_button = _get_or_create_button("AudioButton", "AUDIO: ON")
	menu_button = _get_or_create_button("MenuButton", "MAIN MENU")

	var ordered_children: Array[Control] = [title_label, resume_button, restart_button, audio_button, menu_button]
	for i in range(ordered_children.size()):
		var item := ordered_children[i]
		if item and item.get_parent() == vbox:
			vbox.move_child(item, i)

func _get_or_create_button(node_name: String, default_text: String) -> Button:
	var found := find_child(node_name, true, false) as Button
	if found == null:
		found = Button.new()
		found.name = node_name
		found.text = default_text
	elif found.text.strip_edges() == "":
		found.text = default_text

	if found.get_parent() != vbox:
		if found.get_parent():
			found.reparent(vbox)
		else:
			vbox.add_child(found)

	found.disabled = false
	found.mouse_filter = Control.MOUSE_FILTER_STOP
	found.focus_mode = Control.FOCUS_ALL
	return found

func _normal_button_style(bg: Color, border: Color, bottom_shadow: Color, bottom_thickness: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.border_width_bottom = bottom_thickness
	sb.set_corner_radius_all(4)
	sb.shadow_color = bottom_shadow
	sb.shadow_offset = Vector2(0, bottom_thickness)
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 13
	sb.content_margin_bottom = 13
	return sb

func _pressed_button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.border_width_bottom = 0
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 16
	sb.content_margin_bottom = 10
	return sb

func _setup_button(btn: Button, is_primary: bool, shared_font: Font) -> void:
	if btn == null:
		return

	btn.theme = null
	btn.visible = true
	btn.disabled = false
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.focus_mode = Control.FOCUS_ALL
	btn.modulate = Color.WHITE
	btn.self_modulate = Color.WHITE
	btn.custom_minimum_size = Vector2(360, 52)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.position = Vector2.ZERO
	btn.offset_left = 0.0
	btn.offset_top = 0.0
	btn.offset_right = 0.0
	btn.offset_bottom = 0.0

	if shared_font:
		btn.add_theme_font_override("font", shared_font)
	btn.add_theme_font_size_override("font_size", 21)
	btn.add_theme_constant_override("outline_size", 0)
	btn.add_theme_constant_override("shadow_offset_x", 0)
	btn.add_theme_constant_override("shadow_offset_y", 0)

	if is_primary:
		btn.add_theme_stylebox_override("normal", _normal_button_style(COLOR_RESUME_BG, COLOR_GOLD_BORDER, COLOR_GOLD_SHADOW, 4))
		btn.add_theme_stylebox_override("hover", _normal_button_style(COLOR_RESUME_HOVER, COLOR_GOLD_LIGHT, COLOR_GOLD_SHADOW, 4))
		btn.add_theme_stylebox_override("focus", _normal_button_style(COLOR_RESUME_HOVER, COLOR_GOLD_LIGHT, COLOR_GOLD_SHADOW, 4))
		btn.add_theme_stylebox_override("pressed", _pressed_button_style(COLOR_RESUME_PRESSED, COLOR_GOLD_SHADOW))
		btn.add_theme_color_override("font_color", COLOR_DARK_TEXT)
		btn.add_theme_color_override("font_hover_color", COLOR_DARK_TEXT)
		btn.add_theme_color_override("font_focus_color", COLOR_DARK_TEXT)
		btn.add_theme_color_override("font_pressed_color", COLOR_DARK_TEXT)
	else:
		btn.add_theme_stylebox_override("normal", _normal_button_style(COLOR_SEC_BG, COLOR_SEC_BORDER, COLOR_SEC_SHADOW, 3))
		btn.add_theme_stylebox_override("hover", _normal_button_style(COLOR_SEC_HOVER, COLOR_GOLD_LIGHT, COLOR_SEC_SHADOW, 3))
		btn.add_theme_stylebox_override("focus", _normal_button_style(COLOR_SEC_HOVER, COLOR_GOLD_LIGHT, COLOR_SEC_SHADOW, 3))
		btn.add_theme_stylebox_override("pressed", _pressed_button_style(COLOR_SEC_PRESSED, COLOR_GOLD_BORDER))
		btn.add_theme_color_override("font_color", COLOR_WHITE)
		btn.add_theme_color_override("font_hover_color", COLOR_GOLD_LIGHT)
		btn.add_theme_color_override("font_focus_color", COLOR_GOLD_LIGHT)
		btn.add_theme_color_override("font_pressed_color", COLOR_WHITE)

func _style_pause_trigger(btn: Button, shared_font: Font) -> void:
	if btn == null:
		return

	btn.text = "||"
	btn.theme = null
	btn.custom_minimum_size = Vector2(56, 48)
	if shared_font:
		btn.add_theme_font_override("font", shared_font)
	btn.add_theme_font_size_override("font_size", 38)

	var normal := StyleBoxFlat.new()
	normal.bg_color = COLOR_SEC_BG
	normal.border_color = COLOR_GOLD_BORDER
	normal.set_border_width_all(2)
	normal.border_width_bottom = 3
	normal.set_corner_radius_all(2)
	normal.shadow_color = COLOR_SEC_SHADOW
	normal.shadow_offset = Vector2(0, 3)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = COLOR_SEC_HOVER
	hover.border_color = COLOR_GOLD_LIGHT

	var pressed := StyleBoxFlat.new()
	pressed.bg_color = COLOR_SEC_PRESSED
	pressed.border_color = COLOR_GOLD_BORDER
	pressed.set_border_width_all(2)
	pressed.border_width_bottom = 0
	pressed.set_corner_radius_all(2)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("focus", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_color_override("font_color", COLOR_GOLD_BORDER)
	btn.add_theme_color_override("font_hover_color", COLOR_GOLD_LIGHT)
	btn.add_theme_color_override("font_focus_color", COLOR_GOLD_LIGHT)
	btn.add_theme_color_override("font_pressed_color", COLOR_WHITE)

func _setup_layout_and_styles() -> void:
	if overlay:
		overlay.anchor_left = 0.0
		overlay.anchor_top = 0.0
		overlay.anchor_right = 1.0
		overlay.anchor_bottom = 1.0
		overlay.offset_left = 0.0
		overlay.offset_top = 0.0
		overlay.offset_right = 0.0
		overlay.offset_bottom = 0.0
		overlay.color = Color.WHITE
		overlay.mouse_filter = Control.MOUSE_FILTER_STOP
		overlay.modulate = Color.WHITE

		var sh := Shader.new()
		sh.code = BLUR_SHADER
		var mat := ShaderMaterial.new()
		mat.shader = sh
		overlay.material = mat

	var pad_x := 32
	var pad_y := 28

	if panel:
		panel.theme = null
		panel.anchor_left = 0.0
		panel.anchor_top = 0.0
		panel.anchor_right = 0.0
		panel.anchor_bottom = 0.0
		panel.mouse_filter = Control.MOUSE_FILTER_PASS
		panel.modulate = Color.WHITE
		panel.self_modulate = Color.WHITE
		panel.scale = Vector2.ONE

		var panel_style := StyleBoxFlat.new()
		panel_style.bg_color = COLOR_PANEL_BG
		panel_style.border_color = COLOR_GOLD_BORDER
		panel_style.set_border_width_all(2)
		panel_style.border_width_top = 3
		panel_style.border_width_bottom = 4
		panel_style.set_corner_radius_all(6)
		panel_style.shadow_color = COLOR_PANEL_SHADOW
		panel_style.shadow_size = 10
		panel_style.shadow_offset = Vector2(0, 6)
		panel_style.content_margin_left = pad_x
		panel_style.content_margin_right = pad_x
		panel_style.content_margin_top = pad_y
		panel_style.content_margin_bottom = pad_y
		panel.add_theme_stylebox_override("panel", panel_style)

	if vbox:
		vbox.anchor_left = 0.0
		vbox.anchor_top = 0.0
		vbox.anchor_right = 0.0
		vbox.anchor_bottom = 0.0
		vbox.mouse_filter = Control.MOUSE_FILTER_PASS
		vbox.position = Vector2(pad_x, pad_y)
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 16)

	_shared_font = null
	if ResourceLoader.exists(FONT_PATH):
		_shared_font = load(FONT_PATH) as Font
	elif resume_button:
		_shared_font = resume_button.get_theme_font("font")

	if title_label:
		title_label.theme = null
		title_label.label_settings = null
		title_label.visible = true
		title_label.custom_minimum_size = Vector2(360, 44)
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		title_label.modulate = Color.WHITE
		title_label.self_modulate = Color.WHITE
		title_label.position = Vector2.ZERO
		title_label.offset_left = 0.0
		title_label.offset_top = 0.0
		title_label.offset_right = 0.0
		title_label.offset_bottom = 0.0
		if _shared_font:
			title_label.add_theme_font_override("font", _shared_font)
		title_label.add_theme_font_size_override("font_size", 32)
		title_label.add_theme_color_override("font_color", COLOR_GOLD_BORDER)
		title_label.add_theme_constant_override("outline_size", 0)
		title_label.add_theme_constant_override("shadow_offset_x", 0)
		title_label.add_theme_constant_override("shadow_offset_y", 3)
		title_label.add_theme_color_override("font_shadow_color", COLOR_PANEL_SHADOW)

	_setup_button(resume_button, true, _shared_font)
	for btn in [restart_button, audio_button, menu_button]:
		_setup_button(btn, false, _shared_font)

	for btn in [resume_button, restart_button, audio_button, menu_button]:
		if btn:
			_set_indicators(btn, false)

	_center_panel()

func _set_indicators(btn: Button, active: bool) -> void:
	if btn == null:
		return
	var current_text := btn.text.strip_edges()
	if current_text.begins_with(">"):
		current_text = current_text.substr(1).strip_edges()
	if current_text.ends_with("<"):
		current_text = current_text.substr(0, current_text.length() - 1).strip_edges()

	if active:
		btn.text = "> %s <" % current_text
	else:
		btn.text = current_text

func _animate_button_state(btn: Button, active: bool) -> void:
	if btn == null or not is_instance_valid(btn):
		return
	_set_indicators(btn, active)
	btn.pivot_offset = btn.size * 0.5
	var target_scale := Vector2(1.04, 1.04) if active else Vector2.ONE
	var tw := btn.create_tween()
	tw.tween_property(btn, "scale", target_scale, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _center_panel() -> void:
	var vp := get_viewport()
	if not panel or not vp:
		return
	var pad_x := 32.0
	var pad_y := 28.0
	var content_size := Vector2(360, 320)
	if vbox:
		vbox.reset_size()
		content_size = vbox.get_combined_minimum_size()
		vbox.size = content_size
		vbox.position = Vector2(pad_x, pad_y)

	var total_size := Vector2(
		maxf(424.0, content_size.x + pad_x * 2.0),
		content_size.y + pad_y * 2.0
	)
	panel.size = total_size
	var vp_size := vp.get_visible_rect().size
	panel.position = (vp_size - total_size) * 0.5
	panel.pivot_offset = panel.size * 0.5

	for btn in [resume_button, restart_button, audio_button, menu_button]:
		if btn:
			btn.pivot_offset = btn.size * 0.5

func _connect_signals() -> void:
	var pause_btn := get_tree().root.find_child("PauseMenu2", true, false) as Button
	if pause_btn:
		_style_pause_trigger(pause_btn, _shared_font)
		if not pause_btn.pressed.is_connected(_on_pause_button_pressed):
			pause_btn.pressed.connect(_on_pause_button_pressed)

	if resume_button and not resume_button.pressed.is_connected(_on_resume_button_pressed):
		resume_button.pressed.connect(_on_resume_button_pressed)

	if restart_button and not restart_button.pressed.is_connected(_on_restart_button_pressed):
		restart_button.pressed.connect(_on_restart_button_pressed)

	if audio_button and not audio_button.pressed.is_connected(_on_audio_button_pressed):
		audio_button.pressed.connect(_on_audio_button_pressed)

	if menu_button and not menu_button.pressed.is_connected(_on_menu_button_pressed):
		menu_button.pressed.connect(_on_menu_button_pressed)

	for btn in [resume_button, restart_button, audio_button, menu_button]:
		if btn:
			btn.mouse_entered.connect(func(): _animate_button_state(btn, true))
			btn.mouse_exited.connect(func(): _animate_button_state(btn, btn.has_focus()))
			btn.focus_entered.connect(func(): _animate_button_state(btn, true))
			btn.focus_exited.connect(func(): _animate_button_state(btn, false))

func _trigger_button_action(btn: Button) -> void:
	if btn == resume_button:
		_on_resume_button_pressed()
	elif btn == restart_button:
		_on_restart_button_pressed()
	elif btn == audio_button:
		_on_audio_button_pressed()
	elif btn == menu_button:
		_on_menu_button_pressed()

func _input(event: InputEvent) -> void:
	if not visible or _is_closing:
		if event.is_action_pressed("ui_cancel") and not get_tree().paused:
			_on_pause_button_pressed()
			_mark_input_handled()
		return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var vp := get_viewport()
		var mouse_pos := vp.get_mouse_position() if vp else Vector2.ZERO
		for btn in [resume_button, restart_button, audio_button, menu_button]:
			if btn and btn.visible and not btn.disabled and btn.get_global_rect().has_point(mouse_pos):
				btn.grab_focus()
				_trigger_button_action(btn)
				_mark_input_handled()
				return
		_mark_input_handled()
		return
	
	if event.is_action_pressed("ui_cancel"):
		_on_resume_button_pressed()
		_mark_input_handled()
		return
	
	var buttons: Array[Button] = []
	for b in [resume_button, restart_button, audio_button, menu_button]:
		if b and b.visible and not b.disabled:
			buttons.append(b)
	if buttons.is_empty():
		return
	
	var current_idx := -1
	for i in range(buttons.size()):
		if buttons[i].has_focus():
			current_idx = i
			break
	
	if event.is_action_pressed("ui_down"):
		var next_idx := 0 if current_idx == -1 else (current_idx + 1) % buttons.size()
		buttons[next_idx].grab_focus()
		_mark_input_handled()
	elif event.is_action_pressed("ui_up"):
		var prev_idx := buttons.size() - 1 if current_idx <= 0 else current_idx - 1
		buttons[prev_idx].grab_focus()
		_mark_input_handled()
	elif event.is_action_pressed("ui_accept"):
		var target := buttons[current_idx] if current_idx != -1 else buttons[0]
		_trigger_button_action(target)
		_mark_input_handled()

func _on_pause_button_pressed() -> void:
	if visible and not _is_closing:
		return
	_is_closing = false
	_set_scene_modulate_normal(true)
	_refresh_audio_label()
	_center_panel()
	show()
	get_tree().paused = true
	_animate_open()
	if resume_button:
		resume_button.grab_focus()
		_animate_button_state(resume_button, true)

func _on_resume_button_pressed() -> void:
	if not visible or _is_closing:
		return
	_is_closing = true
	_set_scene_modulate_normal(false)
	get_tree().paused = false
	_animate_close()

func _find_board_to_reset() -> Node:
	var root := get_tree().root
	if not root:
		return null
	var named_board := root.find_child("Board2D_1", true, false)
	if named_board and named_board.has_method("reset_for_new_round"):
		return named_board
	return _find_node_with_method(root, "reset_for_new_round")

func _find_node_with_method(node: Node, method_name: String) -> Node:
	if node != self and node.has_method(method_name):
		return node
	for child in node.get_children():
		var found := _find_node_with_method(child, method_name)
		if found:
			return found
	return null

func _on_restart_button_pressed() -> void:
	_is_closing = false
	_set_scene_modulate_normal(false)
	get_tree().paused = false
	hide()
	
	var gm := get_node_or_null("/root/Gamemanager")
	if gm:
		if "active_game" in gm:
			gm.active_game = true
		if "white_clock_active" in gm:
			gm.white_clock_active = true
		if "black_clock_active" in gm:
			gm.black_clock_active = true
	
	var board := _find_board_to_reset()
	if board and board.has_method("reset_for_new_round"):
		board.reset_for_new_round()
	
	if get_tree().current_scene:
		get_tree().reload_current_scene()

func _on_audio_button_pressed() -> void:
	var master_bus = AudioServer.get_bus_index("Master")
	var is_muted = AudioServer.is_bus_mute(master_bus)
	AudioServer.set_bus_mute(master_bus, not is_muted)
	_refresh_audio_label()
	
	if audio_button:
		audio_button.pivot_offset = audio_button.size * 0.5
		var tw := audio_button.create_tween().set_parallel(true)
		tw.tween_property(audio_button, "modulate", COLOR_AUDIO_FLASH, 0.08)
		tw.tween_property(audio_button, "scale", Vector2(1.08, 1.08), 0.08)
		tw.chain().set_parallel(true)
		tw.tween_property(audio_button, "modulate", Color.WHITE, 0.14)
		tw.tween_property(audio_button, "scale", Vector2(1.04, 1.04), 0.14)

func _on_menu_button_pressed() -> void:
	_is_closing = false
	_set_scene_modulate_normal(false)
	get_tree().paused = false
	hide()
	get_tree().change_scene_to_file("res://MainMenu.tscn")

func _refresh_audio_label() -> void:
	if audio_button == null:
		return
	var master_bus = AudioServer.get_bus_index("Master")
	var is_muted = AudioServer.is_bus_mute(master_bus)
	_audio_text = "AUDIO: OFF" if is_muted else "AUDIO: ON"
	var has_focus_now := audio_button.has_focus()
	audio_button.text = "> %s <" % _audio_text if has_focus_now else _audio_text

func _animate_open() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_center_panel()
	if panel:
		panel.scale = Vector2(0.85, 0.85)
		panel.modulate.a = 0.0
	if overlay:
		overlay.modulate.a = 0.0
	
	_tween = create_tween().set_parallel(true)
	if overlay:
		_tween.tween_property(overlay, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if panel:
		_tween.tween_property(panel, "modulate:a", 1.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_tween.tween_property(panel, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _animate_close() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_center_panel()
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if overlay:
		_tween.tween_property(overlay, "modulate:a", 0.0, 0.12)
	if panel:
		_tween.tween_property(panel, "modulate:a", 0.0, 0.12)
		_tween.tween_property(panel, "scale", Vector2(0.85, 0.85), 0.12)
	_tween.chain().tween_callback(func():
		_is_closing = false
		hide()
	)

func _on_pause_menu_2_pressed() -> void:
	_on_pause_button_pressed()
