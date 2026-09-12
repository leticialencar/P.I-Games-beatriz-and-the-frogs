class_name Frog
extends Node2D

## Tipos do GDD.
enum FrogType { GREEN, YELLOW, BLUE, GOLDEN, STRANGE }

## Escala confortável (o 0.36 ficou gigante no mapa atual).
const SCALE := 0.22
const WALK_FRAME_DURATION := 0.15
const ACTION_FRAME_DURATION := 0.15
const IDLE_FRAME_DURATIONS := [2.0, 0.5, 0.8, 1.2]

const STRANGE_TINT := Color(0.9, 0.2, 0.35, 1.0)
const YELLOW_TINT := Color(1.15, 0.95, 0.25, 1.0)
const BLUE_TINT := Color(0.35, 0.7, 1.15, 1.0)
const GOLDEN_TINT := Color(1.2, 0.85, 0.15, 1.0)
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


func setup(type: FrogType, player_ref: Player) -> void:
	frog_type = type
	player = player_ref
	match frog_type:
		FrogType.STRANGE:
			base_modulate = STRANGE_TINT
			speed = PATROL_SPEED
			lifetime = -1.0
		FrogType.YELLOW:
			base_modulate = YELLOW_TINT
			speed = YELLOW_PATROL_SPEED
			lifetime = YELLOW_LIFETIME
		FrogType.BLUE:
			base_modulate = BLUE_TINT
			speed = BLUE_PATROL_SPEED
			lifetime = BLUE_LIFETIME
		FrogType.GOLDEN:
			base_modulate = GOLDEN_TINT
			speed = GOLDEN_PATROL_SPEED
			lifetime = GOLDEN_LIFETIME
		_:
			base_modulate = Color.WHITE
			speed = GREEN_PATROL_SPEED
			lifetime = -1.0
	modulate = base_modulate


func is_catchable() -> bool:
	if frog_type == FrogType.STRANGE:
		return frozen
	return frog_type in [FrogType.GREEN, FrogType.YELLOW, FrogType.BLUE, FrogType.GOLDEN]


func is_enemy() -> bool:
	return frog_type == FrogType.STRANGE


func is_yellow() -> bool:
	return frog_type == FrogType.YELLOW


func is_blue() -> bool:
	return frog_type == FrogType.BLUE


func is_golden() -> bool:
	return frog_type == FrogType.GOLDEN


func get_score_value() -> int:
	return 3 if frog_type == FrogType.GOLDEN else 1


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
	if sprite == null or sprite.texture == null:
		return global_position
	return global_position + sprite.texture.get_size() * 0.5


func _ready() -> void:
	_load_sprites()
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

	if frog_type == FrogType.STRANGE:
		_process_strange(delta)
	elif frog_type == FrogType.GOLDEN:
		_process_golden(delta)
	else:
		_process_fleeing_frog(delta)


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
	var next := position + move_dir * distance
	var body := _body_rect_at(next)
	if _collides_with_obstacle(body):
		# Tenta desviar: inverte e escolhe outro ângulo.
		move_dir = -move_dir
		next = position + move_dir * distance * 0.5
		if _collides_with_obstacle(_body_rect_at(next)):
			move_dir = _random_dir()
			return
	position = next
	_clamp_to_screen()


func _body_rect_at(pos: Vector2) -> Rect2:
	var size := Vector2(40, 32)
	if sprite != null and sprite.texture != null:
		size = sprite.texture.get_size() * 0.7
	return Rect2(pos + size * 0.15, size)


func _collides_with_obstacle(rect: Rect2) -> bool:
	if not is_inside_tree():
		return false
	for node in get_tree().get_nodes_in_group("obstacles"):
		if node.has_method("get_blocking_rect") and rect.intersects(node.get_blocking_rect()):
			return true
	return false


func _clamp_to_screen() -> void:
	var max_x: float = Screen.width() - 70.0
	var max_y: float = Screen.height() - 90.0
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
	var sheet := load("res://assets/frog/frog_spritesheet.png") as Texture2D

	var idle_rects := [
		Rect2(174, 123, 201, 203),
		Rect2(500, 123, 202, 202),
		Rect2(824, 123, 200, 202),
		Rect2(1159, 121, 200, 208),
	]
	var walk_rects := [
		Rect2(65, 424, 198, 176),
		Rect2(308, 424, 204, 173),
		Rect2(547, 424, 204, 176),
		Rect2(802, 429, 196, 171),
		Rect2(1046, 428, 200, 173),
		Rect2(1281, 428, 206, 169),
	]
	var action_rects := [
		Rect2(174, 773, 207, 162),
		Rect2(494, 702, 239, 212),
		Rect2(802, 682, 214, 212),
		Rect2(1153, 781, 200, 159),
	]

	for rect in idle_rects:
		idle_textures.append(_slice_scaled(sheet, rect))
	for rect in walk_rects:
		walk_textures.append(_slice_scaled(sheet, rect))
	for rect in action_rects:
		action_textures.append(_slice_scaled(sheet, rect))


func _slice_scaled(sheet: Texture2D, region: Rect2) -> Texture2D:
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = region

	var image := atlas.get_image()
	var width := maxi(1, int(image.get_width() * SCALE))
	var height := maxi(1, int(image.get_height() * SCALE))
	image.resize(width, height, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(image)
