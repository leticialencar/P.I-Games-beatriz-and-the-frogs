class_name Frog
extends Node2D

## Tipos do GDD — etapa atual: Verde (foge) e Estranho (persegue).
enum FrogType { GREEN, STRANGE }

const SCALE := 0.18
const WALK_FRAME_DURATION := 0.15
const ACTION_FRAME_DURATION := 0.15
const IDLE_FRAME_DURATIONS := [2.0, 0.5, 0.8, 1.2]

const STRANGE_TINT := Color(0.9, 0.2, 0.35, 1.0)
const VISION_RADIUS := 150.0
const CONTACT_RADIUS := 42.0
const PATROL_SPEED := 55.0
const CHASE_SPEED := 110.0

## Mapa 1: raio de fuga pequeno/médio (GDD).
const GREEN_DETECT_RADIUS := 115.0
const GREEN_PATROL_SPEED := 75.0
const GREEN_FLEE_SPEED := 175.0
const GREEN_HOP_TIME := 0.38
const GREEN_PAUSE_MIN := 0.45
const GREEN_PAUSE_MAX := 1.1
const GREEN_FLEE_HOP_TIME := 0.28

@onready var sprite: Sprite2D = $Sprite2D

var frog_type: FrogType = FrogType.GREEN
var player: Player = null

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


func setup(type: FrogType, player_ref: Player) -> void:
	frog_type = type
	player = player_ref
	if frog_type == FrogType.STRANGE:
		modulate = STRANGE_TINT
		speed = PATROL_SPEED
	else:
		modulate = Color.WHITE
		speed = GREEN_PATROL_SPEED


func is_catchable() -> bool:
	return frog_type == FrogType.GREEN


func is_enemy() -> bool:
	return frog_type == FrogType.STRANGE


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
	if frog_type == FrogType.STRANGE:
		_process_strange(delta)
	else:
		_process_green(delta)


func _process_strange(delta: float) -> void:
	chasing = false
	if player != null and is_instance_valid(player):
		var to_player: Vector2 = player.get_center() - get_center()
		var distance: float = to_player.length()
		if distance <= VISION_RADIUS and distance > 0.1:
			chasing = true
			move_dir = to_player.normalized()
			speed = CHASE_SPEED
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
		position += move_dir * speed * delta
		_clamp_to_screen()
		_advance_walk(delta)
		sprite.texture = walk_textures[walk_frame]
		sprite.flip_h = move_dir.x < 0.0
	else:
		_advance_idle(delta)
		sprite.texture = idle_textures[idle_frame]
		sprite.flip_h = false


func _process_green(delta: float) -> void:
	fleeing = false

	if player != null and is_instance_valid(player):
		var away: Vector2 = get_center() - player.get_center()
		var distance: float = away.length()
		if distance <= GREEN_DETECT_RADIUS and distance > 0.1:
			fleeing = true
			# Vetor oposto à Bea + leve variação para não travar em linha reta.
			var flee_dir: Vector2 = away.normalized()
			var side: Vector2 = Vector2(-flee_dir.y, flee_dir.x) * randf_range(-0.35, 0.35)
			move_dir = (flee_dir + side).normalized()
			speed = GREEN_FLEE_SPEED
			moving = true
			action_playing = false

	if fleeing:
		position += move_dir * speed * delta
		_clamp_to_screen()
		_advance_walk(delta)
		sprite.texture = walk_textures[walk_frame]
		sprite.flip_h = move_dir.x < 0.0
		return

	# Longe da Bea: saltos aleatórios com pausas (GDD).
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
			speed = GREEN_PATROL_SPEED
			state_duration = GREEN_HOP_TIME
			walk_frame = 0
		else:
			idle_frame = 0
			state_duration = randf_range(GREEN_PAUSE_MIN, GREEN_PAUSE_MAX)

	if moving:
		position += move_dir * speed * delta
		_clamp_to_screen()
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


func _clamp_to_screen() -> void:
	position.x = clampf(position.x, 0.0, 760.0)
	position.y = clampf(position.y, 0.0, 520.0)
	if position.x <= 0.0 or position.x >= 760.0:
		move_dir.x *= -1.0
	if position.y <= 0.0 or position.y >= 520.0:
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
