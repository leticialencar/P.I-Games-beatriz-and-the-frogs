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
const ObstacleScene := preload("res://scenes/obstacle.tscn")
const BulletScript := preload("res://scripts/bullet.gd")

@onready var background: Sprite2D = $Background
@onready var entities: Node2D = $Entities
@onready var obstacles_root: Node2D = $Obstacles
@onready var counter_label: Label = $HUD/CounterPanel/CounterLabel
@onready var goal_label: Label = $HUD/TimerPanel/TimerLabel
@onready var lives_label: Label = $HUD/LivesPanel/LivesLabel
@onready var map_label: Label = $HUD/MapLabel
@onready var boost_label: Label = $HUD/BoostLabel
@onready var prompt_label: Label = $HUD/PromptLabel
@onready var transition_label: Label = $HUD/TransitionLabel
@onready var music: AudioStreamPlayer = $Music
@onready var map_loading: CanvasLayer = $MapLoading
@onready var map_load_label: Label = $MapLoading/Center/LoadLabel
@onready var map_bar_fill: ColorRect = $MapLoading/Center/BarBorder/BarFill

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
var bullets: Array = []
var boss_frog: Frog = null
var boss_cleared := false
var map_loading_active := false


func _ready() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	GameState.reset()
	_spawn_player()
	_layout_hud()
	_start_map(1)
	boost_label.visible = false
	transition_label.visible = false
	map_loading.visible = false
	music.play()
	get_viewport().size_changed.connect(_on_viewport_resized)


func _on_viewport_resized() -> void:
	_layout_hud()
	_setup_background(str(level.get("background", "res://assets/background/background.png")))


func _process(delta: float) -> void:
	if finished:
		return

	if map_loading_active:
		return

	if transition_timer > 0.0:
		transition_timer -= delta
		transition_label.visible = transition_timer > 0.0
		return

	game_time_ms += delta * 1000.0
	_update_freeze(delta)
	_cleanup_expired_frogs()
	_update_bullets(delta)
	if not bool(level.get("boss_map", false)):
		_update_spawn(delta)
		_update_bonus_spawns(delta)
		_update_strange_respawn(delta)
	else:
		# Só respawn dos vermelhos — sem sapinhos pegáveis.
		_update_strange_respawn(delta)
	_check_enemy_contact()
	_update_hud()
	_update_prompt()

	if bool(level.get("boss_map", false)):
		if boss_cleared:
			_on_map_cleared()
	elif map_points >= int(level["goal"]):
		_on_map_cleared()


func can_pause() -> bool:
	return not finished and transition_timer <= 0.0 and not map_loading_active


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11:
			_toggle_fullscreen()
			return

	if finished or transition_timer > 0.0 or map_loading_active:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if bool(level.get("boss_map", false)):
			_try_shoot()
		else:
			_try_catch_frog()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F or event.keycode == KEY_J:
			_try_shoot()
			return
		if event.keycode == KEY_E or event.keycode == KEY_SPACE:
			if bool(level.get("boss_map", false)):
				_try_shoot()
			else:
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
	boss_cleared = false
	boss_frog = null
	_clear_bullets()
	Frog.difficulty_scale = float(level["difficulty"])
	_setup_background(str(level["background"]))
	_layout_hud()

	_clear_frogs()
	_spawn_obstacles()
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
	player.has_gun = bool(level.get("boss_map", false))
	_spawn_initial_frogs()
	_update_hud()


func _clear_frogs() -> void:
	for frog in frogs:
		if is_instance_valid(frog):
			frog.queue_free()
	frogs.clear()


func _clear_obstacles() -> void:
	for child in obstacles_root.get_children():
		child.queue_free()


func _spawn_obstacles() -> void:
	_clear_obstacles()
	var rects := LevelData.obstacle_rects_for(current_map, Screen.size())
	for rect in rects:
		var obstacle := ObstacleScene.instantiate() as Obstacle
		obstacles_root.add_child(obstacle)
		obstacle.setup(rect)
		obstacle.add_to_group("obstacles")


