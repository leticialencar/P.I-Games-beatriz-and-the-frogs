extends Node2D

const CATCH_DISTANCE := 90.0
const MAX_YELLOW := 1
const MAX_BLUE := 1
const MAX_GOLDEN := 1
const FREEZE_DURATION := 4.0

const YELLOW_SPAWN_MIN := 8.0
const YELLOW_SPAWN_MAX := 14.0
const BLUE_SPAWN_MIN := 12.0
const BLUE_SPAWN_MAX := 18.0
const GOLDEN_SPAWN_MIN := 16.0
const GOLDEN_SPAWN_MAX := 24.0

const FrogScene := preload("res://scenes/frog.tscn")
const PlayerScene := preload("res://scenes/player.tscn")

@onready var background: Sprite2D = $Background
@onready var entities: Node2D = $Entities
@onready var counter_label: Label = $HUD/CounterPanel/CounterLabel
@onready var goal_label: Label = $HUD/TimerPanel/TimerLabel
@onready var lives_label: Label = $HUD/LivesPanel/LivesLabel
@onready var map_label: Label = $HUD/MapLabel
@onready var boost_label: Label = $HUD/BoostLabel
@onready var prompt_label: Label = $HUD/PromptLabel
@onready var transition_label: Label = $HUD/TransitionLabel
@onready var music: AudioStreamPlayer = $Music

var player: Player
var frogs: Array[Frog] = []
var level: Dictionary = {}
var current_map := 1
var map_points := 0
var total_points := 0
var game_time_ms := 0.0
var spawn_timer := 0.0
var spawn_interval := 0.0
var yellow_spawn_timer := 0.0
var blue_spawn_timer := 0.0
var golden_spawn_timer := 0.0
var strange_respawn_timer := 0.0
var freeze_timer := 0.0
var transition_timer := 0.0
var finished := false


func _ready() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	GameState.reset()
	_spawn_player()
	_layout_hud()
	_start_map(1)
	boost_label.visible = false
	transition_label.visible = false
	music.play()
	get_viewport().size_changed.connect(_on_viewport_resized)


func _on_viewport_resized() -> void:
	_layout_hud()
	_setup_background(str(level.get("background", "res://assets/background/background.png")))


func _process(delta: float) -> void:
	if finished:
		return

	if transition_timer > 0.0:
		transition_timer -= delta
		transition_label.visible = transition_timer > 0.0
		return

	game_time_ms += delta * 1000.0
	_update_freeze(delta)
	_cleanup_expired_frogs()
	_update_spawn(delta)
	_update_bonus_spawns(delta)
	_update_strange_respawn(delta)
	_check_enemy_contact()
	_update_hud()
	_update_prompt()

	if map_points >= int(level["goal"]):
		_on_map_cleared()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11:
			_toggle_fullscreen()
			return

	if finished or transition_timer > 0.0:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E or event.keycode == KEY_SPACE:
			_try_catch_frog()


func _toggle_fullscreen() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _layout_hud() -> void:
	var screen := Screen.size()

	$HUD/CounterPanel.position = Vector2(16, 16)
	$HUD/LivesPanel.position = Vector2(screen.x * 0.5 - 70.0, 16)
	$HUD/TimerPanel.position = Vector2(screen.x - 156.0, 16)

	map_label.position = Vector2(screen.x * 0.5 - 150.0, screen.y - 48.0)
	map_label.size = Vector2(300, 30)

	boost_label.position = Vector2(screen.x * 0.5 - 150.0, 110)
	boost_label.size = Vector2(300, 30)

	transition_label.position = Vector2(screen.x * 0.5 - 300.0, screen.y * 0.5 - 60.0)
	transition_label.size = Vector2(600, 120)


func _setup_background(path: String = "res://assets/background/background.png") -> void:
	var texture := load(path) as Texture2D
	if texture == null:
		push_warning("Fundo não carregou: %s — usando fallback." % path)
		texture = load("res://assets/background/background.png") as Texture2D
	if texture == null:
		return

	var screen := Screen.size()
	background.texture = texture
	background.centered = false
	background.scale = Vector2(
		screen.x / float(texture.get_width()),
		screen.y / float(texture.get_height())
	)


func _spawn_player() -> void:
	player = PlayerScene.instantiate() as Player
	player.position = Vector2(120, 120)
	entities.add_child(player)
	player.died.connect(_on_player_died)


