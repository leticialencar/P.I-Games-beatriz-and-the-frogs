extends Node2D

const GAME_DURATION_MS := 60000.0
const MIN_FROGS := 3
const MAX_FROGS := 8
const CATCH_DISTANCE := 80.0
const MAX_STRANGE := 2
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
## Se limpar os vermelhos, voltam depois deste intervalo.
const STRANGE_RESPAWN_MIN := 6.0
const STRANGE_RESPAWN_MAX := 10.0

const FrogScene := preload("res://scenes/frog.tscn")
const PlayerScene := preload("res://scenes/player.tscn")

@onready var background: Sprite2D = $Background
@onready var entities: Node2D = $Entities
@onready var counter_label: Label = $HUD/CounterPanel/CounterLabel
@onready var timer_label: Label = $HUD/TimerPanel/TimerLabel
@onready var lives_label: Label = $HUD/LivesPanel/LivesLabel
@onready var boost_label: Label = $HUD/BoostLabel
@onready var prompt_label: Label = $HUD/PromptLabel
@onready var music: AudioStreamPlayer = $Music

var player: Player
var frogs: Array[Frog] = []
var frogs_caught := 0
var game_time_ms := 0.0
var spawn_timer := 0.0
var spawn_interval := 0.0
var yellow_spawn_timer := 0.0
var blue_spawn_timer := 0.0
var golden_spawn_timer := 0.0
var strange_respawn_timer := 0.0
var freeze_timer := 0.0
var finished := false


func _ready() -> void:
	GameState.reset()
	_setup_background()
	_spawn_player()
	_spawn_initial_frogs()
	spawn_interval = randf_range(0.3, 0.7)
	yellow_spawn_timer = randf_range(4.0, 7.0)
	blue_spawn_timer = randf_range(9.0, 12.0)
	golden_spawn_timer = randf_range(14.0, 18.0)
	strange_respawn_timer = randf_range(STRANGE_RESPAWN_MIN, STRANGE_RESPAWN_MAX)
	boost_label.visible = false
	music.play()


func _process(delta: float) -> void:
	if finished:
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

	_add_frog(Vector2(650, 450), Frog.FrogType.STRANGE)
	_add_frog(Vector2(400, 120), Frog.FrogType.STRANGE)


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
			frogs_caught += points

			if was_yellow:
				player.apply_speed_boost()
			elif was_blue:
				_apply_freeze()

			spawn_timer = 0.0
			spawn_interval = randf_range(0.3, 0.7)
			break


func _check_enemy_contact() -> void:
	# Congelados não causam dano.
	for frog in frogs:
		if not frog.is_enemy() or frog.frozen:
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
			# Spawn comum só repõe verdes; vermelhos têm timer próprio.
			_add_frog(new_pos, Frog.FrogType.GREEN)
			spawn_timer = 0.0
			spawn_interval = randf_range(0.3, 0.7)


func _update_strange_respawn(delta: float) -> void:
	var strange_count := _count_type(Frog.FrogType.STRANGE)
	if strange_count >= MAX_STRANGE:
		strange_respawn_timer = randf_range(STRANGE_RESPAWN_MIN, STRANGE_RESPAWN_MAX)
		return

	strange_respawn_timer -= delta
	if strange_respawn_timer > 0.0:
		return

	strange_respawn_timer = randf_range(STRANGE_RESPAWN_MIN, STRANGE_RESPAWN_MAX)
	if frogs.size() >= MAX_FROGS:
		return

	var new_pos := _find_spawn_position()
	if new_pos != Vector2.INF:
		_add_frog(new_pos, Frog.FrogType.STRANGE)


func _update_bonus_spawns(delta: float) -> void:
	yellow_spawn_timer -= delta
	blue_spawn_timer -= delta
	golden_spawn_timer -= delta

	if yellow_spawn_timer <= 0.0:
		yellow_spawn_timer = randf_range(YELLOW_SPAWN_MIN, YELLOW_SPAWN_MAX)
		_try_spawn_bonus(Frog.FrogType.YELLOW, MAX_YELLOW)

	if blue_spawn_timer <= 0.0:
		blue_spawn_timer = randf_range(BLUE_SPAWN_MIN, BLUE_SPAWN_MAX)
		_try_spawn_bonus(Frog.FrogType.BLUE, MAX_BLUE)

	if golden_spawn_timer <= 0.0:
		golden_spawn_timer = randf_range(GOLDEN_SPAWN_MIN, GOLDEN_SPAWN_MAX)
		_try_spawn_bonus(Frog.FrogType.GOLDEN, MAX_GOLDEN)


func _try_spawn_bonus(type: Frog.FrogType, max_count: int) -> void:
	if _count_type(type) >= max_count or frogs.size() >= MAX_FROGS:
		return
	var new_pos := _find_spawn_position()
	if new_pos != Vector2.INF:
		_add_frog(new_pos, type)


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
