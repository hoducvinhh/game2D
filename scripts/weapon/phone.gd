# phone.gd
extends Node2D

var level: int = 1
const MAX_LEVEL: int = 5
var is_evolved: bool = false
var cooldown_duration: float = 12.0
var cooldown_remaining: float = 0.0

@export var fear_duration: float = 2.5
@export var fear_radius: float = 220.0 # Bán kính sóng âm phát ra

const UPGRADE_DESCRIPTIONS = {
	2: "Tăng 1 giây thời gian hoảng sợ",
	3: "Mở rộng vùng ảnh hưởng sóng điện thoại",
	4: "Giảm thời gian hồi chiêu đổ chuông",
	5: "Gây hoảng sợ cực đại (4 giây)"
}

func _process(delta: float) -> void:
	cooldown_remaining = maxf(0.0, cooldown_remaining - delta)

func activate() -> bool:
	if cooldown_remaining > 0.0:
		return false
	cooldown_remaining = cooldown_duration
	trigger_fear()
	return true

func trigger_fear() -> void:
	# Hiệu ứng nảy nhẹ khi phát chuông
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.08)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.08)

	# Quét trực tiếp danh sách quái trong group "enemies" mà không cần đợi physics frame
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.has_method("apply_fear"):
			if global_position.distance_to(enemy.global_position) <= fear_radius:
				enemy.apply_fear(fear_duration, global_position)

func level_up() -> void:
	if level < MAX_LEVEL:
		level += 1
		match level:
			2:
				fear_duration = 3.5
			3:
				fear_radius *= 1.3
			4:
				cooldown_duration = maxf(7.0, cooldown_duration - 2.0)
			5:
				fear_duration = 4.5
		
func evolve() -> bool:
	if is_evolved or level < MAX_LEVEL:
		return false
	is_evolved = true
	fear_duration += 2.0
	fear_radius *= 1.5
	cooldown_duration = maxf(6.0, cooldown_duration * 0.7)
	return true
