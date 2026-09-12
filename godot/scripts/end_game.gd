extends Control

@onready var background: TextureRect = $Background
@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var stats_label: Label = $Panel/VBox/StatsLabel
@onready var bea_sprite: Sprite2D = $Panel/VBox/BeaHolder/BeaSprite
@onready var replay_button: Button = $Panel/VBox/ReplayButton
@onready var menu_button: Button = $Panel/VBox/MenuButton
@onready var quit_button: Button = $Panel/VBox/QuitButton

var frames: Array[Texture2D] = []
var current_frame := 0
var frame_timer := 0.0
const FRAME_DURATION := 0.18


func _ready() -> void:
	background.texture = load("res://assets/background/background.png")

	var caught := GameState.frogs_caught
	if not GameState.survived:
		title_label.text = "Game Over"
		_load_animation("res://assets/player/bea_sad.png")
		stats_label.text = "As vidas acabaram!\nSapinhos pegos: %d" % caught
	elif caught == 0:
		title_label.text = "Nenhum sapinho..."
		_load_animation("res://assets/player/bea_sad.png")
		stats_label.text = "Sapinhos pegos: 0"
	else:
		title_label.text = "Missão cumprida!"
		_load_animation("res://assets/player/bea_celebrate.png")
		stats_label.text = "Sapinhos pegos: %d\nVidas restantes: %d" % [
			caught,
			GameState.lives_left,
		]

	replay_button.pressed.connect(_on_replay)
	menu_button.pressed.connect(_on_menu)
	quit_button.pressed.connect(_on_quit)

	if frames.size() > 0:
		bea_sprite.texture = frames[0]


func _process(delta: float) -> void:
	if frames.is_empty():
		return

	frame_timer += delta
	if frame_timer >= FRAME_DURATION:
		frame_timer = 0.0
		current_frame = (current_frame + 1) % frames.size()
		bea_sprite.texture = frames[current_frame]


func _load_animation(path: String) -> void:
	var sheet := load(path) as Texture2D
	var frame_width := sheet.get_width() / 4
	var frame_height := sheet.get_height()

	for i in range(4):
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(i * frame_width, 0, frame_width, frame_height)
		var image := atlas.get_image()
		image.resize(
			maxi(1, int(frame_width * 0.25)),
			maxi(1, int(frame_height * 0.25)),
			Image.INTERPOLATE_NEAREST
		)
		frames.append(ImageTexture.create_from_image(image))


func _on_replay() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_quit() -> void:
	get_tree().quit()
