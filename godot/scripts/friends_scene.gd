extends Node2D

## Mapa 3 — festa pacífica. Andar, conversar; bingo só na lore.

const PlayerScene := preload("res://scenes/player.tscn")
const PauseMenuScene := preload("res://scenes/pause_menu.tscn")
const INTERACT_DISTANCE := 100.0

@onready var background: Sprite2D = $Background
@onready var decor: Node2D = $Decor
@onready var entities: Node2D = $Entities
@onready var prompt_label: Label = $HUD/PromptLabel
@onready var hint_label: Label = $HUD/HintLabel
@onready var map_label: Label = $HUD/MapLabel
@onready var leave_button: Button = $HUD/LeaveButton

var player: Player
var friends: Array[Dictionary] = []
var dialogue_timer := 0.0


func _ready() -> void:
	if not OS.has_feature("web"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	GameState.current_map = 3
	GameState.maps_cleared = maxi(GameState.maps_cleared, 2)

	_setup_background()
	_spawn_party_decor()
	_spawn_player()
	_spawn_friends()
	_spawn_border_obstacles()
	_layout_hud()
	leave_button.pressed.connect(_leave_party)

	var pause_layer := CanvasLayer.new()
	pause_layer.layer = 100
	pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(pause_layer)
	pause_layer.add_child(PauseMenuScene.instantiate())

	get_viewport().size_changed.connect(_on_viewport_resized)


func can_pause() -> bool:
	return true


func _on_viewport_resized() -> void:
	_setup_background()
	_layout_hud()


func _setup_background() -> void:
	background.texture = load("res://assets/background/background_map3.png")
	background.centered = false
	background.position = Vector2.ZERO
	var screen := Screen.size()
	var tex := background.texture
	if tex:
		background.scale = Vector2(screen.x / tex.get_width(), screen.y / tex.get_height())


func _spawn_player() -> void:
	player = PlayerScene.instantiate() as Player
	entities.add_child(player)
	var screen := Screen.size()
	player.position = Vector2(screen.x * 0.22 - 56.0, screen.y * 0.70)


func _spawn_party_decor() -> void:
	var screen := Screen.size()
	var props := [
		{"tex": "res://assets/party/prop_balloons.png", "pos": Vector2(0.16, 0.22), "scale": 1.0},
		{"tex": "res://assets/party/prop_balloons.png", "pos": Vector2(0.84, 0.24), "scale": 0.9},
		{"tex": "res://assets/party/prop_balloons.png", "pos": Vector2(0.72, 0.70), "scale": 0.75},
		{"tex": "res://assets/party/prop_popcorn.png", "pos": Vector2(0.18, 0.62), "scale": 1.05, "block": true},
		{"tex": "res://assets/party/prop_popcorn.png", "pos": Vector2(0.82, 0.58), "scale": 0.95, "block": true},
		{"tex": "res://assets/party/prop_party_flags.png", "pos": Vector2(0.50, 0.18), "scale": 1.2},
		{"tex": "res://assets/party/prop_party_flags.png", "pos": Vector2(0.34, 0.72), "scale": 0.85},
	]
	for prop in props:
		var sprite := Sprite2D.new()
		sprite.texture = load(prop["tex"])
		sprite.centered = true
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var p: Vector2 = prop["pos"]
		sprite.position = Vector2(screen.x * p.x, screen.y * p.y)
		sprite.scale = Vector2.ONE * float(prop["scale"])
		decor.add_child(sprite)

		if prop.get("block", false) and sprite.texture:
			var body := StaticBody2D.new()
			body.collision_layer = 1
			body.collision_mask = 0
			body.position = sprite.position + Vector2(0, 28)
			var shape := CollisionShape2D.new()
			var rect_shape := RectangleShape2D.new()
			rect_shape.size = Vector2(54, 28)
			shape.shape = rect_shape
			body.add_child(shape)
			add_child(body)


func _friend_specs(screen: Vector2) -> Array[Dictionary]:
	## 7 amigos + Bea = turma de 8. Bingo só aparece na conversa (lore).
	return [
		{
			"name": "Luiz",
			"texture": "res://assets/friends/friend_luiz.png",
			"pos": Vector2(screen.x * 0.28, screen.y * 0.36),
			"lines": [
				"Luiz: Bea! O cabelo tá no grau hoje!",
				"Luiz: Depois a gente marca aquele bingo lendário.",
			],
		},
		{
			"name": "Gabriel",
			"texture": "res://assets/friends/friend_gabriel.png",
			"pos": Vector2(screen.x * 0.40, screen.y * 0.32),
			"lines": [
				"Gabriel: Olha a tattoo nova!",
				"Gabriel: Pegou quantos sapinhos no caminho?",
			],
		},
		{
			"name": "Letícia",
			"texture": "res://assets/friends/friend_leticia.png",
			"pos": Vector2(screen.x * 0.52, screen.y * 0.31),
			"lines": [
				"Letícia: Chegou! A festa tava te esperando.",
				"Letícia: Conta tudo da caçada!",
			],
		},
		{
			"name": "Lucas",
			"texture": "res://assets/friends/friend_lucas.png",
			"pos": Vector2(screen.x * 0.64, screen.y * 0.34),
			"lines": [
				"Lucas: Saí do trampo de dev só pra isso.",
				"Lucas: Blazer no calor, mas valeu a pena.",
			],
		},
		{
			"name": "Igor",
			"texture": "res://assets/friends/friend_igor.png",
			"pos": Vector2(screen.x * 0.34, screen.y * 0.48),
			"lines": [
				"Igor: Pipoca tá boa. Quer um pouco?",
				"Igor: Ainda falamos de bingo… um dia!",
			],
		},
		{
			"name": "Caio",
			"texture": "res://assets/friends/friend_caio.png",
			"pos": Vector2(screen.x * 0.50, screen.y * 0.52),
			"lines": [
				"Caio: De short, de óculos e de festa!",
				"Caio: Cuidado com os balões, hein.",
			],
		},
		{
			"name": "Brenda",
			"texture": "res://assets/friends/friend_brenda.png",
			"pos": Vector2(screen.x * 0.66, screen.y * 0.48),
			"lines": [
				"Brenda: Esse cabelo e essa festa? Imbatível.",
				"Brenda: Fica mais um pouco, Bea!",
			],
		},
	]


func _spawn_friends() -> void:
	var screen := Screen.size()
	for spec in _friend_specs(screen):
		var root := Node2D.new()
		root.position = spec["pos"]
		entities.add_child(root)

		var sprite := Sprite2D.new()
		sprite.texture = load(spec["texture"])
		sprite.centered = true
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		root.add_child(sprite)

		var label := Label.new()
		label.text = str(spec["name"])
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_color_override("font_outline_color", Color(0.15, 0.2, 0.1, 1))
		label.add_theme_constant_override("outline_size", 4)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.position = Vector2(-50, -85)
		label.size = Vector2(100, 22)
		root.add_child(label)

		friends.append({
			"node": root,
			"lines": spec["lines"],
			"line_index": 0,
		})


func _spawn_border_obstacles() -> void:
	var screen := Screen.size()
	var rects: Array[Rect2] = [
		Rect2(screen.x * 0.10, screen.y * 0.08, screen.x * 0.80, screen.y * 0.035),
		Rect2(screen.x * 0.10, screen.y * 0.90, screen.x * 0.80, screen.y * 0.035),
		Rect2(screen.x * 0.05, screen.y * 0.10, screen.x * 0.035, screen.y * 0.80),
		Rect2(screen.x * 0.915, screen.y * 0.10, screen.x * 0.035, screen.y * 0.80),
	]
	for rect in rects:
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		body.position = rect.position + rect.size * 0.5
		var shape := CollisionShape2D.new()
		var rect_shape := RectangleShape2D.new()
		rect_shape.size = rect.size
		shape.shape = rect_shape
		body.add_child(shape)
		add_child(body)


func _layout_hud() -> void:
	var screen := Screen.size()
	map_label.position = Vector2(screen.x * 0.5 - 220.0, 18.0)
	map_label.size = Vector2(440, 36)
	hint_label.position = Vector2(screen.x * 0.5 - 320.0, screen.y - 88.0)
	hint_label.size = Vector2(640, 40)
	leave_button.position = Vector2(screen.x - 200.0, 16.0)
	leave_button.size = Vector2(180, 40)
	prompt_label.visible = false


func _process(delta: float) -> void:
	if player == null:
		return
	if dialogue_timer > 0.0:
		dialogue_timer -= delta
	_clamp_player()
	_update_prompt()


func _clamp_player() -> void:
	var screen := Screen.size()
	player.position.x = clampf(player.position.x, 50.0, screen.x - 130.0)
	player.position.y = clampf(player.position.y, 70.0, screen.y - 150.0)


func _nearest_friend_index() -> int:
	var best_i := -1
	var best_dist := INF
	var center := player.get_center()
	for i in range(friends.size()):
		var node: Node2D = friends[i]["node"]
		var distance: float = center.distance_to(node.global_position)
		if distance < best_dist:
			best_dist = distance
			best_i = i
	if best_i >= 0 and best_dist <= INTERACT_DISTANCE:
		return best_i
	return -1


func _update_prompt() -> void:
	var i := _nearest_friend_index()
	if i < 0:
		prompt_label.visible = false
		return
	prompt_label.visible = true
	prompt_label.text = "Conversar (E)"
	var node: Node2D = friends[i]["node"]
	prompt_label.global_position = node.global_position + Vector2(-70, -105)
	prompt_label.size = Vector2(160, 28)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11:
			_toggle_fullscreen()
			return
		if event.keycode == KEY_E or event.keycode == KEY_SPACE:
			_try_talk()


func _try_talk() -> void:
	var i := _nearest_friend_index()
	if i < 0:
		return
	var friend: Dictionary = friends[i]
	var lines: Array = friend["lines"]
	var idx: int = int(friend["line_index"])
	hint_label.text = str(lines[idx])
	friend["line_index"] = (idx + 1) % lines.size()
	friends[i] = friend
	dialogue_timer = 4.0


func _leave_party() -> void:
	GameState.survived = true
	GameState.party_visited = true
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/end_game.tscn")


func _toggle_fullscreen() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
