class_name Player
extends CharacterBody2D

signal died

const BASE_SPEED := 280.0
const FRAME_SIZE := Vector2(200, 218)
## Tamanho confortável pro viewport 1280x720 (sem exagerar).
const DISPLAY_SIZE := Vector2(112, 122)
const FRAME_DURATION := 0.15
const MAX_LIVES := 3
const INVULN_DURATION := 1.5
const SPEED_BOOST_MULT := 1.5
const SPEED_BOOST_DURATION := 5.0

@onready var sprite: Sprite2D = $Sprite2D

var direction := "front"
var facing_right := true
var moving := false
var speed_multiplier := 1.0
var speed_boost_timer := 0.0

var lives := MAX_LIVES
var invulnerable := false
var invuln_timer := 0.0
var flash_timer := 0.0
var has_gun := false
var shoot_cooldown := 0.0
const SHOOT_COOLDOWN := 0.28

var current_frame := 0
var animation_timer := 0.0

var idle_front: Array[Texture2D] = []
var walk_front: Array[Texture2D] = []
var idle_side: Array[Texture2D] = []
var walk_side: Array[Texture2D] = []
var idle_back: Array[Texture2D] = []
var walk_back: Array[Texture2D] = []


func _ready() -> void:
	_load_sprites()
	sprite.texture = idle_front[0]


func _physics_process(delta: float) -> void:
	_update_speed_boost(delta)
	_update_invulnerability(delta)
	if shoot_cooldown > 0.0:
		shoot_cooldown -= delta
	_handle_movement()
	_update_animation(delta)
	_update_sprite()


func get_aim_direction() -> Vector2:
	match direction:
		"side":
			return Vector2.RIGHT if facing_right else Vector2.LEFT
		"back":
			return Vector2.UP
		_:
			return Vector2.DOWN


func can_shoot() -> bool:
	return has_gun and shoot_cooldown <= 0.0


func mark_shot() -> void:
	shoot_cooldown = SHOOT_COOLDOWN


func get_center() -> Vector2:
	return global_position + DISPLAY_SIZE * 0.5


func has_speed_boost() -> bool:
	return speed_boost_timer > 0.0


func apply_speed_boost(duration: float = SPEED_BOOST_DURATION) -> void:
	speed_boost_timer = duration
	speed_multiplier = SPEED_BOOST_MULT


func _update_speed_boost(delta: float) -> void:
	if speed_boost_timer <= 0.0:
		speed_multiplier = 1.0
		if not invulnerable:
			sprite.modulate = Color.WHITE
		return

	speed_boost_timer -= delta
	speed_multiplier = SPEED_BOOST_MULT
	# Tom amarelo leve enquanto o bônus estiver ativo.
	if not invulnerable:
		sprite.modulate = Color(1.15, 1.05, 0.55, 1.0)

	if speed_boost_timer <= 0.0:
		speed_boost_timer = 0.0
		speed_multiplier = 1.0
		if not invulnerable:
			sprite.modulate = Color.WHITE


func take_damage() -> bool:
	if invulnerable or lives <= 0:
		return false

	lives -= 1
	invulnerable = true
	invuln_timer = INVULN_DURATION
	flash_timer = 0.0

	if lives <= 0:
		died.emit()

	return true


func _update_invulnerability(delta: float) -> void:
	if not invulnerable:
		sprite.modulate.a = 1.0
		return

	invuln_timer -= delta
	flash_timer += delta
	sprite.modulate.a = 0.35 if int(flash_timer * 10.0) % 2 == 0 else 1.0

	if invuln_timer <= 0.0:
		invulnerable = false
		sprite.modulate.a = 1.0


func _handle_movement() -> void:
	var input_vector := Vector2.ZERO

	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		input_vector.x -= 1.0
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		input_vector.x += 1.0
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		input_vector.y -= 1.0
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		input_vector.y += 1.0

	moving = input_vector != Vector2.ZERO

	if moving:
		# Normaliza para a diagonal não ficar mais rápida que o eixo puro.
		input_vector = input_vector.normalized()

		# Animação: prioriza o eixo dominante (empate → lado).
		if absf(input_vector.x) >= absf(input_vector.y):
			direction = "side"
			facing_right = input_vector.x > 0.0
		elif input_vector.y < 0.0:
			direction = "back"
		else:
			direction = "front"

	velocity = input_vector * BASE_SPEED * speed_multiplier
	move_and_slide()

	var screen := Screen.size()
	global_position.x = clampf(global_position.x, 0.0, screen.x - DISPLAY_SIZE.x)
	global_position.y = clampf(global_position.y, 0.0, screen.y - DISPLAY_SIZE.y)


func _update_animation(delta: float) -> void:
	if not moving:
		current_frame = 0
		animation_timer = 0.0
		return

	animation_timer += delta
	if animation_timer < FRAME_DURATION:
		return

	animation_timer = 0.0
	var max_frames := 6
	match direction:
		"front":
			max_frames = walk_front.size()
		"side":
			max_frames = walk_side.size()
		_:
			max_frames = walk_back.size()

	current_frame = (current_frame + 1) % max_frames


func _update_sprite() -> void:
	var texture: Texture2D

	match direction:
		"front":
			texture = walk_front[current_frame] if moving else idle_front[0]
			sprite.flip_h = false
		"side":
			texture = walk_side[current_frame] if moving else idle_side[0]
			sprite.flip_h = facing_right
		_:
			texture = walk_back[current_frame] if moving else idle_back[0]
			sprite.flip_h = false

	sprite.texture = texture


func _load_sprites() -> void:
	var sheet := load("res://assets/player/bea_spritesheet.png") as Texture2D
	var frame_h := int(FRAME_SIZE.y)

	for i in range(2):
		idle_front.append(_slice(sheet, i, 0, frame_h, 0))

	for i in range(6):
		walk_front.append(_slice(sheet, i, frame_h + 5, frame_h - 5, 0))

	for i in range(2):
		idle_side.append(_slice(sheet, i, frame_h * 2, frame_h, 0))

	for i in range(6):
		walk_side.append(_slice(sheet, i, frame_h * 3, frame_h - 10, 0))

	for i in range(2):
		idle_back.append(_slice(sheet, i, frame_h * 4 - 10, frame_h - 15, 0))

	for i in range(6):
		walk_back.append(_slice(sheet, i, frame_h * 5 - 20, frame_h - 20, 0))


func _slice(sheet: Texture2D, index: int, y: int, height: int, _unused: int) -> Texture2D:
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(index * FRAME_SIZE.x, y, FRAME_SIZE.x, height)

	var image := atlas.get_image()
	image.resize(int(DISPLAY_SIZE.x), int(DISPLAY_SIZE.y), Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(image)
