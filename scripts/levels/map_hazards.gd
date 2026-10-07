extends Node2D
class_name MapHazards

const HAZARD_RADIUS := 58.0

var hazard_type: String = "none"
var player: Node2D
var spawn_timer: float = 3.0
var warning_timer: float = 0.0
var active_timer: float = 0.0
var has_applied_effect: bool = false

func _process(delta: float) -> void:
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
		draw_circle(Vector2.ZERO, HAZARD_RADIUS, Color(0.9, 0.75, 0.2, 0.12))
		draw_arc(Vector2.ZERO, HAZARD_RADIUS, 0.0, TAU, 48, Color(1.0, 0.82, 0.25, 0.9), 3.0)
	elif active_timer > 0.0:
		var color := Color(0.35, 0.8, 1.0, 0.32) if hazard_type == "slow" else Color(0.8, 0.35, 1.0, 0.38)
		draw_circle(Vector2.ZERO, HAZARD_RADIUS, color)
		draw_arc(Vector2.ZERO, HAZARD_RADIUS, 0.0, TAU, 48, color.lightened(0.35), 3.0)
