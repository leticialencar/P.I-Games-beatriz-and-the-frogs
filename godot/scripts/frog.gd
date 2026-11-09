class_name Frog
extends Node2D

## Tipos do GDD (+ Lasombra no mapa 3).
enum FrogType { GREEN, YELLOW, BLUE, GOLDEN, STRANGE, BOSS }

## Os sapos comuns usam folhas 1080x720; Lasombra usa uma folha 1536x1024.
const SCALE := 0.31
const BOSS_SCALE := 0.52
const BOSS_CONTACT_RADIUS := 78.0
const BOSS_CHASE_SPEED := 95.0
const BOSS_VISION := 9999.0
const WALK_FRAME_DURATION := 0.15
const ACTION_FRAME_DURATION := 0.15
const IDLE_FRAME_DURATIONS := [2.0, 0.5, 0.8, 1.2]

const FROZEN_TINT := Color(0.55, 0.85, 1.2, 1.0)

const VISION_RADIUS := 150.0
const CONTACT_RADIUS := 48.0
const PATROL_SPEED := 55.0
const CHASE_SPEED := 110.0

const GREEN_DETECT_RADIUS := 115.0
const GREEN_PATROL_SPEED := 75.0
const GREEN_FLEE_SPEED := 175.0
const GREEN_HOP_TIME := 0.38
const GREEN_PAUSE_MIN := 0.45
const GREEN_PAUSE_MAX := 1.1

const YELLOW_DETECT_RADIUS := 130.0
const YELLOW_PATROL_SPEED := 120.0
const YELLOW_FLEE_SPEED := 220.0
const YELLOW_LIFETIME := 12.0

const BLUE_DETECT_RADIUS := 100.0
const BLUE_PATROL_SPEED := 40.0
const BLUE_FLEE_SPEED := 70.0
const BLUE_LIFETIME := 14.0

const GOLDEN_DETECT_RADIUS := 150.0
const GOLDEN_PATROL_SPEED := 180.0
const GOLDEN_FLEE_SPEED := 260.0
const GOLDEN_LIFETIME := 5.0
const GOLDEN_DIR_CHANGE := 0.25
const OBSTACLE_LOOKAHEAD := 18.0
const BOSS_OBSTACLE_LOOKAHEAD := 30.0
const OBSTACLE_CLEARANCE := 10.0

## Escala de dificuldade do mapa atual (1.0 = mapa 1).
static var difficulty_scale := 1.0

@onready var sprite: Sprite2D = $Sprite2D

var frog_type: FrogType = FrogType.GREEN
var player: Player = null
var base_modulate := Color.WHITE
var frozen := false

var idle_textures: Array[Texture2D] = []
var walk_textures: Array[Texture2D] = []
var action_textures: Array[Texture2D] = []

var idle_frame := 0
var walk_frame := 0
var action_frame := 0
var animation_timer := 0.0

var move_dir := Vector2.RIGHT
var moving := false
var action_playing := false
var chasing := false
var fleeing := false

var state_timer := 0.0
var state_duration := 0.0
var action_timer := 0.0
var speed := PATROL_SPEED
var lifetime := -1.0
var expired := false
var golden_dir_timer := 0.0
var avoidance_side := 1.0
var boss_hp := 12
var boss_max_hp := 12
var hit_flash := 0.0
signal boss_defeated


func setup(type: FrogType, player_ref: Player) -> void:
	frog_type = type
	player = player_ref
	avoidance_side = -1.0 if randf() < 0.5 else 1.0
	match frog_type:
		FrogType.STRANGE:
			base_modulate = Color.WHITE
			speed = PATROL_SPEED
			lifetime = -1.0
		FrogType.YELLOW:
			base_modulate = Color.WHITE
			speed = YELLOW_PATROL_SPEED
			lifetime = YELLOW_LIFETIME
		FrogType.BLUE:
			base_modulate = Color.WHITE
			speed = BLUE_PATROL_SPEED
			lifetime = BLUE_LIFETIME
		FrogType.GOLDEN:
			base_modulate = Color.WHITE
			speed = GOLDEN_PATROL_SPEED
			lifetime = GOLDEN_LIFETIME
		FrogType.BOSS:
			base_modulate = Color.WHITE
			speed = BOSS_CHASE_SPEED
			lifetime = -1.0
		_:
			base_modulate = Color.WHITE
			speed = GREEN_PATROL_SPEED
			lifetime = -1.0
	modulate = base_modulate


