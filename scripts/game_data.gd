extends Node

signal gold_changed(total_gold: int)
signal achievement_unlocked(achievement_id: String)

const SAVE_PATH := "user://profile.cfg"
const MAPS := {
	"map_1": {
		"name": "Bản Làng Khởi Đầu",
		"description": "Chiến trường cơ bản, không có hiệu ứng địa hình.",
		"background_path": "res://assets/background.jpg",
		"hazard": "none",
		"ranged_chance": 0.15
	},
	"map_2": {
		"name": "Rừng Ma Bí Ẩn",
		"description": "Vùng sương làm chậm người chơi theo chu kỳ.",
		"background_path": "res://assets/nenmoi1.jpg",
		"hazard": "slow",
		"ranged_chance": 0.25
	},
	"map_3": {
		"name": "Lãnh Địa Hư Không",
		"description": "Tia sét được cảnh báo trước, gây sát thương trong vùng nhỏ.",
		"background_path": "res://assets/nenmoi2.jpg",
		"hazard": "lightning",
		"ranged_chance": 0.35
	}
}
const RUN_ENEMY_TYPES: Array[String] = ["basic", "fast", "ranged"]
const DIFFICULTIES := {
	"easy": {
		"name": "Dễ",
		"spawn_interval": 3.0,
		"batch_size": 3,
		"description": "3 quái mỗi 3 giây"
	},
	"hard": {
		"name": "Khó",
		"spawn_interval": 2.0,
		"batch_size": 5,
		"description": "5 quái mỗi 2 giây"
	},
	"super_hard": {
		"name": "Siêu khó",
		"spawn_interval": 1.2,
		"batch_size": 7,
		"description": "7 quái mỗi 1,2 giây"
	}
}
const CHARACTERS := {
	"default": {
		"name": "Lil' Boy Tộc Trưởng",
		"price": 0,
		"description": "Chỉ số cân bằng, súng mía cơ bản.",
		"portrait_path": "res://assets/sprites/player/character_selection.png",
		"sprite_path": "res://assets/sprites/player/normal.png",
		"run_path": "res://assets/sprites/player/run.png",
		"attack_path": "res://assets/sprites/player/attack.png",
		"bonus_hp": 0,
		"bonus_speed": 0.0
	},
	"red_hair": {
		"name": "Chiến Binh Râu Đỏ",
		"price": 100,
		"description": "Máu dồi dào (+40 HP), vũ khí cận chiến uy lực.",
		"portrait_path": "res://assets/sprites/player/new_character.png",
		"normal_path": "res://assets/sprites/player/new_character_normal.png",
		"jump_path": "res://assets/sprites/player/new_character_jump.png",
		"attack_path": "res://assets/sprites/player/new_character_attack.png",
		"bonus_hp": 40,
		"bonus_speed": -10.0
	},
	"mage_vu": {
		"name": "Pháp Sư Vũ",
		"price": 200,
		"description": "Tốc độ cao (+20%), tầm khói Shisa & sóng âm rộng.",
		"portrait_path": "res://assets/sprites/player/mage_vu_portrait.png",
		"fallback_portrait": "res://assets/sprites/player/new_character.png",
		"normal_path": "res://assets/sprites/player/mage_vu_normal.png",
		"run_path": "res://assets/sprites/player/mage_vu_run.png",
		"attack_path": "res://assets/sprites/player/mage_vu_attack.png",
		"bonus_hp": -10,
		"bonus_speed": 35.0
	},
	"sniper": {
		"name": "Xạ Thủ Bã Mía",
		"price": 300,
		"description": "Tầm bắn xa, đạn mía bay nhanh, tỉ lệ bạo kích cao.",
		"portrait_path": "res://assets/sprites/player/sniper_portrait.png",
		"fallback_portrait": "res://assets/sprites/player/character_selection.png",
		"normal_path": "res://assets/sprites/player/sniper_normal.png",
		"run_path": "res://assets/sprites/player/sniper_run.png",
		"attack_path": "res://assets/sprites/player/sniper_attack.png",
		"bonus_hp": 10,
		"bonus_speed": 15.0
	}
}

