extends Area2D

const ZONE_SIZE := Vector2(130.0, 125.0)
var visual_time: float = 0.0

@onready var alert_sound: AudioStreamPlayer = $AudioStreamPlayer

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	visual_time += delta
	queue_redraw()

func _draw() -> void:
	var center := Vector2(918.0, 308.5)
	var half_size := ZONE_SIZE * 0.5
	var rect := Rect2(center - half_size, ZONE_SIZE)
	var pulse := 0.5 + 0.5 * sin(visual_time * 3.0)
	var border_color := Color(0.35, 0.88, 1.0, 0.72 + pulse * 0.2)

	draw_rect(rect.grow(7.0), Color(0.15, 0.72, 1.0, 0.035 + pulse * 0.025), true)
	draw_rect(rect.grow(3.0), Color(0.35, 0.88, 1.0, 0.32 + pulse * 0.12), false, 2.0, true)
	draw_rect(rect, border_color, false, 2.0, true)

	var corner_length := 17.0
	var inset := 7.0
	for x_sign in [-1.0, 1.0]:
		for y_sign in [-1.0, 1.0]:
			var corner := center + Vector2(half_size.x * x_sign, half_size.y * y_sign)
			var horizontal_end := corner - Vector2(x_sign * corner_length, 0.0) - Vector2(x_sign * inset, 0.0)
			var vertical_end := corner - Vector2(0.0, y_sign * corner_length) - Vector2(0.0, y_sign * inset)
			draw_line(corner - Vector2(x_sign * inset, 0.0), horizontal_end, Color(0.72, 0.96, 1.0, 0.95), 3.0, true)
			draw_line(corner - Vector2(0.0, y_sign * inset), vertical_end, Color(0.72, 0.96, 1.0, 0.95), 3.0, true)

	var icon_center := center + Vector2(0.0, -4.0)
	var icon := PackedVector2Array([
		icon_center + Vector2(0.0, -13.0),
		icon_center + Vector2(12.0, 0.0),
		icon_center + Vector2(0.0, 13.0),
		icon_center + Vector2(-12.0, 0.0)
	])
	icon.append(icon[0])
	draw_polyline(icon, Color(0.72, 0.96, 1.0, 0.7), 1.5, true)
	draw_line(icon_center + Vector2(0.0, -5.0), icon_center + Vector2(0.0, 3.0), Color(0.88, 0.98, 1.0, 0.95), 2.0, true)
	draw_circle(icon_center + Vector2(0.0, 7.0), 1.5, Color(0.88, 0.98, 1.0, 0.95))

func _on_body_entered(body: Node2D) -> void:
	print("--- Đã phát hiện va chạm với: ", body.name)
	print("Thuộc các Groups: ", body.get_groups())
	
	# Bỏ qua Player
	if body.name == "Player" or body.is_in_group("Player"):
		print("--> Đây là Player, bỏ qua.")
		return
		
	# In ra để xem con quái đang mang tên hoặc group gì
	print("--> Đây là đối tượng khác, tiến hành phát âm thanh cảnh báo!")
	
	if alert_sound and alert_sound.stream:
		if not alert_sound.playing:
			alert_sound.play()
	else:
		print("Lỗi: AudioStreamPlayer chưa có file âm thanh hoặc chưa được gán đúng!")