func setup_boss(player_ref: Player, hp: int) -> void:
	setup(FrogType.BOSS, player_ref)
	boss_hp = hp
	boss_max_hp = hp


func is_catchable() -> bool:
	if frog_type == FrogType.BOSS:
		return false
	if frog_type == FrogType.STRANGE:
		return frozen
	return frog_type in [FrogType.GREEN, FrogType.YELLOW, FrogType.BLUE, FrogType.GOLDEN]


func is_enemy() -> bool:
	return frog_type == FrogType.STRANGE or frog_type == FrogType.BOSS


func is_boss() -> bool:
	return frog_type == FrogType.BOSS


func is_yellow() -> bool:
	return frog_type == FrogType.YELLOW


func is_blue() -> bool:
	return frog_type == FrogType.BLUE


func is_golden() -> bool:
	return frog_type == FrogType.GOLDEN


func get_score_value() -> int:
	match frog_type:
		FrogType.GOLDEN:
			return 5
		FrogType.YELLOW, FrogType.BLUE:
			return 2
		FrogType.STRANGE:
			return 3
		_:
			return 1


func set_frozen(value: bool) -> void:
	frozen = value
	if frozen:
		modulate = FROZEN_TINT
		moving = false
		chasing = false
		fleeing = false
		action_playing = false
	else:
		modulate = base_modulate


func get_center() -> Vector2:
	return global_position


func _ready() -> void:
	_load_sprites()
	if frog_type == FrogType.BOSS:
		_apply_boss_look()
	move_dir = _random_dir()
	state_duration = randf_range(GREEN_PAUSE_MIN, GREEN_PAUSE_MAX)
	action_timer = randf_range(4.0, 8.0)
	if idle_textures.size() > 0:
		sprite.texture = idle_textures[0]


func _process(delta: float) -> void:
	if lifetime > 0.0:
		lifetime -= delta
		if lifetime <= 0.0:
			expired = true
			return

	if frozen:
		_advance_idle(delta)
		if idle_textures.size() > 0:
			sprite.texture = idle_textures[idle_frame]
		return

	if frog_type == FrogType.BOSS:
		_process_boss(delta)
	elif frog_type == FrogType.STRANGE:
		_process_strange(delta)
	elif frog_type == FrogType.GOLDEN:
		_process_golden(delta)
	else:
		_process_fleeing_frog(delta)


func _process_boss(delta: float) -> void:
	if hit_flash > 0.0:
		hit_flash -= delta
		modulate = Color(1.5, 0.35, 0.35, 1.0) if hit_flash > 0.0 else base_modulate

	chasing = false
	if player != null and is_instance_valid(player):
		var to_player: Vector2 = player.get_center() - get_center()
		var distance: float = to_player.length()
		if distance > 0.1:
			chasing = true
			move_dir = to_player.normalized()
			speed = BOSS_CHASE_SPEED * difficulty_scale
			moving = true

	if moving:
		_try_move(speed * delta)
		_advance_walk(delta)
		if walk_textures.size() > 0:
			sprite.texture = walk_textures[walk_frame]
		sprite.flip_h = move_dir.x < 0.0


func take_hit(damage: int = 1) -> bool:
	if frog_type != FrogType.BOSS or expired:
		return false
	boss_hp = maxi(0, boss_hp - damage)
	hit_flash = 0.12
	if boss_hp <= 0:
		expired = true
		boss_defeated.emit()
		return true
	return false


