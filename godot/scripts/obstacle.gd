class_name Obstacle
extends StaticBody2D

## Elemento sólido recortado da folha complementar de cada mapa.

const SHEET_PATHS := {
	1: "res://assets/obstacles/map_1.png",
	2: "res://assets/obstacles/map_2.png",
	3: "res://assets/obstacles/map_3.png",
}

const SHEET_REGIONS := {
	# Rocha grande e tronco coberto de musgo.
	1: [
		Rect2(520, 10, 250, 205),
		Rect2(25, 380, 305, 145),
	],
	# Pilha de pedras, tronco e arco em ruínas.
	2: [
		Rect2(1030, 195, 185, 95),
		Rect2(1340, 285, 330, 140),
		Rect2(835, 670, 240, 270),
	],
	# Lápide, rochas e árvore seca da arena do Lasombra.
	3: [
		Rect2(10, 10, 195, 265),
		Rect2(185, 295, 205, 125),
		Rect2(1190, 740, 190, 275),
	],
}

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D


func setup(rect: Rect2, map_number: int, variant: int) -> void:
	position = rect.position + rect.size * 0.5

	var path: String = SHEET_PATHS.get(map_number, SHEET_PATHS[1])
	var sheet := load(path) as Texture2D
	var regions: Array = SHEET_REGIONS.get(map_number, SHEET_REGIONS[1])
	var region: Rect2 = regions[variant % regions.size()]
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = region
	atlas.filter_clip = true
	sprite.texture = atlas
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	# Mantém a proporção do desenho; o código anterior esticava as pedras.
	var texture_size := region.size
	var scale_factor := minf(
		rect.size.x / texture_size.x,
		rect.size.y / texture_size.y
	)
	sprite.scale = Vector2.ONE * scale_factor

	var visual_size := texture_size * scale_factor
	var shape := RectangleShape2D.new()
	# A base do desenho é a parte que efetivamente bloqueia o caminho.
	shape.size = Vector2(visual_size.x * 0.78, visual_size.y * 0.58)
	collision_shape.position.y = visual_size.y * 0.18
	collision_shape.shape = shape


func get_blocking_rect() -> Rect2:
	var shape := collision_shape.shape as RectangleShape2D
	var size := shape.size
	var center := global_position + collision_shape.position
	return Rect2(center - size * 0.5, size)
