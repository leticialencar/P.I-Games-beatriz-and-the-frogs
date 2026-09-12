class_name Screen
extends Object

## Tamanho lógico atual do jogo (cresce com a janela quando stretch=expand).


static func size() -> Vector2:
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		var rect := tree.root.get_visible_rect()
		if rect.size.x >= 640.0 and rect.size.y >= 360.0:
			return rect.size
	return Vector2(1280, 720)


static func width() -> float:
	return size().x


static func height() -> float:
	return size().y
