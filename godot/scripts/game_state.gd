extends Node

## Dados compartilhados entre mapas e a tela final.

var frogs_caught: int = 0
var game_time_ms: float = 0.0
var lives_left: int = 3
var survived: bool = true
var current_map: int = 1
var maps_cleared: int = 0
var party_visited: bool = false


func reset() -> void:
	frogs_caught = 0
	game_time_ms = 0.0
	lives_left = 3
	survived = true
	current_map = 1
	maps_cleared = 0
	party_visited = false
