extends CanvasLayer
class_name PauseMenu

@onready var btn_resume: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/BtnResume
@onready var btn_settings: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/BtnSettings
@onready var btn_menu: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/BtnMenu

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 25
	add_to_group("pause_menu")
	hide()
	
	btn_resume.pressed.connect(_on_resume_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)
	btn_menu.pressed.connect(_on_menu_pressed)

func _input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE)):
		toggle_pause()

func toggle_pause() -> void:
	var is_paused = not visible
	visible = is_paused
	get_tree().paused = is_paused

func _on_resume_pressed() -> void:
	visible = false
	get_tree().paused = false

func _on_settings_pressed() -> void:
	hide()
	GameData.settings_return_scene = ""
	var settings: Node = load("res://scenes/ui/settings.tscn").instantiate()
	settings.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().current_scene.add_child(settings)

func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/levels/main_menu.tscn")