const TALENTS := {
	"max_hp": {"name": "Máu Tối Đa", "base_cost": 50, "max_level": 5, "desc": "+15 HP mỗi cấp"},
	"speed": {"name": "Tốc Độ Di Chuyển", "base_cost": 50, "max_level": 5, "desc": "+5% Tốc độ mỗi cấp"},
	"damage": {"name": "Sát Thương Toàn Thể", "base_cost": 75, "max_level": 5, "desc": "+8% Sát thương mỗi cấp"},
	"pickup_range": {"name": "Lực Hút Nam Châm", "base_cost": 40, "max_level": 5, "desc": "+20% Bán kính nhặt đồ"},
	"greed": {"name": "Thần Tài May Mắn", "base_cost": 60, "max_level": 5, "desc": "+10% Tỉ lệ nhận vàng"}
}

const ACHIEVEMENTS := {
	"first_blood": {"name": "Khởi Đầu", "description": "Tiêu diệt 10 kẻ địch.", "reward": 25, "target": 10},
	"gold_collector": {"name": "Tích Tiểu Thành Đại", "description": "Nhặt tổng cộng 100 vàng.", "reward": 40, "target": 100},
	"boss_slayer": {"name": "Kẻ Săn Trùm", "description": "Đánh bại Chúa Tể Hư Không.", "reward": 75, "target": 1},
	"map_veteran": {"name": "Chinh Phục Chiến Trường", "description": "Hoàn thành một lượt ở mỗi bản đồ.", "reward": 100, "target": 3},
	"evolutionist": {"name": "Tiến Hóa Tối Đa", "description": "Tiến hóa một vũ khí.", "reward": 50, "target": 1},
	"super_hard_clear": {"name": "Không Khoan Nhượng", "description": "Hoàn thành lượt chơi ở độ khó Siêu khó.", "reward": 60, "target": 1}
}

var talent_levels := {
	"max_hp": 0,
	"speed": 0,
	"damage": 0,
	"pickup_range": 0,
	"greed": 0
}

var gold: int = 0
var unlocked_characters: Array[String] = ["default"]
var selected_character_id: String = "default"
var selected_map_id: String = "map_1"
var run_map_order: Array[String] = []
var run_enemy_type_by_map: Dictionary = {}
var current_run_map_id: String = ""
var selected_difficulty_id: String = "hard"
var completed_runs: Array[Dictionary] = []
var achievement_progress: Dictionary = {"kills": 0, "gold": 0, "completed_maps": [], "unlocked": []}
var touch_controls_enabled: bool = true
var master_volume: float = 1.0
var settings_return_scene: String = "res://scenes/levels/main_menu.tscn"

func _ready() -> void:
	_load_profile()
	var master_bus_index := AudioServer.get_bus_index("Master")
	if master_bus_index >= 0:
		AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(maxf(master_volume, 0.001)))

func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	gold += amount
	_save_profile()
	gold_changed.emit(gold)

func get_damage_multiplier() -> float:
	return 1.0 + get_talent_level("damage") * 0.08

func get_pickup_radius(base_radius: float) -> float:
	var bonus := 1.0 + get_talent_level("pickup_range") * 0.2
	var player := get_tree().get_first_node_in_group("player")
	if player:
		var passives: Variant = player.get("passive_items")
		if passives is Array and passives.has("pickup_range"):
			bonus += 0.25
	return base_radius * bonus

func get_gold_drop_chance(base_chance: float) -> float:
	var bonus := get_talent_level("greed") * 0.1
	var player := get_tree().get_first_node_in_group("player")
	if player:
		var passives: Variant = player.get("passive_items")
		if passives is Array and passives.has("greed"):
			bonus += 0.15
	return clampf(base_chance + bonus, 0.0, 1.0)

func record_enemy_kill() -> void:
	achievement_progress["kills"] = int(achievement_progress.get("kills", 0)) + 1
	if achievement_progress["kills"] >= ACHIEVEMENTS["first_blood"]["target"]:
		_unlock_achievement("first_blood")
	_save_profile()

func record_gold_collected(amount: int) -> void:
	if amount <= 0:
		return
	achievement_progress["gold"] = int(achievement_progress.get("gold", 0)) + amount
	if achievement_progress["gold"] >= ACHIEVEMENTS["gold_collector"]["target"]:
		_unlock_achievement("gold_collector")
	_save_profile()

