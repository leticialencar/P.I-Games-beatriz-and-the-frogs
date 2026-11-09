extends Control

## Entrada clássica de 3 letras (AAA) para o placar.

const LETTERS := "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
const PIXEL_FONT := preload("res://assets/fonts/Minecraftia-Regular.ttf")

@onready var background: TextureRect = $Background
@onready var title_label: Label = $Center/Panel/Margin/VBox/TitleLabel
@onready var score_label: Label = $Center/Panel/Margin/VBox/ScoreLabel
@onready var letter_row: HBoxContainer = $Center/Panel/Margin/VBox/LetterRow
@onready var hint_label: Label = $Center/Panel/Margin/VBox/HintLabel
@onready var confirm_button: Button = $Center/Panel/Margin/VBox/ConfirmButton

var letters: Array[int] = [0, 0, 0] ## índices em LETTERS
var cursor := 0
var letter_labels: Array[Label] = []


func _ready() -> void:
	if not OS.has_feature("web"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	background.texture = load("res://assets/background/background_map_1.png")
	title_label.text = "NOVO RECORDE!"
	score_label.text = "Pontos: %d\nTempo: %s" % [
		GameState.ranking_score,
		_format_time(GameState.game_time_ms),
	]
	hint_label.text = "← → troca a letra   ↑ ↓ muda   Enter confirma"
	_build_letter_labels()
	_refresh_letters()
	confirm_button.pressed.connect(_confirm)


func _build_letter_labels() -> void:
	for child in letter_row.get_children():
		child.queue_free()
	letter_labels.clear()
	for i in range(3):
		var lbl := Label.new()
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.custom_minimum_size = Vector2(72, 72)
		lbl.add_theme_font_override("font", PIXEL_FONT)
		lbl.add_theme_font_size_override("font_size", 40)
		letter_row.add_child(lbl)
		letter_labels.append(lbl)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_LEFT, KEY_A:
			cursor = (cursor + 2) % 3
			_refresh_letters()
		KEY_RIGHT, KEY_D:
			cursor = (cursor + 1) % 3
			_refresh_letters()
		KEY_UP, KEY_W:
			letters[cursor] = (letters[cursor] + 1) % LETTERS.length()
			_refresh_letters()
		KEY_DOWN, KEY_S:
			letters[cursor] = (letters[cursor] - 1 + LETTERS.length()) % LETTERS.length()
			_refresh_letters()
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			_confirm()
		KEY_F11:
			_toggle_fullscreen()


func _refresh_letters() -> void:
	for i in range(3):
		var ch := LETTERS[letters[i]]
		letter_labels[i].text = ch
		if i == cursor:
			letter_labels[i].add_theme_color_override("font_color", Color(1.0, 0.9, 0.25))
		else:
			letter_labels[i].add_theme_color_override("font_color", Color.WHITE)


func _confirm() -> void:
	var name := "%s%s%s" % [
		LETTERS[letters[0]],
		LETTERS[letters[1]],
		LETTERS[letters[2]],
	]
	GameState.submit_highscore(name, GameState.ranking_score, GameState.game_time_ms)
	get_tree().change_scene_to_file("res://scenes/leaderboard.tscn")


func _format_time(ms: float) -> String:
	var total_sec := int(ms / 1000.0)
	var m := total_sec / 60
	var s := total_sec % 60
	return "%02d:%02d" % [m, s]


func _toggle_fullscreen() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
