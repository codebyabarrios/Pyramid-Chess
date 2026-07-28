extends Camera2D

@onready var mask_container: Control = $"../ScreenMask/MaskContainer"

func _ready() -> void:
	limit_left = -1000000
	limit_top = -1000000
	limit_right = 1000000
	limit_bottom = 1000000
	
	make_current()
	enabled = true
	anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	
	var board_1_pos = Vector2(230.0, 310.0)
	var board_2_pos = Vector2(740.0, 310.0)
	var board_3_pos = Vector2(1258.0, 310.0)
	
	var overview_pos_x: float = 740.0
	var overview_pos_y: float = 310.0
	
	var close_zoom = Vector2(1.48, 1.48)
	var far_zoom = Vector2(1.11, 1.11)
	
	global_position = board_1_pos
	zoom = close_zoom
	
	if mask_container:
		mask_container.modulate.a = 1.0
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_interval(1.0)
	
	tween.tween_property(self, "global_position", board_2_pos, 2.0)
	tween.tween_interval(0.4)
	
	tween.tween_property(self, "global_position", board_3_pos, 2.0)
	tween.tween_interval(0.4)
	
	tween.tween_property(self, "global_position:x", overview_pos_x, 1.5)
	tween.parallel().tween_property(self, "global_position:y", overview_pos_y, 1.5)
	tween.tween_interval(0.4)
	
	if mask_container:
		tween.tween_property(mask_container, "modulate:a", 0.0, 0.5)
		tween.parallel().tween_property(self, "zoom", far_zoom, 3.0)
	else:
		tween.tween_property(self, "zoom", far_zoom, 3.0)
	
	tween.tween_interval(3.0)
	
	if mask_container:
		tween.tween_property(mask_container, "modulate:a", 1.0, 0.4)
		tween.parallel().tween_property(self, "global_position", board_1_pos, 1.2)
		tween.parallel().tween_property(self, "zoom", close_zoom, 1.2)
	else:
		tween.tween_property(self, "global_position", board_1_pos, 1.2)
		tween.parallel().tween_property(self, "zoom", close_zoom, 1.2)