func _apply_boss_look() -> void:
	var sheet := load("res://assets/frog/lasombra_frog_spritesheet.png") as Texture2D
	if sheet == null:
		push_warning("Spritesheet do Lasombra não carregou.")
		return

	idle_textures.clear()
	walk_textures.clear()
	action_textures.clear()

	for column in range(4):
		idle_textures.append(_slice_boss_cleaned(
			sheet, Rect2(column * 384, 0, 384, 341), BOSS_SCALE
		))
	var walk_rects := [
		Rect2(0, 330, 300, 340),
		Rect2(270, 330, 280, 340),
		Rect2(540, 330, 260, 340),
		Rect2(790, 330, 260, 340),
		Rect2(1035, 330, 270, 340),
		Rect2(1285, 330, 251, 340),
	]
	for region in walk_rects:
		walk_textures.append(_slice_boss_cleaned(sheet, region, BOSS_SCALE))
	for column in range(4):
		action_textures.append(_slice_boss_cleaned(
			sheet, Rect2(column * 384, 682, 384, 342), BOSS_SCALE
		))

	sprite.texture = idle_textures[0]
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _process_strange(delta: float) -> void:
	chasing = false
	if player != null and is_instance_valid(player):
		var to_player: Vector2 = player.get_center() - get_center()
		var distance: float = to_player.length()
		if distance <= VISION_RADIUS * difficulty_scale and distance > 0.1:
			chasing = true
			move_dir = to_player.normalized()
			speed = CHASE_SPEED * difficulty_scale
			moving = true

	if not chasing:
		state_timer += delta
		if state_timer >= state_duration:
			state_timer = 0.0
			moving = not moving
			state_duration = randf_range(1.0, 2.5)
			if moving:
				move_dir = _random_dir()
				walk_frame = 0
			else:
				idle_frame = 0
		speed = PATROL_SPEED

	if moving:
		_try_move(speed * delta)
		_advance_walk(delta)
		sprite.texture = walk_textures[walk_frame]
		sprite.flip_h = move_dir.x < 0.0
	else:
		_advance_idle(delta)
		sprite.texture = idle_textures[idle_frame]
		sprite.flip_h = false


func _process_golden(delta: float) -> void:
	# Movimento errático e muito rápido (GDD).
	fleeing = false
	golden_dir_timer -= delta

	if player != null and is_instance_valid(player):
		var away: Vector2 = get_center() - player.get_center()
		var distance: float = away.length()
		if distance <= GOLDEN_DETECT_RADIUS * difficulty_scale and distance > 0.1:
			fleeing = true
			move_dir = away.normalized()
			speed = GOLDEN_FLEE_SPEED * difficulty_scale

	if not fleeing and golden_dir_timer <= 0.0:
		golden_dir_timer = GOLDEN_DIR_CHANGE
		move_dir = _random_dir()
		speed = GOLDEN_PATROL_SPEED

	moving = true
	_try_move(speed * delta)
	_advance_walk(delta)
	sprite.texture = walk_textures[walk_frame]
	sprite.flip_h = move_dir.x < 0.0


func _process_fleeing_frog(delta: float) -> void:
	var detect_radius := GREEN_DETECT_RADIUS * difficulty_scale
	var patrol_speed := GREEN_PATROL_SPEED
	var flee_speed := GREEN_FLEE_SPEED * difficulty_scale

	match frog_type:
		FrogType.YELLOW:
			detect_radius = YELLOW_DETECT_RADIUS * difficulty_scale
			patrol_speed = YELLOW_PATROL_SPEED
			flee_speed = YELLOW_FLEE_SPEED * difficulty_scale
		FrogType.BLUE:
			detect_radius = BLUE_DETECT_RADIUS * difficulty_scale
			patrol_speed = BLUE_PATROL_SPEED
			flee_speed = BLUE_FLEE_SPEED * difficulty_scale
		_:
			pass

	fleeing = false

	if player != null and is_instance_valid(player):
		var away: Vector2 = get_center() - player.get_center()
		var distance: float = away.length()
		if distance <= detect_radius and distance > 0.1:
			fleeing = true
			var flee_dir: Vector2 = away.normalized()
			var side: Vector2 = Vector2(-flee_dir.y, flee_dir.x) * randf_range(-0.35, 0.35)
			move_dir = (flee_dir + side).normalized()
			speed = flee_speed
			moving = true
			action_playing = false

	if fleeing:
		_try_move(speed * delta)
		_advance_walk(delta)
		sprite.texture = walk_textures[walk_frame]
		sprite.flip_h = move_dir.x < 0.0
		return

	if action_playing:
		_update_action(delta)
		return

	action_timer -= delta
	if action_timer <= 0.0 and not moving:
		action_playing = true
		action_frame = 0
		animation_timer = 0.0
		return

	state_timer += delta
	if state_timer >= state_duration:
		state_timer = 0.0
		moving = not moving
		if moving:
			move_dir = _random_dir()
			speed = patrol_speed
			state_duration = GREEN_HOP_TIME
			walk_frame = 0
		else:
			idle_frame = 0
			state_duration = randf_range(GREEN_PAUSE_MIN, GREEN_PAUSE_MAX)

	if moving:
		_try_move(speed * delta)
		_advance_walk(delta)
		sprite.texture = walk_textures[walk_frame]
		sprite.flip_h = move_dir.x < 0.0
	else:
		_advance_idle(delta)
		sprite.texture = idle_textures[idle_frame]
		sprite.flip_h = false


