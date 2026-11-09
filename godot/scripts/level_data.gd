class_name LevelData
extends RefCounted

## Configuração por mapa + layouts de obstáculos (frações da tela).
## Balanceado mais leve para apresentação / jogadores novos.


static func get_config(map_number: int) -> Dictionary:
	match map_number:
		1:
			return {
				"name": "Mapa 1",
				"goal": 6,
				"boss_map": false,
				"max_strange": 1,
				"max_frogs": 7,
				"min_frogs": 3,
				"difficulty": 0.85,
				"allow_yellow": true,
				"allow_blue": false,
				"allow_golden": false,
				"strange_respawn_min": 10.0,
				"strange_respawn_max": 14.0,
				"background": "res://assets/background/background_map_1.png",
				"obstacles": [
					{"x": 0.30, "y": 0.34, "w": 0.15, "h": 0.18},
					{"x": 0.58, "y": 0.62, "w": 0.20, "h": 0.11},
				],
			}
		2:
			return {
				"name": "Mapa 2",
				"goal": 8,
				"boss_map": false,
				"max_strange": 2,
				"max_frogs": 8,
				"min_frogs": 3,
				"difficulty": 1.05,
				"allow_yellow": true,
				"allow_blue": true,
				"allow_golden": true,
				"strange_respawn_min": 8.0,
				"strange_respawn_max": 12.0,
				"background": "res://assets/background/background_map_2.png",
				"obstacles": [
					{"x": 0.18, "y": 0.28, "w": 0.16, "h": 0.10},
					{"x": 0.54, "y": 0.48, "w": 0.22, "h": 0.12},
					{"x": 0.75, "y": 0.58, "w": 0.15, "h": 0.28},
				],
			}
		_:
			# Mapa 3 — boss: Lasombra + poucos vermelhos.
			return {
				"name": "Missão Lasombra",
				"goal": 1,
				"boss_map": true,
				"boss_hp": 8,
				"max_strange": 1,
				"max_frogs": 3,
				"min_frogs": 0,
				"difficulty": 1.15,
				"allow_yellow": false,
				"allow_blue": false,
				"allow_golden": false,
				"strange_respawn_min": 8.0,
				"strange_respawn_max": 12.0,
				"background": "res://assets/background/background_map_3.png",
				"obstacles": [
					{"x": 0.08, "y": 0.24, "w": 0.12, "h": 0.28},
					{"x": 0.74, "y": 0.24, "w": 0.16, "h": 0.12},
					{"x": 0.80, "y": 0.62, "w": 0.12, "h": 0.30},
				],
			}


static func max_maps() -> int:
	return 3


static func obstacle_rects_for(map_number: int, screen: Vector2) -> Array[Rect2]:
	var config := get_config(map_number)
	var rects: Array[Rect2] = []
	for item in config.get("obstacles", []):
		rects.append(Rect2(
			float(item["x"]) * screen.x,
			float(item["y"]) * screen.y,
			float(item["w"]) * screen.x,
			float(item["h"]) * screen.y
		))
	return rects
