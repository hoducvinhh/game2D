extends Node

var is_game_over: bool = false

# Sửa lại đúng tên file là WinMenu.tscn (viết hoa chữ W và M)
const WIN_MENU_SCENE = preload("res://scenes/ui/winmenu.tscn")
const VICTORY_SOUND = preload("res://scenes/ui/emand_edroff-victory-bell-success-fanfare-576275.mp3")

func trigger_win() -> void:
	if is_game_over:
		return
	is_game_over = true
	AudioManager.play_sound(VICTORY_SOUND)
	
	# Instantiate bảng Win hiển thị lên màn hình chơi game hiện tại
	var win_ui = WIN_MENU_SCENE.instantiate()
	get_tree().current_scene.add_child(win_ui)
	
	# Tạm dừng toàn bộ hoạt động trong game khi thắng
	get_tree().paused = true