func _random_dir() -> Vector2:
	var dir := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
	if dir.length_squared() < 0.01:
		return Vector2.RIGHT
	return dir.normalized()


func _try_move(distance: float) -> void:
	var lookahead := BOSS_OBSTACLE_LOOKAHEAD if frog_type == FrogType.BOSS else OBSTACLE_LOOKAHEAD
	lookahead = maxf(lookahead, distance)
	if _collides_with_obstacle(_body_rect_at(position + move_dir * lookahead)):
		if not _choose_detour_direction(lookahead):
			return

	var next := position + move_dir * distance
	if _collides_with_obstacle(_body_rect_at(next)):
		return
	position = next
	_clamp_to_screen()


func _choose_detour_direction(lookahead: float) -> bool:
	# Mantém um lado preferido para não oscilar na frente do mesmo obstáculo.
	var angles := [25.0, 45.0, 70.0, 90.0, 120.0, 150.0, 180.0]
	for angle in angles:
		for side in [avoidance_side, -avoidance_side]:
			var candidate := move_dir.rotated(deg_to_rad(angle * side)).normalized()
			var candidate_pos := position + candidate * lookahead
			if not _collides_with_obstacle(_body_rect_at(candidate_pos)):
				move_dir = candidate
				avoidance_side = side
				return true
	avoidance_side *= -1.0
	return false


func _body_rect_at(pos: Vector2) -> Rect2:
	# Área estável nos pés; não varia com o tamanho de cada quadro da animação.
	var size := Vector2(104, 72) if frog_type == FrogType.BOSS else Vector2(38, 30)
	return Rect2(pos - size * 0.5, size)


func _collides_with_obstacle(rect: Rect2) -> bool:
	if not is_inside_tree():
		return false
	for node in get_tree().get_nodes_in_group("obstacles"):
		if node.has_method("get_blocking_rect"):
			var obstacle_rect: Rect2 = node.get_blocking_rect().grow(OBSTACLE_CLEARANCE)
			if rect.intersects(obstacle_rect):
				return true
	return false


func _clamp_to_screen() -> void:
	var pad := 90.0 if frog_type == FrogType.BOSS else 70.0
	var max_x: float = Screen.width() - pad
	var max_y: float = Screen.height() - (110.0 if frog_type == FrogType.BOSS else 90.0)
	position.x = clampf(position.x, 0.0, max_x)
	position.y = clampf(position.y, 0.0, max_y)
	if position.x <= 0.0 or position.x >= max_x:
		move_dir.x *= -1.0
	if position.y <= 0.0 or position.y >= max_y:
		move_dir.y *= -1.0


func _advance_walk(delta: float) -> void:
	animation_timer += delta
	if animation_timer >= WALK_FRAME_DURATION:
		animation_timer = 0.0
		walk_frame = (walk_frame + 1) % walk_textures.size()


func _advance_idle(delta: float) -> void:
	animation_timer += delta
	if animation_timer >= IDLE_FRAME_DURATIONS[idle_frame]:
		animation_timer = 0.0
		idle_frame = (idle_frame + 1) % idle_textures.size()


func _update_action(delta: float) -> void:
	animation_timer += delta
	if animation_timer >= ACTION_FRAME_DURATION:
		animation_timer = 0.0
		action_frame += 1
		if action_frame >= action_textures.size():
			action_frame = 0
			action_playing = false
			action_timer = randf_range(4.0, 8.0)
			return

	sprite.texture = action_textures[action_frame]
	sprite.flip_h = false