func _start_map(map_number: int) -> void:
	current_map = map_number
	GameState.current_map = map_number
	level = LevelData.get_config(map_number)
	map_points = 0
	Frog.difficulty_scale = float(level["difficulty"])
	_setup_background(str(level["background"]))
	_layout_hud()

	_clear_frogs()
	freeze_timer = 0.0

	spawn_interval = randf_range(0.3, 0.7)
	spawn_timer = 0.0
	yellow_spawn_timer = randf_range(4.0, 7.0)
	blue_spawn_timer = randf_range(9.0, 12.0)
	golden_spawn_timer = randf_range(14.0, 18.0)
	strange_respawn_timer = randf_range(
		float(level["strange_respawn_min"]),
		float(level["strange_respawn_max"])
	)

	player.global_position = Vector2(120, 120)
	_spawn_initial_frogs()
	_update_hud()


func _clear_frogs() -> void:
	for frog in frogs:
		if is_instance_valid(frog):
			frog.queue_free()
	frogs.clear()


func _spawn_initial_frogs() -> void:
	var screen := Screen.size()
	var greens := [
		Vector2(screen.x * 0.18, screen.y * 0.28),
		Vector2(screen.x * 0.42, screen.y * 0.38),
		Vector2(screen.x * 0.68, screen.y * 0.26),
		Vector2(screen.x * 0.30, screen.y * 0.68),
		Vector2(screen.x * 0.58, screen.y * 0.62),
	]
	for pos in greens:
		_add_frog(pos, Frog.FrogType.GREEN)

	_add_frog(Vector2(screen.x * 0.80, screen.y * 0.70), Frog.FrogType.STRANGE)
	if int(level["max_strange"]) >= 2:
		_add_frog(Vector2(screen.x * 0.52, screen.y * 0.16), Frog.FrogType.STRANGE)
	if int(level["max_strange"]) >= 3:
		_add_frog(Vector2(screen.x * 0.86, screen.y * 0.42), Frog.FrogType.STRANGE)


func _add_frog(pos: Vector2, frog_type: Frog.FrogType) -> void:
	var frog := FrogScene.instantiate() as Frog
	frog.position = pos
	frog.setup(frog_type, player)
	if freeze_timer > 0.0:
		frog.set_frozen(true)
	entities.add_child(frog)
	frogs.append(frog)


func _count_type(type: Frog.FrogType) -> int:
	var total := 0
	for frog in frogs:
		if frog.frog_type == type:
			total += 1
	return total


func _cleanup_expired_frogs() -> void:
	var remaining: Array[Frog] = []
	for frog in frogs:
		if frog.expired:
			frog.queue_free()
		else:
			remaining.append(frog)
	frogs = remaining


func _apply_freeze() -> void:
	freeze_timer = FREEZE_DURATION
	for frog in frogs:
		frog.set_frozen(true)


func _update_freeze(delta: float) -> void:
	if freeze_timer <= 0.0:
		return

	freeze_timer -= delta
	if freeze_timer <= 0.0:
		freeze_timer = 0.0
		for frog in frogs:
			frog.set_frozen(false)


func _try_catch_frog() -> void:
	for frog in frogs:
		if not frog.is_catchable():
			continue

		var distance: float = player.get_center().distance_to(frog.get_center())
		if distance < CATCH_DISTANCE:
			var points := frog.get_score_value()
			var was_yellow := frog.is_yellow()
			var was_blue := frog.is_blue()

			frogs.erase(frog)
			frog.queue_free()
			map_points += points
			total_points += points

			if was_yellow:
				player.apply_speed_boost()
			elif was_blue:
				_apply_freeze()

			spawn_timer = 0.0
			spawn_interval = randf_range(0.3, 0.7)
			break


func _check_enemy_contact() -> void:
	for frog in frogs:
		if not frog.is_enemy() or frog.frozen:
			continue

		var distance: float = player.get_center().distance_to(frog.get_center())
		if distance < Frog.CONTACT_RADIUS:
			player.take_damage()
			break


func _update_spawn(delta: float) -> void:
	spawn_timer += delta
	var min_frogs := int(level["min_frogs"])
	var max_frogs := int(level["max_frogs"])
	if frogs.size() <= min_frogs and spawn_timer >= spawn_interval and frogs.size() < max_frogs:
		var new_pos := _find_spawn_position()
		if new_pos != Vector2.INF:
			_add_frog(new_pos, Frog.FrogType.GREEN)
			spawn_timer = 0.0
			spawn_interval = randf_range(0.3, 0.7)


func _update_strange_respawn(delta: float) -> void:
	var max_strange := int(level["max_strange"])
	var strange_count := _count_type(Frog.FrogType.STRANGE)
	if strange_count >= max_strange:
		strange_respawn_timer = randf_range(
			float(level["strange_respawn_min"]),
			float(level["strange_respawn_max"])
		)
		return

	strange_respawn_timer -= delta
	if strange_respawn_timer > 0.0:
		return

	strange_respawn_timer = randf_range(
		float(level["strange_respawn_min"]),
		float(level["strange_respawn_max"])
	)
	if frogs.size() >= int(level["max_frogs"]):
		return

	var new_pos := _find_spawn_position()
	if new_pos != Vector2.INF:
		_add_frog(new_pos, Frog.FrogType.STRANGE)


