extends Control

@export var detection_range: float = 700.0
@export var minimap_radius: float = 55.0

var player: Node2D
var refresh_timer: float = 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(132.0, 132.0)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	refresh_timer += delta
	if refresh_timer >= 0.1:
		refresh_timer = 0.0
		queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, minimap_radius + 7.0, Color(0.015, 0.025, 0.02, 0.82))
	draw_arc(center, minimap_radius + 7.0, 0.0, TAU, 48, Color(0.82, 0.78, 0.52, 0.9), 1.5)
	draw_circle(center, minimap_radius, Color(0.08, 0.17, 0.1, 0.76))
	draw_arc(center, minimap_radius * 0.5, 0.0, TAU, 32, Color(0.65, 0.75, 0.63, 0.22), 1.0)
	draw_line(center + Vector2(-minimap_radius, 0.0), center + Vector2(minimap_radius, 0.0), Color(0.65, 0.75, 0.63, 0.18), 1.0)
	draw_line(center + Vector2(0.0, -minimap_radius), center + Vector2(0.0, minimap_radius), Color(0.65, 0.75, 0.63, 0.18), 1.0)

	var enemy_count := 0
	if is_instance_valid(player):
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(enemy) or not enemy is Node2D:
				continue
			var offset: Vector2 = player.global_position.direction_to(enemy.global_position)
			var distance := player.global_position.distance_to(enemy.global_position)
			if distance > detection_range:
				continue
			var dot_position := center + offset * (distance / detection_range) * minimap_radius
			draw_circle(dot_position, 3.0, Color(1.0, 0.2, 0.16, 1.0))
			enemy_count += 1

	draw_circle(center, 5.0, Color(0.2, 0.95, 0.48, 1.0))
	draw_arc(center, 5.0, 0.0, TAU, 24, Color(0.04, 0.12, 0.07, 1.0), 1.5)
	draw_string(ThemeDB.fallback_font, Vector2(8.0, 14.0), "BẢN ĐỒ  •  %d" % enemy_count, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color(1.0, 0.94, 0.73, 1.0))
