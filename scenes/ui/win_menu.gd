extends CanvasLayer

const WIN_SOUND: AudioStream = preload("res://assets/music/win.mp3")
const RUN_SUMMARY = preload("res://scripts/ui/run_summary.gd")

@onready var btn_replay: Button = $UIContainer/PanelContainer/MarginContainer/VBoxContainer/VBoxContainerButtons/BtnReplay
@onready var btn_home: Button = $UIContainer/PanelContainer/MarginContainer/VBoxContainer/VBoxContainerButtons/BtnHome
@onready var btn_settings: Button = $UIContainer/PanelContainer/MarginContainer/VBoxContainer/VBoxContainerButtons/BtnSettings

# Khai báo đường dẫn đến node phát âm thanh
@onready var audio_player: AudioStreamPlayer = $UIContainer/PanelContainer/MarginContainer/VBoxContainer/AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Kết nối sự kiện bấm nút
	btn_replay.pressed.connect(_on_replay_pressed)
	btn_home.pressed.connect(_on_home_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)
	
	if audio_player:
		audio_player.stream = WIN_SOUND
		audio_player.play()

	var panel: PanelContainer = $UIContainer/PanelContainer
	var content: VBoxContainer = $UIContainer/PanelContainer/MarginContainer/VBoxContainer
	var buttons: Control = $UIContainer/PanelContainer/MarginContainer/VBoxContainer/VBoxContainerButtons
	var summary_panel: PanelContainer = RUN_SUMMARY.create_panel()
	content.add_child(summary_panel)
	content.move_child(summary_panel, buttons.get_index())
	panel.custom_minimum_size.x = 520.0
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	await get_tree().process_frame
	panel.size = panel.get_combined_minimum_size()
	panel.position = (get_viewport().get_visible_rect().size - panel.size) * 0.5

func _on_replay_pressed() -> void:
	get_tree().paused = false
	GameData.start_random_run()
	get_tree().reload_current_scene() # Reset lại map chơi lại từ đầu

func _on_home_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/levels/main_menu.tscn") # Quay về màn hình chính (đổi lại đường dẫn nếu cần)

func _on_settings_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/settings.tscn") # Chuyển sang màn hình cài đặt âm lượng tổng riêng biệt
