extends Node2D

var destination = null
var active: bool = false
var is_despawning: bool = false
var galaxy_color: Color = Color.WHITE
var galaxy_rotation: float = 0.0
var stars: Array = []
var grid_position: Vector2i = Vector2i(-1, -1)
var cooldown_id: int = 0
const TILE_SIZE = 64

func _ready():
	add_to_group("portals")
	z_index = 20
	scale = Vector2.ZERO
	for i in range(12):
		stars.append(Vector2(randf_range(-22, 22), randf_range(-22, 22)))
	var tween = create_tween()
	if tween:
		tween.tween_property(self, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BOUNCE)
		tween.tween_callback(func(): if not is_despawning: active = true)
	else:
		active = true

func set_grid_position(grid: Vector2i):
	grid_position = grid
	position = Vector2(grid.x * TILE_SIZE + TILE_SIZE / 2.0, grid.y * TILE_SIZE + TILE_SIZE / 2.0)

func get_grid_position() -> Vector2i: return grid_position

func set_lifetime(duration: float):
	if not is_inside_tree(): await ready
	if not is_inside_tree() or is_despawning: return
	await get_tree().create_timer(duration).timeout
	if not is_instance_valid(self) or is_despawning: return
	despawn()

func despawn():
	if is_despawning: return
	is_despawning = true
	active = false
	if is_in_group("portals"): remove_from_group("portals")
	
	var other_portal = destination
	destination = null
	if is_instance_valid(other_portal):
		if other_portal.get("destination") == self: other_portal.destination = null
		if not other_portal.get("is_despawning"): other_portal.despawn()
		
	var tween = create_tween()
	if tween:
		tween.tween_property(self, "scale", Vector2.ZERO, 0.5)
		tween.tween_callback(queue_free)
	else: queue_free()

func _process(delta):
	galaxy_rotation += 2.0 * delta
	queue_redraw()
	if not active or is_despawning: return
	if not is_instance_valid(destination) or destination.is_queued_for_deletion(): return
	
	for player in get_tree().get_nodes_in_group("players"):
		if not is_instance_valid(player) or player.is_queued_for_deletion(): continue
		if position.distance_to(player.position) < 20.0:
			_teleport_rider(player)
			return

func _teleport_rider(player):
	if not active or is_despawning: return
	if not is_instance_valid(destination) or destination.get("is_despawning") or destination.is_queued_for_deletion(): return
	if not is_instance_valid(player) or player.is_queued_for_deletion(): return
	active = false
	if destination.has_method("start_cooldown"): destination.start_cooldown()
	if player.has_method("teleport_to"): player.teleport_to(destination.position)
	start_cooldown()

func start_cooldown():
	cooldown_id += 1
	var my_cooldown_id = cooldown_id
	active = false
	modulate.a = 0.2
	if not is_inside_tree(): return
	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree() or is_despawning or is_queued_for_deletion(): return
	if my_cooldown_id != cooldown_id: return
	active = true
	modulate.a = 1.0

func _draw():
	var core_color = Color(1.0, 1.0, 1.0, 0.9)
	draw_circle(Vector2.ZERO, 6.0, core_color)
	draw_circle(Vector2.ZERO, 12.0, galaxy_color * Color(1, 1, 1, 0.6))
	for arm in range(4):
		var arm_angle = (arm * PI * 2.0 / 4) + galaxy_rotation
		var prev_point = Vector2.ZERO
		for i in range(1, 15):
			var t = float(i) / 15.0
			var current_angle = arm_angle + (t * PI * 1.5)
			var current_point = Vector2(cos(current_angle), sin(current_angle)) * (t * 26.0)
			draw_line(prev_point, current_point, galaxy_color * Color(1, 1, 1, 1.0 - t), 6.0 * (1.0 - t), true)
			prev_point = current_point
	for star in stars:
		draw_circle(star.rotated(galaxy_rotation * 0.5), 1.5, Color(1, 1, 1, 0.8))