func _spawn_initial_frogs() -> void:
	var screen := Screen.size()

	if bool(level.get("boss_map", false)):
		var boss := FrogScene.instantiate() as Frog
		boss.position = Vector2(screen.x * 0.62, screen.y * 0.38)
		boss.setup_boss(player, int(level.get("boss_hp", 12)))
		if freeze_timer > 0.0:
			boss.set_frozen(true)
		entities.add_child(boss)
		frogs.append(boss)
		boss_frog = boss
		# Só vermelhos pra atormentar — zero sapinhos pra pegar.
		var strange_spots := [
			Vector2(screen.x * 0.22, screen.y * 0.55),
			Vector2(screen.x * 0.78, screen.y * 0.68),
			Vector2(screen.x * 0.50, screen.y * 0.22),
		]
		var strange_needed := int(level["max_strange"])
		for i in range(mini(strange_needed, strange_spots.size())):
			_add_frog(strange_spots[i], Frog.FrogType.STRANGE)
		return

	var greens := [
		Vector2(screen.x * 0.18, screen.y * 0.28),
		Vector2(screen.x * 0.42, screen.y * 0.38),
		Vector2(screen.x * 0.68, screen.y * 0.26),
		Vector2(screen.x * 0.30, screen.y * 0.68),
		Vector2(screen.x * 0.58, screen.y * 0.62),
	]
	for pos in greens:
		if _hits_obstacle(Rect2(pos, Vector2(50, 40))):
			pos = _find_spawn_position()
			if pos == Vector2.INF:
				continue
		_add_frog(pos, Frog.FrogType.GREEN)

	var strange_spots := [
		Vector2(screen.x * 0.80, screen.y * 0.70),
		Vector2(screen.x * 0.52, screen.y * 0.16),
		Vector2(screen.x * 0.86, screen.y * 0.42),
	]
	var strange_needed := int(level["max_strange"])
	for i in range(mini(strange_needed, strange_spots.size())):
		var pos: Vector2 = strange_spots[i]
		if _hits_obstacle(Rect2(pos, Vector2(50, 40))):
			pos = _find_spawn_position()
			if pos == Vector2.INF:
				continue
		_add_frog(pos, Frog.FrogType.STRANGE)


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

		var radius := Frog.BOSS_CONTACT_RADIUS if frog.is_boss() else Frog.CONTACT_RADIUS
		var distance: float = player.get_center().distance_to(frog.get_center())
		if distance < radius:
			player.take_damage()
			break


func _try_shoot() -> void:
	if player == null or not player.can_shoot():
		return
	player.mark_shot()
	var bullet := Node2D.new()
	bullet.set_script(BulletScript)
	entities.add_child(bullet)
	bullet.setup(player.get_center(), player.get_aim_direction())
	bullets.append(bullet)


func _clear_bullets() -> void:
	for b in bullets:
		if is_instance_valid(b):
			b.queue_free()
	bullets.clear()


func _update_bullets(_delta: float) -> void:
	var alive: Array = []
	for b in bullets:
		if not is_instance_valid(b) or b.spent:
			continue
		var hit := false
		for frog in frogs:
			if not frog.is_boss() or frog.expired:
				continue
			if b.global_position.distance_to(frog.get_center()) <= Bullet.HIT_RADIUS + 40.0:
				frog.take_hit(1)
				b.spent = true
				b.queue_free()
				hit = true
				if frog.expired:
					boss_cleared = true
					total_points += 10
					map_points = 1
				break
		if not hit:
			alive.append(b)
	bullets = alive


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
		if _hits_obstacle(Rect2(pos, Vector2(50, 40))):
			continue

		var valid := true
		for frog in frogs:
			if frog.global_position.distance_to(pos) < 110.0:
				valid = false
				break

		if valid:
			return pos

	return Vector2.INF


