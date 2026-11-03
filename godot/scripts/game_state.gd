extends Node

## Dados compartilhados entre mapas, ranking e a tela final.

const HIGHSCORE_PATH := "user://highscores.cfg"
const MAX_HIGHSCORES := 10

var frogs_caught: int = 0
var game_time_ms: float = 0.0
var lives_left: int = 3
var survived: bool = true
var current_map: int = 1
var maps_cleared: int = 0
var party_visited: bool = false

## Modo Ranking (arcade / endless).
var ranking_mode: bool = false
var ranking_score: int = 0
var ranking_wave: int = 1


func reset() -> void:
	frogs_caught = 0
	game_time_ms = 0.0
	lives_left = 3
	survived = true
	current_map = 1
	maps_cleared = 0
	party_visited = false
	ranking_score = 0
	ranking_wave = 1
	# ranking_mode é definido no menu e não é limpo aqui.


func load_highscores() -> Array:
	var scores: Array = []
	var cfg := ConfigFile.new()
	if cfg.load(HIGHSCORE_PATH) != OK:
		return scores
	var count := int(cfg.get_value("meta", "count", 0))
	for i in range(count):
		scores.append({
			"name": str(cfg.get_value("score_%d" % i, "name", "???")),
			"score": int(cfg.get_value("score_%d" % i, "score", 0)),
			"time_ms": float(cfg.get_value("score_%d" % i, "time_ms", 0.0)),
		})
	scores.sort_custom(func(a, b): return int(a["score"]) > int(b["score"]))
	return scores


func qualifies_for_board(score: int) -> bool:
	if score <= 0:
		return false
	var scores := load_highscores()
	if scores.size() < MAX_HIGHSCORES:
		return true
	return score > int(scores[scores.size() - 1]["score"])


## Salva e devolve a posição 1-based no placar (0 se não entrou).
func submit_highscore(player_name: String, score: int, time_ms: float) -> int:
	var clean := player_name.strip_edges().to_upper()
	if clean.is_empty():
		clean = "AAA"
	if clean.length() > 3:
		clean = clean.substr(0, 3)
	while clean.length() < 3:
		clean += "A"

	var scores := load_highscores()
	scores.append({"name": clean, "score": score, "time_ms": time_ms})
	scores.sort_custom(func(a, b): return int(a["score"]) > int(b["score"]))
	if scores.size() > MAX_HIGHSCORES:
		scores = scores.slice(0, MAX_HIGHSCORES)

	var cfg := ConfigFile.new()
	cfg.set_value("meta", "count", scores.size())
	for i in range(scores.size()):
		cfg.set_value("score_%d" % i, "name", scores[i]["name"])
		cfg.set_value("score_%d" % i, "score", scores[i]["score"])
		cfg.set_value("score_%d" % i, "time_ms", scores[i]["time_ms"])
	cfg.save(HIGHSCORE_PATH)

	for i in range(scores.size()):
		if int(scores[i]["score"]) == score and str(scores[i]["name"]) == clean:
			return i + 1
	return 0
