extends Control

var scroll_offset: float = 0.0
var scroll_speed: float = 35.0 
const TILE_SIZE = 64
const START_POS_1 = 160.0
const START_POS_2 = 288.0

func _ready():
	size = Vector2(512, 512)
	clip_contents = true 
	z_as_relative = false
	z_index = 50 
	position = Vector2.ZERO
	scale = Vector2.ONE 
	show() 
	call_deferred("_poner_al_frente")

func _poner_al_frente():
	if get_parent(): get_parent().move_child(self, -1)

func _process(delta: float):
	scroll_offset += scroll_speed * delta
	queue_redraw()

func _draw():
	if not Global.get("show_guide_arrows"): 
		return

	var thickness = 3.0

	for y in range(8):
		var direction = -1 if (y % 2 != 0) else 1
		var row_color = Color(1.0, 0.6, 0.2, 0.45) if direction == 1 else Color(0.2, 0.8, 1.0, 0.45)
		
		var y_center = (y * TILE_SIZE) + (TILE_SIZE / 2.0)

		var x_arrow_1 = START_POS_1 + (scroll_offset * direction)
		var x_arrow_2 = START_POS_2 + (scroll_offset * direction)

		x_arrow_1 = wrapf(x_arrow_1, -32.0, 544.0)
		x_arrow_2 = wrapf(x_arrow_2, -32.0, 544.0)

		_dibujar_flecha(Vector2(x_arrow_1, y_center), direction, row_color, thickness)
		_dibujar_flecha(Vector2(x_arrow_2, y_center), direction, row_color, thickness)


func _dibujar_flecha(center: Vector2, direction: int, color: Color, thickness: float):
	var points = PackedVector2Array()
	if direction == 1:
		points.push_back(center + Vector2(-8, -12))
		points.push_back(center + Vector2(8, 0))
		points.push_back(center + Vector2(-8, 12))
	else:
		points.push_back(center + Vector2(8, -12))
		points.push_back(center + Vector2(-8, 0))
		points.push_back(center + Vector2(8, 12))
	
	draw_polyline(points, color, thickness, true)
