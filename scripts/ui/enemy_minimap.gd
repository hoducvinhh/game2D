extends Control

@export var detection_range: float = 700.0

var player: Node2D
var refresh_timer: float = 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(124.0, 124.0)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	refresh_timer += delta
	if refresh_timer >= 0.1:
		refresh_timer = 0.0
		queue_redraw()

func _draw() -> void:
	var map_rect := Rect2(Vector2(3.0, 3.0), size - Vector2(6.0, 6.0))
	var inner_rect := map_rect.grow(-7.0)
	var center := inner_rect.get_center()
	draw_rect(map_rect, Color(0.015, 0.025, 0.02, 0.88), true)
	draw_rect(map_rect, Color(0.82, 0.78, 0.52, 0.9), false, 1.5)
	draw_rect(inner_rect, Color(0.08, 0.17, 0.1, 0.76), true)
	draw_rect(inner_rect, Color(0.65, 0.75, 0.63, 0.25), false, 1.0)
	draw_line(Vector2(center.x, inner_rect.position.y), Vector2(center.x, inner_rect.end.y), Color(0.65, 0.75, 0.63, 0.22), 1.0)
	draw_line(Vector2(inner_rect.position.x, center.y), Vector2(inner_rect.end.x, center.y), Color(0.65, 0.75, 0.63, 0.22), 1.0)

	var enemy_count := 0
	if is_instance_valid(player):
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(enemy) or not enemy is Node2D:
				continue
			var offset: Vector2 = player.global_position.direction_to(enemy.global_position)
			var distance := player.global_position.distance_to(enemy.global_position)
			if distance > detection_range:
				continue
			var normalized_offset := offset * (distance / detection_range)
			var half_extent := inner_rect.size * 0.5 - Vector2(4.0, 4.0)
			var dot_position := center + Vector2(normalized_offset.x * half_extent.x, normalized_offset.y * half_extent.y)
			draw_circle(dot_position, 3.0, Color(1.0, 0.2, 0.16, 1.0))
			enemy_count += 1

	draw_circle(center, 5.0, Color(0.2, 0.95, 0.48, 1.0))
	draw_string(ThemeDB.fallback_font, Vector2(7.0, 14.0), "BẢN ĐỒ · %d" % enemy_count, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 9, Color(1.0, 0.94, 0.73, 1.0))
