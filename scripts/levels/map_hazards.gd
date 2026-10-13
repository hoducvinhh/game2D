extends Node2D
class_name MapHazards

const HAZARD_RADIUS := 58.0

var hazard_type: String = "none"
var player: Node2D
var spawn_timer: float = 3.0
var warning_timer: float = 0.0
var active_timer: float = 0.0
var has_applied_effect: bool = false
var visual_time: float = 0.0

func _process(delta: float) -> void:
	visual_time += delta
	if hazard_type == "none" or not is_instance_valid(player):
		return

	if warning_timer > 0.0:
		warning_timer -= delta
		if warning_timer <= 0.0:
			active_timer = 0.8
			_apply_effect()
		queue_redraw()
		return

	if active_timer > 0.0:
		active_timer -= delta
		if active_timer <= 0.0:
			spawn_timer = 3.5 if hazard_type == "slow" else 4.5
			has_applied_effect = false
			global_position = Vector2.ZERO
		queue_redraw()
		return

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_start_warning()

func _start_warning() -> void:
	if not is_instance_valid(player):
		return
	var offset := Vector2.from_angle(randf() * TAU) * randf_range(90.0, 210.0)
	global_position = player.global_position + offset
	warning_timer = 0.9
	queue_redraw()

func _apply_effect() -> void:
	if has_applied_effect or not is_instance_valid(player):
		return
	has_applied_effect = true
	if player.global_position.distance_to(global_position) > HAZARD_RADIUS:
		return
	if hazard_type == "slow" and player.has_method("apply_map_slow"):
		player.apply_map_slow(0.55, 1.2)
	elif hazard_type == "lightning" and player.has_method("take_damage"):
		player.take_damage(12)

func _draw() -> void:
	if warning_timer > 0.0:
		var pulse := 0.5 + 0.5 * sin(visual_time * 7.0)
		var warning_color := Color(1.0, 0.72, 0.2)
		var radius := HAZARD_RADIUS - pulse * 3.0
		draw_circle(Vector2.ZERO, radius, Color(warning_color, 0.1 + pulse * 0.06))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(warning_color, 0.7 + pulse * 0.3), 2.5, true)
		draw_arc(Vector2.ZERO, radius * 0.78, -visual_time * 1.4, -visual_time * 1.4 + TAU * 0.72, 48, Color(1.0, 0.9, 0.55, 0.75), 1.5, true)
		_draw_radial_ticks(radius, Color(1.0, 0.9, 0.55, 0.9), 12, visual_time * 0.25)
	elif active_timer > 0.0:
		var pulse := 0.5 + 0.5 * sin(visual_time * 12.0)
		var color := Color(0.18, 0.78, 1.0) if hazard_type == "slow" else Color(0.72, 0.32, 1.0)
		var radius := HAZARD_RADIUS - pulse * 2.0
		draw_circle(Vector2.ZERO, radius, Color(color, 0.2 + pulse * 0.1))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(color.lightened(0.35), 0.9), 3.0, true)
		draw_arc(Vector2.ZERO, radius * (0.7 + pulse * 0.04), visual_time * 2.0, visual_time * 2.0 + TAU * 0.66, 48, Color(color.lightened(0.55), 0.8), 2.0, true)
		_draw_radial_ticks(radius, Color(color.lightened(0.55), 0.9), 8, -visual_time * 0.2)

func _draw_radial_ticks(radius: float, color: Color, tick_count: int, rotation: float) -> void:
	for index in range(tick_count):
		var angle := rotation + TAU * float(index) / tick_count
		var direction := Vector2.from_angle(angle)
		draw_line(direction * (radius - 6.0), direction * (radius + 2.0), color, 2.0, true)
