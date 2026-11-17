extends Control

@onready var background: TextureRect = $Background
@onready var title_label: Label = $Center/Panel/Margin/VBox/TitleLabel
@onready var score_label: Label = $Center/Panel/Margin/VBox/ScoreLabel
@onready var name_input: LineEdit = $Center/Panel/Margin/VBox/NameInput
@onready var hint_label: Label = $Center/Panel/Margin/VBox/HintLabel
@onready var confirm_button: Button = $Center/Panel/Margin/VBox/ConfirmButton


func _ready() -> void:
	background.texture = load("res://assets/background/background_map_1.png")
	title_label.text = "NOVO RECORDE!"
	score_label.text = "Pontos: %d\nTempo: %s" % [GameState.ranking_score, _format_time(GameState.game_time_ms)]
	hint_label.text = "Digite seu nome para o placar"
	confirm_button.pressed.connect(_confirm)
	name_input.text_submitted.connect(func(_text: String): _confirm())
	name_input.gui_input.connect(_on_name_input_gui_input)
	name_input.grab_focus()


func _confirm() -> void:
	var player_name := name_input.text.strip_edges()
	if player_name.is_empty():
		if GameState.is_mobile_survival():
			_open_mobile_name_prompt()
			player_name = name_input.text.strip_edges()
			if not player_name.is_empty():
				_confirm()
			return
		hint_label.text = "Digite um nome para continuar"
		return
	confirm_button.disabled = true
	name_input.editable = false
	hint_label.text = "Salvando pontuacao..."
	if not OS.has_feature("web"):
		GameState.submit_highscore(player_name, GameState.ranking_score, GameState.game_time_ms)
		_go_to_board()
		return
	var request := HTTPRequest.new()
	add_child(request)
	request.request_completed.connect(func(_result, _code, _headers, _body): _go_to_board())
	var payload := JSON.stringify({"name": player_name, "score": GameState.ranking_score, "time_ms": GameState.game_time_ms})
	var error := request.request(GameState.api_url("/api/scores"), ["Content-Type: application/json"], HTTPClient.METHOD_POST, payload)
	if error != OK:
		_go_to_board()


func _go_to_board() -> void:
	get_tree().change_scene_to_file("res://scenes/leaderboard.tscn")


func _on_name_input_gui_input(event: InputEvent) -> void:
	if not GameState.is_mobile_survival():
		return
	if event is InputEventScreenTouch and event.pressed:
		_open_mobile_name_prompt()
	elif event is InputEventMouseButton and event.pressed:
		_open_mobile_name_prompt()


func _open_mobile_name_prompt() -> void:
	if not OS.has_feature("web"):
		return
	var entered_name := str(JavaScriptBridge.eval("window.prompt('Digite seu nome para o placar:', '')", true))
	if entered_name != "null":
		name_input.text = entered_name.strip_edges().substr(0, 32)


func _format_time(ms: float) -> String:
	var total_sec := int(ms / 1000.0)
	return "%02d:%02d" % [total_sec / 60, total_sec % 60]
