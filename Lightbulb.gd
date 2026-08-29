extends Area2D
class_name Lightbulb

var is_on: bool = true
var type_piece = "lightbulb"
var grid_position: Vector2i
const TILE_SIZE = 64

var is_moving: bool = false
var move_timer: float = 0.0
var move_interval: float = 0.6
var steps_taken: int = 0
var move_direction: int = 1

func _ready():
	add_to_group("lightbulbs")
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 24.0
	shape.shape = circle
	add_child(shape)
	z_index = 20
	
	move_direction = 1 if randi() % 2 == 0 else -1
	
	var bulb_light = PointLight2D.new()
	bulb_light.energy = 1.5
	bulb_light.blend_mode = Light2D.BLEND_MODE_ADD
	
	var grad = Gradient.new()
	grad.colors = PackedColorArray([
		Color(1.0, 1.0, 0.3, 1.0),
		Color(1.0, 1.0, 0.3, 0.4),
		Color(1.0, 1.0, 0.3, 0.0)
	])
	grad.offsets = PackedFloat32Array([0.0, 0.7, 1.0])
	
	var tex = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 64
	tex.height = 64
	bulb_light.texture = tex
	add_child(bulb_light)

func _process(delta):
	queue_redraw()
	if is_moving and steps_taken < 8:
		move_timer += delta
		if move_timer >= move_interval:
			move_timer = 0.0
			_move_horizontal()

func _move_horizontal():
	steps_taken += 1
	var next_x = grid_position.x + move_direction
	
	if next_x > 7: next_x = 0
	elif next_x < 0: next_x = 7
	
	grid_position.x = next_x
	var tween = create_tween()
	tween.tween_property(self, "position", Vector2((grid_position.x * TILE_SIZE) + (TILE_SIZE / 2), (grid_position.y * TILE_SIZE) + (TILE_SIZE / 2)), 0.3)
	
	if steps_taken >= 8:
		tween.tween_callback(self.queue_free)

func _draw():
	if is_on:
		var pulse = (sin(Time.get_ticks_msec() * 0.01) + 1.0) / 2.0
		var glow = Color(1.0, 1.0, 0.0, 0.4 + (pulse * 0.4))
		draw_circle(Vector2.ZERO, 14.0, Color.YELLOW)
		draw_circle(Vector2.ZERO, 26.0, glow)
	else:
		var pulse = (sin(Time.get_ticks_msec() * 0.015) + 1.0) / 2.0
		var warning = Color(1.0, 0.0, 0.0, pulse * 0.6)
		draw_circle(Vector2.ZERO, 14.0, Color(0.2, 0.2, 0.2))
		draw_circle(Vector2.ZERO, 22.0, warning)
		
