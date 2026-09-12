extends Node

## Dados compartilhados entre a partida e a tela final.

var frogs_caught: int = 0
var game_time_ms: float = 0.0
var lives_left: int = 3
var survived: bool = true


func reset() -> void:
	frogs_caught = 0
	game_time_ms = 0.0
	lives_left = 3
	survived = true