func record_boss_defeated() -> void:
	_unlock_achievement("boss_slayer")

func record_weapon_evolved(_weapon_id: String) -> void:
	_unlock_achievement("evolutionist")

func _unlock_achievement(achievement_id: String) -> void:
	var unlocked: Array = achievement_progress.get("unlocked", [])
	if not ACHIEVEMENTS.has(achievement_id) or unlocked.has(achievement_id):
		return
	unlocked.append(achievement_id)
	achievement_progress["unlocked"] = unlocked
	gold += int(ACHIEVEMENTS[achievement_id]["reward"])
	_save_profile()
	gold_changed.emit(gold)
	achievement_unlocked.emit(achievement_id)

func save_settings() -> void:
	_save_profile()

func is_character_unlocked(character_id: String) -> bool:
	return unlocked_characters.has(character_id)

func purchase_character(character_id: String) -> bool:
	var character: Dictionary = CHARACTERS.get(character_id, {})
	if character.is_empty() or is_character_unlocked(character_id):
		return false

	var price: int = character.get("price", 0)
	if gold < price:
		return false

	gold -= price
	unlocked_characters.append(character_id)
	selected_character_id = character_id
	_save_profile()
	gold_changed.emit(gold)
	return true

func select_character(character_id: String) -> bool:
	if not CHARACTERS.has(character_id) or not is_character_unlocked(character_id):
		return false
	selected_character_id = character_id
	_save_profile()
	return true

func select_map(map_id: String) -> bool:
	if not MAPS.has(map_id):
		return false
	selected_map_id = map_id
	_save_profile()
	return true

func start_random_run() -> void:
	run_map_order = ["map_1", "map_2", "map_3"]
	run_map_order.shuffle()

	var enemy_types := RUN_ENEMY_TYPES.duplicate()
	enemy_types.shuffle()
	run_enemy_type_by_map.clear()
	for index in range(run_map_order.size()):
		run_enemy_type_by_map[run_map_order[index]] = enemy_types[index]

	current_run_map_id = run_map_order[0]

func select_difficulty(difficulty_id: String) -> bool:
	if not DIFFICULTIES.has(difficulty_id):
		return false
	selected_difficulty_id = difficulty_id
	_save_profile()
	return true

func record_completed_run(map_id: String, difficulty_id: String, survival_seconds: int) -> void:
	if not MAPS.has(map_id) or not DIFFICULTIES.has(difficulty_id):
		return
	completed_runs.push_front({
		"map_id": map_id,
		"difficulty_id": difficulty_id,
		"survival_seconds": survival_seconds,
		"completed_at": int(Time.get_unix_time_from_system())
	})
	if completed_runs.size() > 50:
		completed_runs.resize(50)
	var completed_maps: Array = achievement_progress.get("completed_maps", [])
	if not completed_maps.has(map_id):
		completed_maps.append(map_id)
	achievement_progress["completed_maps"] = completed_maps
	if completed_maps.size() >= ACHIEVEMENTS["map_veteran"]["target"]:
		_unlock_achievement("map_veteran")
	if difficulty_id == "super_hard":
		_unlock_achievement("super_hard_clear")
	_save_profile()