func _hits_obstacle(rect: Rect2) -> bool:
	for node in get_tree().get_nodes_in_group("obstacles"):
		if node.has_method("get_blocking_rect") and rect.intersects(node.get_blocking_rect()):
			return true
	return false


func _update_hud() -> void:
	counter_label.text = str(total_points)
	lives_label.text = "Vidas: %d" % player.lives
	map_label.text = str(level["name"])

	if bool(level.get("boss_map", false)):
		if boss_frog != null and is_instance_valid(boss_frog) and not boss_frog.expired:
			goal_label.text = "HP %d/%d" % [boss_frog.boss_hp, boss_frog.boss_max_hp]
			goal_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
			boost_label.visible = true
			boost_label.text = "Atirar: F / clique  |  Sem pegar!"
			boost_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		else:
			goal_label.text = "DERROTADO!"
			goal_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
		return

	var goal := int(level["goal"])
	goal_label.text = "%d/%d" % [map_points, goal]
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
	if bool(level.get("boss_map", false)) and boss_frog != null and is_instance_valid(boss_frog) and not boss_frog.expired:
		var dist: float = player.get_center().distance_to(boss_frog.get_center())
		if dist < 160.0:
			prompt_label.visible = true
			prompt_label.global_position = boss_frog.global_position + Vector2(-30, -40)
			prompt_label.text = "Atire! F"
			prompt_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
			return

	for frog in frogs:
		var distance: float = player.get_center().distance_to(frog.get_center())
		if distance >= CATCH_DISTANCE:
			continue
		if frog.is_boss():
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
	if finished or transition_timer > 0.0 or map_loading_active:
		return

	GameState.maps_cleared = current_map

	if current_map >= LevelData.max_maps():
		_go_to_friends()
		return

	var next_map := current_map + 1
	var title := "Carregando Mapa 2..."
	var blurb := "Os sapinhos estão mais ágeis..."
	if current_map == 2:
		title = "Carregando Mapa 3..."
		blurb = "O Sapão Preto apareceu...\nBea pegou uma arma!"
	_load_next_map(next_map, title, blurb)


func _set_map_load_progress(ratio: float) -> void:
	var width := floorf((412.0 * clampf(ratio, 0.0, 1.0)) / 4.0) * 4.0
	map_bar_fill.size = Vector2(width, 20.0)


func _load_next_map(next_map: int, title: String, blurb: String) -> void:
	map_loading_active = true
	map_loading.visible = true
	map_load_label.text = "%s\n%s" % [title, blurb]
	_set_map_load_progress(0.0)
	prompt_label.visible = false
	transition_label.visible = false

	# Mostra a barra e só depois monta o mapa (hitch fica “escondido”).
	for i in range(8):
		_set_map_load_progress(float(i) / 12.0)
		await get_tree().process_frame

	_start_map(next_map)

	for i in range(8, 13):
		_set_map_load_progress(float(i) / 12.0)
		await get_tree().process_frame
		await get_tree().create_timer(0.05).timeout

	_set_map_load_progress(1.0)
	await get_tree().create_timer(0.15).timeout
	map_loading.visible = false
	map_loading_active = false


func _go_to_friends() -> void:
	if finished:
		return
	finished = true
	GameState.frogs_caught = total_points
	GameState.game_time_ms = game_time_ms
	GameState.lives_left = player.lives
	GameState.survived = true
	GameState.current_map = current_map

	map_loading_active = true
	map_loading.visible = true
	map_load_label.text = "Indo para a festa..."
	_set_map_load_progress(0.2)
	await get_tree().process_frame
	_set_map_load_progress(0.7)
	await get_tree().create_timer(0.35).timeout
	_set_map_load_progress(1.0)
	await get_tree().create_timer(0.15).timeout

	music.stop()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/friends_scene.tscn")


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
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/end_game.tscn")
