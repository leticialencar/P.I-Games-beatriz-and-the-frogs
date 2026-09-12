class_name Bullet
extends Node2D

const SPEED := 560.0
const HIT_RADIUS := 36.0
const LIFETIME := 1.6

var direction := Vector2.RIGHT
var age := 0.0
var spent := false


func setup(from: Vector2, dir: Vector2) -> void:
	global_position = from
	direction = dir.normalized() if dir.length_squared() > 0.01 else Vector2.RIGHT
	var tex := load("res://assets/frog/bullet.png") as Texture2D
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)


func _process(delta: float) -> void:
	if spent:
		return
	age += delta
	position += direction * SPEED * delta
	if age >= LIFETIME:
		spent = true
		queue_free()
		return

	var screen := Screen.size()
	if position.x < -40.0 or position.y < -40.0 or position.x > screen.x + 40.0 or position.y > screen.y + 40.0:
		spent = true
		queue_free()