func _load_profile() -> void:
	var config := ConfigFile.new()
	var load_error := config.load(SAVE_PATH)
	if load_error == ERR_FILE_NOT_FOUND:
		_save_profile()
		return
	if load_error != OK:
		push_error("Unable to load profile %s: %s" % [SAVE_PATH, error_string(load_error)])
		return

	gold = maxi(0, int(config.get_value("profile", "gold", 0)))
	unlocked_characters.clear()
	var saved_characters: Array = config.get_value("profile", "unlocked_characters", ["default"])
	for character_id in saved_characters:
		if character_id is String and CHARACTERS.has(character_id) and not unlocked_characters.has(character_id):
			unlocked_characters.append(character_id)
	if not unlocked_characters.has("default"):
		unlocked_characters.push_front("default")

	var saved_selection: String = config.get_value("profile", "selected_character_id", "default")
	selected_character_id = saved_selection if is_character_unlocked(saved_selection) else "default"
	var saved_map: String = config.get_value("profile", "selected_map_id", "map_1")
	selected_map_id = saved_map if MAPS.has(saved_map) else "map_1"
	var saved_difficulty: String = config.get_value("profile", "selected_difficulty_id", "hard")
	selected_difficulty_id = saved_difficulty if DIFFICULTIES.has(saved_difficulty) else "hard"
	completed_runs.clear()
	var saved_runs: Array = config.get_value("profile", "completed_runs", [])
	for run in saved_runs:
		if run is Dictionary and MAPS.has(run.get("map_id", "")) and DIFFICULTIES.has(run.get("difficulty_id", "")):
			completed_runs.append(run)
	if completed_runs.size() > 50:
		completed_runs.resize(50)

	for talent_id in TALENTS:
		talent_levels[talent_id] = clampi(int(config.get_value("talents", talent_id, 0)), 0, int(TALENTS[talent_id]["max_level"]))
	achievement_progress["kills"] = maxi(0, int(config.get_value("achievements", "kills", 0)))
	achievement_progress["gold"] = maxi(0, int(config.get_value("achievements", "gold", 0)))
	var saved_completed_maps: Variant = config.get_value("achievements", "completed_maps", [])
	var saved_achievements: Variant = config.get_value("achievements", "unlocked", [])
	achievement_progress["completed_maps"] = saved_completed_maps if saved_completed_maps is Array else []
	achievement_progress["unlocked"] = saved_achievements if saved_achievements is Array else []
	achievement_progress["completed_maps"] = achievement_progress["completed_maps"].filter(func(map_id): return MAPS.has(map_id))
	achievement_progress["unlocked"] = achievement_progress["unlocked"].filter(func(id): return ACHIEVEMENTS.has(id))
	touch_controls_enabled = bool(config.get_value("settings", "touch_controls_enabled", true))
	master_volume = clampf(float(config.get_value("settings", "master_volume", 1.0)), 0.0, 1.0)

func _save_profile() -> void:
	var config := ConfigFile.new()
	config.set_value("profile", "gold", gold)
	config.set_value("profile", "unlocked_characters", unlocked_characters)
	config.set_value("profile", "selected_character_id", selected_character_id)
	config.set_value("profile", "selected_map_id", selected_map_id)
	config.set_value("profile", "selected_difficulty_id", selected_difficulty_id)
	config.set_value("profile", "completed_runs", completed_runs)
	config.set_value("achievements", "kills", achievement_progress.get("kills", 0))
	config.set_value("achievements", "gold", achievement_progress.get("gold", 0))
	config.set_value("achievements", "completed_maps", achievement_progress.get("completed_maps", []))
	config.set_value("achievements", "unlocked", achievement_progress.get("unlocked", []))
	config.set_value("settings", "touch_controls_enabled", touch_controls_enabled)
	config.set_value("settings", "master_volume", master_volume)
	for talent_id in talent_levels:
		config.set_value("talents", talent_id, talent_levels[talent_id])
	var save_error := config.save(SAVE_PATH)
	if save_error != OK:
		push_error("Unable to save profile %s: %s" % [SAVE_PATH, error_string(save_error)])

func get_talent_level(talent_id: String) -> int:
	return talent_levels.get(talent_id, 0)

func get_talent_cost(talent_id: String) -> int:
	if not TALENTS.has(talent_id):
		return 999999
	var current_lvl: int = talent_levels.get(talent_id, 0)
	return TALENTS[talent_id].get("base_cost", 50) * (current_lvl + 1)

func upgrade_talent(talent_id: String) -> bool:
	if not TALENTS.has(talent_id):
		return false
	var talent_info: Dictionary = TALENTS[talent_id]
	var current_lvl: int = talent_levels.get(talent_id, 0)
	var max_lvl: int = talent_info.get("max_level", 5)
	if current_lvl >= max_lvl:
		return false
	var cost: int = get_talent_cost(talent_id)
	if gold < cost:
		return false
	gold -= cost
	talent_levels[talent_id] = current_lvl + 1
	_save_profile()
	gold_changed.emit(gold)
	return true
