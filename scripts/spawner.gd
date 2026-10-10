extends Node2D

var basic_enemy_scene: PackedScene = load("res://scenes/enemies/enemy.tscn")
var fast_enemy_scene: PackedScene = load("res://scenes/enemies/fast_enemy.tscn")
var ranged_enemy_scene: PackedScene = load("res://scenes/enemies/ranged_enemy.tscn")
var boss_scene: PackedScene = load("res://scenes/enemies/boss.tscn")
var pet_scene: PackedScene = load("res://scenes/characters/companion_pet.tscn")

@onready var timer: Timer = $Timer

var quest_tracker: Node
var current_map_id: String = ""
var current_enemy_type: String = "basic"
var current_batch_size: int = 5
var current_spawn_interval: float = 2.0

@export var batch_size: int = 5
@export var max_active_enemies: int = 85

enum RunPhase { MAP, TRANSITION, BOSS }

var phase: RunPhase = RunPhase.MAP
var map_index: int = 0
var map_time_elapsed: float = 0.0
var pet_spawn_pending: bool = false
var awaiting_continue_confirmation: bool = false

func _ready() -> void:
	add_to_group("run_progression")
	if GameData.run_map_order.size() != GameData.MAPS.size() or GameData.run_enemy_type_by_map.size() != GameData.MAPS.size():
		GameData.start_random_run()

	timer.timeout.connect(_on_timer_timeout)
	timer.stop()
	_apply_difficulty_settings()
	call_deferred("_spawn_companion_pet")

func _apply_difficulty_settings() -> void:
	var difficulty: Dictionary = GameData.DIFFICULTIES.get(
		GameData.selected_difficulty_id,
		GameData.DIFFICULTIES["hard"]
	)
	current_spawn_interval = difficulty.get("spawn_interval", 2.0)
	current_batch_size = difficulty.get("batch_size", 5)
	timer.wait_time = current_spawn_interval
	batch_size = current_batch_size

func _process(delta: float) -> void:
	if phase == RunPhase.MAP:
		map_time_elapsed += delta

func bind_quest_tracker(tracker: Node) -> void:
	quest_tracker = tracker
	if not quest_tracker.is_connected("stage_completed", _on_stage_completed):
		quest_tracker.connect("stage_completed", _on_stage_completed)
	if not quest_tracker.is_connected("continue_requested", _on_continue_requested):
		quest_tracker.connect("continue_requested", _on_continue_requested)
	_begin_map_stage()

func record_normal_enemy_kill() -> void:
	if phase == RunPhase.MAP and is_instance_valid(quest_tracker):
		quest_tracker.call("record_kill")

func _begin_map_stage() -> void:
	phase = RunPhase.MAP
	map_time_elapsed = 0.0
	var map_id: String = GameData.run_map_order[map_index]
	current_map_id = map_id
	GameData.current_run_map_id = map_id
	current_enemy_type = GameData.run_enemy_type_by_map.get(map_id, "basic")
	var main_scene := get_tree().current_scene
	if main_scene and main_scene.has_method("apply_run_map"):
		main_scene.call("apply_run_map", map_id)
	else:
		push_error("Main scene is missing apply_run_map")
	_apply_difficulty_settings()
	if is_instance_valid(quest_tracker):
		quest_tracker.call("begin_map_stage", map_index + 1, GameData.run_map_order.size(), map_id, current_enemy_type)
	timer.start()

func _on_stage_completed() -> void:
	if phase != RunPhase.MAP:
		return

	phase = RunPhase.TRANSITION
	awaiting_continue_confirmation = true
	timer.stop()
	GameData.record_completed_run(
		GameData.current_run_map_id,
		GameData.selected_difficulty_id,
		int(map_time_elapsed)
	)
	get_tree().paused = true
	if is_instance_valid(quest_tracker):
		quest_tracker.call("show_stage_completion", map_index + 1, GameData.run_map_order.size())

