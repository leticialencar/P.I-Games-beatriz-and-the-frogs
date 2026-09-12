class_name LevelData
extends RefCounted

## Configuração por mapa + layouts de obstáculos (frações da tela).


static func get_config(map_number: int) -> Dictionary:
	match map_number:
		1:
			return {
				"name": "Mapa 1",
				"goal": 8,
				"boss_map": false,
				"max_strange": 2,
				"max_frogs": 8,
				"min_frogs": 3,
				"difficulty": 1.0,
				"allow_yellow": true,
				"allow_blue": false,
				"allow_golden": false,
				"strange_respawn_min": 7.0,
				"strange_respawn_max": 11.0,
				"background": "res://assets/background/background.png",
				"obstacles": [
					{"x": 0.28, "y": 0.34, "w": 0.10, "h": 0.07},
					{"x": 0.58, "y": 0.48, "w": 0.12, "h": 0.08},
					{"x": 0.42, "y": 0.68, "w": 0.11, "h": 0.07},
				],
			}
		2:
			return {
				"name": "Mapa 2",
				"goal": 12,
				"boss_map": false,
				"max_strange": 3,
				"max_frogs": 9,
				"min_frogs": 4,
				"difficulty": 1.35,
				"allow_yellow": true,
				"allow_blue": true,
				"allow_golden": true,
				"strange_respawn_min": 5.0,
				"strange_respawn_max": 8.0,
				"background": "res://assets/background/background_map2.png",
				"obstacles": [
					{"x": 0.18, "y": 0.22, "w": 0.12, "h": 0.08},
					{"x": 0.48, "y": 0.28, "w": 0.10, "h": 0.18},
					{"x": 0.70, "y": 0.22, "w": 0.12, "h": 0.08},
					{"x": 0.32, "y": 0.52, "w": 0.14, "h": 0.08},
					{"x": 0.58, "y": 0.55, "w": 0.10, "h": 0.16},
					{"x": 0.22, "y": 0.72, "w": 0.12, "h": 0.08},
					{"x": 0.72, "y": 0.70, "w": 0.13, "h": 0.08},
				],
			}
		_:
			# Mapa 3 — boss: Sapão Preto + vermelhos. Sem sapinhos pegáveis (maldade).
			return {
				"name": "Mapa 3 — Sapão Preto",
				"goal": 1,
				"boss_map": true,
				"boss_hp": 12,
				"max_strange": 3,
				"max_frogs": 4,
				"min_frogs": 0,
				"difficulty": 1.5,
				"allow_yellow": false,
				"allow_blue": false,
				"allow_golden": false,
				"strange_respawn_min": 4.0,
				"strange_respawn_max": 7.0,
				"background": "res://assets/background/background_map3_hunt.png",
				# Um único obstáculo no meio — força manobra contra o sapão.
				"obstacles": [
					{"x": 0.44, "y": 0.42, "w": 0.14, "h": 0.10},
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
