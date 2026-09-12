class_name LevelData
extends RefCounted

## Configuração por mapa (Parte 1 — sem arte/obstáculos novos ainda).


static func get_config(map_number: int) -> Dictionary:
	match map_number:
		1:
			return {
				"name": "Mapa 1",
				"goal": 8,
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
			}
		_:
			# Mapa 2 — mais difícil (GDD).
			return {
				"name": "Mapa 2",
				"goal": 12,
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
			}


static func max_maps() -> int:
	return 2