func _on_continue_requested(should_continue: bool) -> void:
	if phase != RunPhase.TRANSITION or not awaiting_continue_confirmation:
		return
	awaiting_continue_confirmation = false
	get_tree().paused = false
	if should_continue:
		call_deferred("_advance_run")
	else:
		get_tree().quit()

func _advance_run() -> void:
	_clear_stage_entities()
	map_index += 1
	if map_index >= GameData.run_map_order.size():
		_begin_boss_phase()
	else:
		_begin_map_stage()

func _begin_boss_phase() -> void:
	phase = RunPhase.BOSS
	timer.stop()
	if is_instance_valid(quest_tracker):
		quest_tracker.call("begin_boss_stage")
	_spawn_boss()

func _clear_stage_entities() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			enemy.queue_free()
	for bullet in get_tree().get_nodes_in_group("enemy_bullets"):
		if is_instance_valid(bullet):
			bullet.queue_free()

func _spawn_companion_pet() -> void:
	if pet_spawn_pending:
		return
	pet_spawn_pending = true
	for attempt in range(10):
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if is_instance_valid(player):
			var existing_pet := get_tree().get_first_node_in_group("companion_pet")
			if is_instance_valid(existing_pet):
				pet_spawn_pending = false
				return
			if not pet_scene:
				push_error("Cannot spawn companion pet: pet scene is missing")
				pet_spawn_pending = false
				return
			var pet := pet_scene.instantiate() as Node2D
			get_tree().current_scene.add_child(pet)
			pet.global_position = player.global_position + Vector2(-120.0, 20.0)
			pet_spawn_pending = false
			return
		await get_tree().process_frame
	push_error("Cannot spawn companion pet: player was not ready")
	pet_spawn_pending = false

func _spawn_boss() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not player or not boss_scene:
		push_error("Cannot start the boss phase without a player and boss scene")
		return
	var boss := boss_scene.instantiate() as Node2D
	if not boss:
		push_error("Boss scene root must be a Node2D")
		return
	get_tree().current_scene.add_child(boss)
	boss.global_position = player.global_position + Vector2.from_angle(randf() * TAU) * 1000.0
	print("[BOSS SPAWNED] Chúa Tể Hư Không đã xuất hiện!")

func _on_timer_timeout() -> void:
	if phase != RunPhase.MAP:
		return
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	var current_enemy_count = get_tree().get_nodes_in_group("enemies").size()
	if current_enemy_count >= max_active_enemies:
		return

	if current_map_id.is_empty():
		current_map_id = GameData.current_run_map_id
	if current_map_id.is_empty():
		current_map_id = GameData.run_map_order[0] if not GameData.run_map_order.is_empty() else "map_1"
	if not GameData.run_enemy_type_by_map.has(current_map_id):
		GameData.start_random_run()
	current_enemy_type = GameData.run_enemy_type_by_map.get(current_map_id, "basic")
	var enemy_scene: PackedScene
	match current_enemy_type:
		"basic":
			enemy_scene = basic_enemy_scene
		"fast":
			enemy_scene = fast_enemy_scene
		"ranged":
			enemy_scene = ranged_enemy_scene
		_:
			push_error("Unknown enemy type for map %s: %s" % [current_map_id, current_enemy_type])
			return

	for i in range(max(1, current_batch_size)):
		var spawn_distance = randf_range(520.0, 720.0)
		var spawn_angle = randf() * PI * 2
		var spawn_offset = Vector2(cos(spawn_angle), sin(spawn_angle)) * spawn_distance
		var spawn_position = player.global_position + spawn_offset
		if not enemy_scene:
			push_error("Missing enemy scene for type %s" % current_enemy_type)
			return
		var enemy := enemy_scene.instantiate() as BaseEnemy
		if not enemy:
			push_error("Enemy scene for %s does not use BaseEnemy" % current_enemy_type)
			return
		enemy.global_position = spawn_position
		get_tree().current_scene.add_child(enemy)
		if get_tree().get_nodes_in_group("enemies").size() >= max_active_enemies:
			break
