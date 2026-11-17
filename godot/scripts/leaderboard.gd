extends Control

@onready var background: TextureRect = $Background
@onready var title_label: Label = $Center/Panel/Margin/VBox/TitleLabel
@onready var scores_label: Label = $Center/Panel/Margin/VBox/ScoresLabel
@onready var again_button: Button = $Center/Panel/Margin/VBox/AgainButton
@onready var menu_button: Button = $Center/Panel/Margin/VBox/MenuButton


func _ready() -> void:
	if not OS.has_feature("web"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	background.texture = load("res://assets/background/background_map_1.png")
	title_label.text = "PLACAR — TOP 10"
	_fill_scores()
	again_button.pressed.connect(_on_again)
	menu_button.pressed.connect(_on_menu)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _fill_scores() -> void:
	if OS.has_feature("web"):
		scores_label.text = "Carregando placar..."
		var request := HTTPRequest.new()
		add_child(request)
		request.request_completed.connect(_on_scores_loaded)
	if request.request(GameState.api_url("/api/leaderboard")) != OK:
			_show_scores(GameState.load_highscores())
		return
	_show_scores(GameState.load_highscores())


func _on_scores_loaded(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		_show_scores(GameState.load_highscores())
		return
	var payload = JSON.parse_string(body.get_string_from_utf8())
	if not (payload is Dictionary):
		_show_scores(GameState.load_highscores())
		return
	_show_scores(payload.get("scores", []))


func _show_scores(scores: Array) -> void:
	if scores.is_empty():
		scores_label.text = "Nenhum recorde ainda.\nSeja o primeiro!"
		return
	var lines: PackedStringArray = []
	for i in range(scores.size()):
		var entry: Dictionary = scores[i]
		var t := _format_time(float(entry.get("time_ms", 0.0)))
		lines.append("%2d. %-3s  %5d   %s" % [
			i + 1,
			str(entry.get("name", "???")),
			int(entry.get("score", 0)),
			t,
		])
	scores_label.text = "\n".join(lines)


func _format_time(ms: float) -> String:
	var total_sec := int(ms / 1000.0)
	return "%02d:%02d" % [total_sec / 60, total_sec % 60]


func _on_again() -> void:
	GameState.ranking_mode = true
	get_tree().change_scene_to_file("res://scenes/loading_screen.tscn")


func _on_menu() -> void:
	GameState.ranking_mode = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
