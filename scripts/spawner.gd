extends Node2D

var basic_enemy_scene: PackedScene = load("res://scenes/enemies/enemy.tscn")
var fast_enemy_scene: PackedScene = load("res://scenes/enemies/fast_enemy.tscn")
var ranged_enemy_scene: PackedScene = load("res://scenes/enemies/ranged_enemy.tscn")
var boss_scene: PackedScene = load("res://scenes/enemies/boss.tscn")
var pet_scene: PackedScene = load("res://scenes/characters/companion_pet.tscn")

@onready var timer: Timer = $Timer

@export var batch_size: int = 5
@export var max_active_enemies: int = 85

var time_elapsed: float = 0.0
var boss_spawned: bool = false

func _ready() -> void:
	timer.timeout.connect(_on_timer_timeout)
	timer.stop()
	var difficulty: Dictionary = GameData.DIFFICULTIES.get(
		GameData.selected_difficulty_id,
		GameData.DIFFICULTIES["hard"]
	)
	timer.wait_time = difficulty.get("spawn_interval", 2.0)
	batch_size = difficulty.get("batch_size", 5)
	timer.start()
	
	# Sinh ra bạn đồng hành (Pet) ngay khi vào trận
	call_deferred("_spawn_companion_pet")

func _process(delta: float) -> void:
	time_elapsed += delta
	
	# Sinh Boss ở mốc 40 giây (hoặc khi gần kết thúc màn)
	if not boss_spawned and time_elapsed >= 40.0:
		boss_spawned = true
		_spawn_boss()

func _spawn_companion_pet() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and pet_scene:
		var pet = pet_scene.instantiate()
		pet.global_position = player.global_position + Vector2(-30, 20)
		get_tree().current_scene.add_child(pet)

func _spawn_boss() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player or not boss_scene:
		return
	var boss = boss_scene.instantiate()
	boss.global_position = player.global_position + Vector2(0, -450)
	get_tree().current_scene.add_child(boss)
	print("[BOSS SPAWNED] Chúa Tể Hư Không đã xuất hiện!")

func _on_timer_timeout() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	# Giới hạn số lượng quái đồng thời để đảm bảo hiệu năng 60 FPS mượt mà
	var current_enemy_count = get_tree().get_nodes_in_group("enemies").size()
	if current_enemy_count >= max_active_enemies:
		return

	for i in range(batch_size):
		var spawn_distance = randf_range(520.0, 720.0)
		var spawn_angle = randf() * PI * 2
		var spawn_offset = Vector2(cos(spawn_angle), sin(spawn_angle)) * spawn_distance
		var spawn_position = player.global_position + spawn_offset

		# Chọn loại quái theo mốc thời gian (Wave progression)
		var selected_scene = basic_enemy_scene
		var roll = randf()
		var map_data: Dictionary = GameData.MAPS.get(GameData.selected_map_id, GameData.MAPS["map_1"])
		var ranged_chance: float = map_data.get("ranged_chance", 0.15)
		var fast_chance: float = 0.3 if GameData.selected_map_id == "map_2" else 0.2
		if time_elapsed >= 20.0:
			if roll < ranged_chance and ranged_enemy_scene:
				selected_scene = ranged_enemy_scene
			elif roll < ranged_chance + fast_chance and fast_enemy_scene:
				selected_scene = fast_enemy_scene
		elif time_elapsed >= 10.0 and GameData.selected_map_id == "map_2":
			if roll < 0.35 and fast_enemy_scene:
				selected_scene = fast_enemy_scene

		if selected_scene:
			var enemy = selected_scene.instantiate()
			enemy.global_position = spawn_position
			get_tree().current_scene.add_child(enemy)