func _update_bonus_spawns(delta: float) -> void:
	yellow_spawn_timer -= delta
	blue_spawn_timer -= delta
	golden_spawn_timer -= delta

	if bool(level["allow_yellow"]) and yellow_spawn_timer <= 0.0:
		yellow_spawn_timer = randf_range(YELLOW_SPAWN_MIN, YELLOW_SPAWN_MAX)
		_try_spawn_bonus(Frog.FrogType.YELLOW, MAX_YELLOW)

	if bool(level["allow_blue"]) and blue_spawn_timer <= 0.0:
		blue_spawn_timer = randf_range(BLUE_SPAWN_MIN, BLUE_SPAWN_MAX)
		_try_spawn_bonus(Frog.FrogType.BLUE, MAX_BLUE)

	if bool(level["allow_golden"]) and golden_spawn_timer <= 0.0:
		golden_spawn_timer = randf_range(GOLDEN_SPAWN_MIN, GOLDEN_SPAWN_MAX)
		_try_spawn_bonus(Frog.FrogType.GOLDEN, MAX_GOLDEN)


func _try_spawn_bonus(type: Frog.FrogType, max_count: int) -> void:
	if _count_type(type) >= max_count or frogs.size() >= int(level["max_frogs"]):
		return
	var new_pos := _find_spawn_position()
	if new_pos != Vector2.INF:
		_add_frog(new_pos, type)


func _find_spawn_position() -> Vector2:
	var screen := Screen.size()
	var min_x := 60
	var max_x := maxi(80, int(screen.x - 120.0))
	var min_y := 60
	var max_y := maxi(80, int(screen.y - 140.0))

	for _i in range(100):
		var pos := Vector2(randi_range(min_x, max_x), randi_range(min_y, max_y))
		if player.global_position.distance_to(pos) < 160.0:
			continue

		var valid := true
		for frog in frogs:
			if frog.global_position.distance_to(pos) < 110.0:
				valid = false
				break

		if valid:
			return pos

	return Vector2.INF


func _update_hud() -> void:
	var goal := int(level["goal"])
	counter_label.text = str(total_points)
	goal_label.text = "%d/%d" % [map_points, goal]
	lives_label.text = "Vidas: %d" % player.lives
	map_label.text = str(level["name"])

	if map_points >= goal:
		goal_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	else:
		goal_label.add_theme_color_override("font_color", Color.WHITE)

	if freeze_timer > 0.0:
		boost_label.visible = true
		boost_label.text = "Congelado! %.0fs" % ceilf(freeze_timer)
		boost_label.add_theme_color_override("font_color", Color(0.45, 0.8, 1.0))
	elif player.has_speed_boost():
		boost_label.visible = true
		boost_label.text = "Velocidade! %.0fs" % ceilf(player.speed_boost_timer)
		boost_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.25))
	else:
		boost_label.visible = false


func _update_prompt() -> void:
	prompt_label.visible = false
	for frog in frogs:
		var distance: float = player.get_center().distance_to(frog.get_center())
		if distance >= CATCH_DISTANCE:
			continue

		prompt_label.visible = true
		prompt_label.global_position = frog.global_position + Vector2(-20, -24)
		if frog.is_enemy():
			if frog.frozen:
				prompt_label.text = "Pegar! E"
				prompt_label.add_theme_color_override("font_color", Color(0.45, 0.8, 1.0))
			else:
				prompt_label.text = "Perigo!"
				prompt_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
		elif frog.is_yellow():
			prompt_label.text = "Velocidade! E"
			prompt_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
		elif frog.is_blue():
			prompt_label.text = "Congelar! E"
			prompt_label.add_theme_color_override("font_color", Color(0.45, 0.8, 1.0))
		elif frog.is_golden():
			prompt_label.text = "Raro x3! E"
			prompt_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.1))
		else:
			prompt_label.text = "Pressione E"
			prompt_label.add_theme_color_override("font_color", Color.WHITE)
		break


func _on_map_cleared() -> void:
	GameState.maps_cleared = current_map

	if current_map >= LevelData.max_maps():
		_finish_game(true)
		return

	transition_timer = 2.0
	transition_label.text = "Mapa 2!\nOs sapinhos estão mais ágeis..."
	transition_label.visible = true
	_start_map(current_map + 1)


func _on_player_died() -> void:
	_finish_game(false)


func _finish_game(survived: bool) -> void:
	if finished:
		return
	finished = true

	GameState.frogs_caught = total_points
	GameState.game_time_ms = game_time_ms
	GameState.lives_left = player.lives
	GameState.survived = survived
	GameState.current_map = current_map
	music.stop()
	get_tree().change_scene_to_file("res://scenes/end_game.tscn")