func _load_sprites() -> void:
	if frog_type == FrogType.BOSS:
		return

	var sheet_path := "res://assets/frog/pink_frog_spritesheet.png"
	match frog_type:
		FrogType.YELLOW:
			sheet_path = "res://assets/frog/yellow_frog_spritesheet.png"
		FrogType.BLUE:
			sheet_path = "res://assets/frog/blue_frog_spritesheet.png"
		FrogType.GOLDEN:
			sheet_path = "res://assets/frog/purple_frog_spritesheet.png"
		FrogType.STRANGE:
			sheet_path = "res://assets/frog/red_frog_spritesheet.png"

	var sheet := load(sheet_path) as Texture2D
	if sheet == null:
		push_warning("Spritesheet do sapo não carregou: %s" % sheet_path)
		return

	var idle_rects := [
		Rect2(122, 86, 141, 143),
		Rect2(352, 86, 142, 142),
		Rect2(579, 86, 141, 142),
		Rect2(815, 85, 141, 146),
	]
	var walk_rects := [
		Rect2(46, 298, 139, 124),
		Rect2(217, 298, 143, 122),
		Rect2(385, 298, 143, 124),
		Rect2(564, 302, 138, 120),
		Rect2(736, 301, 141, 122),
		Rect2(901, 301, 145, 119),
	]
	var action_rects := [
		Rect2(122, 543, 146, 114),
		Rect2(347, 494, 168, 149),
		Rect2(564, 480, 150, 149),
		Rect2(811, 549, 141, 112),
	]

	for rect in idle_rects:
		idle_textures.append(_slice_scaled(sheet, rect))
	for rect in walk_rects:
		walk_textures.append(_slice_scaled(sheet, rect))
	for rect in action_rects:
		action_textures.append(_slice_scaled(sheet, rect))


func _slice_scaled(sheet: Texture2D, region: Rect2, scale_factor: float = SCALE) -> Texture2D:
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = region

	var image := atlas.get_image()
	var width := maxi(1, int(image.get_width() * scale_factor))
	var height := maxi(1, int(image.get_height() * scale_factor))
	image.resize(width, height, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(image)


func _slice_boss_cleaned(sheet: Texture2D, region: Rect2, scale_factor: float) -> Texture2D:
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = region
	var image := atlas.get_image()
	_keep_largest_alpha_component(image)
	var used_rect := image.get_used_rect()
	if used_rect.size.x > 0 and used_rect.size.y > 0:
		image = image.get_region(used_rect)
	var width := maxi(1, int(image.get_width() * scale_factor))
	var height := maxi(1, int(image.get_height() * scale_factor))
	image.resize(width, height, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(image)


func _keep_largest_alpha_component(image: Image) -> void:
	var width := image.get_width()
	var height := image.get_height()
	var visited := PackedByteArray()
	visited.resize(width * height)
	var largest := PackedInt32Array()
	var neighbors := [
		Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
		Vector2i(-1, 0), Vector2i(1, 0),
		Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
	]

	for y in range(height):
		for x in range(width):
			var start := y * width + x
			if visited[start] != 0:
				continue
			visited[start] = 1
			if image.get_pixel(x, y).a <= 0.01:
				continue

			var component := PackedInt32Array([start])
			var queue := PackedInt32Array([start])
			var head := 0
			while head < queue.size():
				var current := queue[head]
				head += 1
				var current_x := current % width
				var current_y := current / width
				for offset in neighbors:
					var next_x: int = current_x + offset.x
					var next_y: int = current_y + offset.y
					if next_x < 0 or next_x >= width or next_y < 0 or next_y >= height:
						continue
					var next := next_y * width + next_x
					if visited[next] != 0:
						continue
					visited[next] = 1
					if image.get_pixel(next_x, next_y).a > 0.01:
						queue.append(next)
						component.append(next)
			if component.size() > largest.size():
				largest = component

	var keep := PackedByteArray()
	keep.resize(width * height)
	for index in largest:
		keep[index] = 1
	for y in range(height):
		for x in range(width):
			if keep[y * width + x] == 0:
				image.set_pixel(x, y, Color.TRANSPARENT)
