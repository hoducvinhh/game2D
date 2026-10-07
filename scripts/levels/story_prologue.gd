extends Control

const MAIN_MENU_PATH := "res://scenes/levels/main_menu.tscn"
const CHARACTER_LOBBY_PATH := "res://scenes/levels/character_lobby.tscn"

@onready var story_label: Label = $MarginContainer/VBoxContainer/PanelStory/MarginText/StoryLabel
@onready var btn_next: Button = $MarginContainer/VBoxContainer/HBoxNav/BtnNext
@onready var btn_skip: Button = $MarginContainer/VBoxContainer/HBoxNav/BtnSkip
@onready var title_label: Label = $MarginContainer/VBoxContainer/Header/Title

const STORY_PARAGRAPHS := [
	"Năm 2026, tại một bản làng thanh bình của Tộc trưởng Lil' Boy Domixi, một vết nứt không gian kỳ bí bất ngờ mở ra. Cơn Bão Hư Không bao trùm vạn vật, kéo theo hàng ngàn sinh vật biến dị và các bản thể tha hóa tràn vào xâm lăng.",
	"Buôn làng đứng trước nguy cơ sụp đổ. Trước tình thế ngàn cân treo sợi tóc, Tộc trưởng cùng những người anh em chí cốt đã vác trên tay những bảo vật truyền thuyết: Cây Chày Thần Lực, Bã Mía Hoàng Kim, Điếu Shisa Ngũ Hành và Chiếc Điện Thoại Cứu Viện...",
	"Để phong ấn vĩnh viễn vết nứt Hư Không, người được chọn phải vượt qua các chiến trường khắc nghiệt từ Bản Làng, Rừng Ma cho đến Đấu Trường Hư Không, tiêu diệt bầy quái vật và đánh bại Chúa Tể Hư Không để mang lại hòa bình!",
	"Hãy cầm chắc vũ khí, chuẩn bị cho cuộc chiến sinh tồn vĩ đại nhất lịch sử buôn làng!"
]

var current_index: int = 0
var typing_tween: Tween

func _ready() -> void:
	btn_next.pressed.connect(_on_next_pressed)
	btn_skip.pressed.connect(_on_skip_pressed)
	_display_paragraph(0)

func _display_paragraph(index: int) -> void:
	current_index = index
	var text = STORY_PARAGRAPHS[index]
	story_label.text = text
	story_label.visible_characters = 0
	
	if typing_tween and typing_tween.is_valid():
		typing_tween.kill()
		
	typing_tween = create_tween()
	var duration = float(text.length()) * 0.02
	typing_tween.tween_property(story_label, "visible_characters", text.length(), duration)
	
	if current_index == STORY_PARAGRAPHS.size() - 1:
		btn_next.text = "VÀO TRẬN CHIẾN >>"
	else:
		btn_next.text = "TIẾP TỤC >>"

func _on_next_pressed() -> void:
	# Nếu chữ đang chạy mà bấm tiếp thì hiện hết chữ ngay
	if story_label.visible_characters < STORY_PARAGRAPHS[current_index].length():
		if typing_tween and typing_tween.is_valid():
			typing_tween.kill()
		story_label.visible_characters = STORY_PARAGRAPHS[current_index].length()
		return
		
	if current_index < STORY_PARAGRAPHS.size() - 1:
		_display_paragraph(current_index + 1)
	else:
		get_tree().change_scene_to_file(CHARACTER_LOBBY_PATH)

func _on_skip_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_PATH)
