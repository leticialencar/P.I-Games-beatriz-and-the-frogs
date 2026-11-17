extends Control

const PIXEL_FONT := preload("res://assets/fonts/Minecraftia-Regular.ttf")
const MEDALS := preload("res://assets/ui/ranking_medals.png")

@onready var background: TextureRect = $Background
@onready var title_label: Label = $Center/Panel/Margin/VBox/TitleLabel
@onready var scores_list: VBoxContainer = $Center/Panel/Margin/VBox/ScoresList
@onready var again_button: Button = $Center/Panel/Margin/VBox/AgainButton
@onready var menu_button: Button = $Center/Panel/Margin/VBox/MenuButton


func _ready() -> void:
	if not OS.has_feature("web"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	background.texture = load("res://assets/background/background_map_1.png")
	title_label.text = "PLACAR - TOP 10"
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
		_show_message("Carregando placar...")
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
	_clear_scores()
	if scores.is_empty():
		_show_message("Nenhum recorde ainda.\nSeja o primeiro!")
		return
	_add_header()
	for i in range(scores.size()):
		var entry: Dictionary = scores[i]
		_add_score_row(i + 1, entry)


func _clear_scores() -> void:
	for child in scores_list.get_children():
		child.queue_free()


func _show_message(message: String) -> void:
	_clear_scores()
	var label := _make_label(message, 16, Color.WHITE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scores_list.add_child(label)


func _add_header() -> void:
	var row := HBoxContainer.new()
	row.add_child(_make_label("POS", 12, Color(0.68, 0.92, 0.4), 76.0))
	row.add_child(_make_label("NOME", 12, Color(0.68, 0.92, 0.4), 190.0))
	row.add_child(_make_label("PTS", 12, Color(0.68, 0.92, 0.4), 76.0))
	row.add_child(_make_label("TEMPO", 12, Color(0.68, 0.92, 0.4), 100.0))
	scores_list.add_child(row)


func _add_score_row(position: int, entry: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 38)
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	row.add_child(_make_position_cell(position))
	var name := str(entry.get("name", "???"))
	if name.length() > 16:
		name = name.substr(0, 15) + "."
	row.add_child(_make_label(name, 14, Color.WHITE, 190.0))
	row.add_child(_make_label(str(int(entry.get("score", 0))), 14, Color(1, 0.9, 0.35), 76.0))
	row.add_child(_make_label(_format_time(float(entry.get("time_ms", 0.0))), 14, Color.WHITE, 100.0))
	scores_list.add_child(row)


func _make_position_cell(position: int) -> Control:
	var cell := HBoxContainer.new()
	cell.custom_minimum_size = Vector2(76, 38)
	cell.alignment = BoxContainer.ALIGNMENT_BEGIN
	if position <= 3:
		var medal := TextureRect.new()
		medal.custom_minimum_size = Vector2(30, 30)
		medal.texture = _medal_texture(position - 1)
		medal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		medal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cell.add_child(medal)
	cell.add_child(_make_label(str(position), 14, Color.WHITE, 28.0))
	return cell


func _medal_texture(index: int) -> Texture2D:
	var atlas := AtlasTexture.new()
	atlas.atlas = MEDALS
	atlas.region = Rect2(index * 724, 0, 724, 724)
	var image := atlas.get_image()
	image.resize(30, 30, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(image)


func _make_label(text: String, font_size: int, color: Color, width: float = 0.0) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", PIXEL_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if width > 0.0:
		label.custom_minimum_size = Vector2(width, 0)
	return label


func _format_time(ms: float) -> String:
	var total_sec := int(ms / 1000.0)
	return "%02d:%02d" % [total_sec / 60, total_sec % 60]


func _on_again() -> void:
	GameState.ranking_mode = true
	get_tree().change_scene_to_file("res://scenes/loading_screen.tscn")


func _on_menu() -> void:
	GameState.ranking_mode = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
