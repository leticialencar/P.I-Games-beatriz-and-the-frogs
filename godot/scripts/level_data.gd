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
				"background": "res://assets/background/background.png",
				"obstacles": [
					{"x": 0.32, "y": 0.42, "w": 0.10, "h": 0.07},
					{"x": 0.58, "y": 0.58, "w": 0.10, "h": 0.07},
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
				"background": "res://assets/background/background_map2.png",
				"obstacles": [
					{"x": 0.22, "y": 0.30, "w": 0.10, "h": 0.07},
					{"x": 0.55, "y": 0.45, "w": 0.10, "h": 0.14},
					{"x": 0.70, "y": 0.68, "w": 0.11, "h": 0.07},
				],
			}
		_:
			# Mapa 3 — boss: Sapão Preto + poucos vermelhos.
			return {
				"name": "Missao Sapao Preto",
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
				"background": "res://assets/background/background_map3_hunt.png",
				"obstacles": [
					{"x": 0.44, "y": 0.42, "w": 0.12, "h": 0.08},
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
