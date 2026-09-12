class_name Obstacle
extends StaticBody2D

## Pedra sólida. Bloqueia a Bea (física) e os sapos (AABB).

const ROCK_TEXTURES: Array[String] = [
	"res://assets/obstacles/rock_1.png",
	"res://assets/obstacles/rock_2.png",
	"res://assets/obstacles/rock_3.png",
]

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D


func setup(rect: Rect2) -> void:
	position = rect.position + rect.size * 0.5

	var shape := RectangleShape2D.new()
	# Um pouco menor que o rect visual pra não “grudar” nas bordas.
	shape.size = rect.size * 0.85
	collision_shape.shape = shape

	var path: String = ROCK_TEXTURES[randi() % ROCK_TEXTURES.size()]
	var tex := load(path) as Texture2D
	sprite.texture = tex
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	var tex_size := tex.get_size()
	if tex_size.x > 0.0 and tex_size.y > 0.0:
		sprite.scale = Vector2(rect.size.x / tex_size.x, rect.size.y / tex_size.y)


func get_blocking_rect() -> Rect2:
	var shape := collision_shape.shape as RectangleShape2D
	var size := shape.size
	return Rect2(global_position - size * 0.5, size)
