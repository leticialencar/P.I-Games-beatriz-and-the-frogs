extends Node2D

const GAME_DURATION_MS := 60000.0
const MIN_FROGS := 3
const MAX_FROGS := 8
const CATCH_DISTANCE := 80.0
const MAX_STRANGE := 2

const FrogScene := preload("res://scenes/frog.tscn")
const PlayerScene := preload("res://scenes/player.tscn")

@onready var background: Sprite2D = $Background
@onready var entities: Node2D = $Entities
@onready var counter_label: Label = $HUD/CounterPanel/CounterLabel
@onready var timer_label: Label = $HUD/TimerPanel/TimerLabel
@onready var lives_label: Label = $HUD/LivesPanel/LivesLabel
@onready var prompt_label: Label = $HUD/PromptLabel
@onready var music: AudioStreamPlayer = $Music

var player: Player
var frogs: Array[Frog] = []
var frogs_caught := 0
var game_time_ms := 0.0
var spawn_timer := 0.0
var spawn_interval := 0.0
var finished := false


func _ready() -> void:
	GameState.reset()
	_setup_background()
	_spawn_player()
	_spawn_initial_frogs()
	spawn_interval = randf_range(0.3, 0.7)
	music.play()


func _process(delta: float) -> void:
	if finished:
		return

	game_time_ms += delta * 1000.0
	_update_spawn(delta)
	_check_enemy_contact()
	_update_hud()
	_update_prompt()

	if game_time_ms >= GAME_DURATION_MS:
		_finish_game(true)


func _unhandled_input(event: InputEvent) -> void:
	if finished:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E or event.keycode == KEY_SPACE:
			_try_catch_frog()


func _setup_background() -> void:
	var texture := load("res://assets/background/background.png") as Texture2D
	background.texture = texture
	background.centered = false
	background.scale = Vector2(
		800.0 / texture.get_width(),
		600.0 / texture.get_height()
	)


func _spawn_player() -> void:
	player = PlayerScene.instantiate() as Player
	player.position = Vector2(100, 100)
	entities.add_child(player)
	player.died.connect(_on_player_died)


func _spawn_initial_frogs() -> void:
	var greens := [
		Vector2(150, 180),
		Vector2(350, 250),
		Vector2(550, 180),
		Vector2(250, 450),
	]
	for pos in greens:
		_add_frog(pos, Frog.FrogType.GREEN)

	# Poucos sapos estranhos no mapa 1 (GDD).
	_add_frog(Vector2(650, 450), Frog.FrogType.STRANGE)
	_add_frog(Vector2(400, 120), Frog.FrogType.STRANGE)


func _add_frog(pos: Vector2, frog_type: Frog.FrogType) -> void:
	var frog := FrogScene.instantiate() as Frog
	frog.position = pos
	frog.setup(frog_type, player)
	entities.add_child(frog)
	frogs.append(frog)


func _count_strange() -> int:
	var total := 0
	for frog in frogs:
		if frog.is_enemy():
			total += 1
	return total


func _try_catch_frog() -> void:
	for frog in frogs:
		if not frog.is_catchable():
			continue

		var distance: float = player.get_center().distance_to(frog.get_center())
		if distance < CATCH_DISTANCE:
			frogs.erase(frog)
			frog.queue_free()
			frogs_caught += 1
			spawn_timer = 0.0
			spawn_interval = randf_range(0.3, 0.7)
			break


func _check_enemy_contact() -> void:
	for frog in frogs:
		if not frog.is_enemy():
			continue

		var distance: float = player.get_center().distance_to(frog.get_center())
		if distance < Frog.CONTACT_RADIUS:
			player.take_damage()
			break


func _update_spawn(delta: float) -> void:
	spawn_timer += delta
	if frogs.size() <= MIN_FROGS and spawn_timer >= spawn_interval and frogs.size() < MAX_FROGS:
		var new_pos := _find_spawn_position()
		if new_pos != Vector2.INF:
			var type := Frog.FrogType.GREEN
			if _count_strange() < MAX_STRANGE and randf() < 0.2:
				type = Frog.FrogType.STRANGE
			_add_frog(new_pos, type)
			spawn_timer = 0.0
			spawn_interval = randf_range(0.3, 0.7)


func _find_spawn_position() -> Vector2:
	for _i in range(100):
		var pos := Vector2(randi_range(50, 700), randi_range(50, 480))
		if player.global_position.distance_to(pos) < 150.0:
			continue

		var valid := true
		for frog in frogs:
			if frog.global_position.distance_to(pos) < 100.0:
				valid = false
				break

		if valid:
			return pos

	return Vector2.INF


func _update_hud() -> void:
	counter_label.text = str(frogs_caught)
	lives_label.text = "Vidas: %d" % player.lives

	var remaining := maxf(0.0, GAME_DURATION_MS - game_time_ms)
	var total_seconds := int(remaining / 1000.0)
	var minutes := total_seconds / 60
	var seconds := total_seconds % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]

	if remaining <= 10000.0:
		timer_label.add_theme_color_override("font_color", Color(0.745, 0.216, 0.216))
	else:
		timer_label.add_theme_color_override("font_color", Color.WHITE)


func _update_prompt() -> void:
	prompt_label.visible = false
	for frog in frogs:
		var distance: float = player.get_center().distance_to(frog.get_center())
		if distance >= CATCH_DISTANCE:
			continue

		prompt_label.visible = true
		prompt_label.global_position = frog.global_position + Vector2(-20, -24)
		if frog.is_enemy():
			prompt_label.text = "Perigo!"
			prompt_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
		else:
			prompt_label.text = "Pressione E"
			prompt_label.add_theme_color_override("font_color", Color.WHITE)
		break


func _on_player_died() -> void:
	_finish_game(false)


func _finish_game(survived: bool) -> void:
	if finished:
		return
	finished = true

	GameState.frogs_caught = frogs_caught
	GameState.game_time_ms = game_time_ms
	GameState.lives_left = player.lives
	GameState.survived = survived
	music.stop()
	get_tree().change_scene_to_file("res://scenes/end_game.tscn")
