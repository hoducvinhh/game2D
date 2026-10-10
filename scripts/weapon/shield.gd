# shield.gd
extends Node2D

var level: int = 1
const MAX_LEVEL: int = 5
const DURATION: float = 10.0
var remaining_duration: float = 0.0
var cooldown_duration: float = 25.0
var cooldown_remaining: float = 0.0
var is_evolved: bool = false
@onready var shield_sprite: Sprite2D = $Sprite2D

# Tỉ lệ giảm sát thương theo từng cấp (% giảm trừ)
var damage_reduction_rates = {
	1: 0.15, # Giảm 15%
	2: 0.25, # Giảm 25%
	3: 0.35, # Giảm 35%
	4: 0.45, # Giảm 45%
	5: 0.60  # Giảm 60%
}

const UPGRADE_DESCRIPTIONS = {
	2: "Giảm 25% sát thương nhận vào",
	3: "Giảm 35% sát thương nhận vào",
	4: "Giảm 45% sát thương nhận vào",
	5: "Giảm tối đa 60% sát thương nhận vào"
}

func _process(delta: float) -> void:
	cooldown_remaining = maxf(0.0, cooldown_remaining - delta)
	if remaining_duration > 0.0:
		remaining_duration = maxf(0.0, remaining_duration - delta)
		rotation += 1.5 * delta
		if remaining_duration == 0.0:
			visible = false

func activate() -> bool:
	if cooldown_remaining > 0.0:
		return false
	cooldown_remaining = DURATION + cooldown_duration
	remaining_duration = DURATION
	rotation = 0.0
	visible = true
	return true

func _ready() -> void:
	visible = false

func level_up() -> void:
	if level < MAX_LEVEL:
		level += 1

# Trả về % sát thương được giảm hiện tại
func get_damage_reduction() -> float:
	if remaining_duration <= 0.0:
		return 0.0
	return damage_reduction_rates.get(level, 0.15)

func evolve() -> bool:
	if is_evolved or level < MAX_LEVEL:
		return false
	is_evolved = true
	damage_reduction_rates[5] = 0.75
	return true
