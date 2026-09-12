extends Control

const LORE_TEXT := (
	"De Barbalha para o mundo, Beatriz, ou Bea para os mais "
	+ "próximos, é uma das três netas de Tadeu e uma caçadora "
	+ "de sapinhos que nunca recusa um bingo. "
	+ "Dizem que ela consegue encontrar qualquer sapinho... "
	+ "desde que não esteja ocupada marcando a cartela."
)

@onready var background: TextureRect = $Background
@onready var logo: TextureRect = $Panel/VBox/Logo
@onready var play_button: Button = $Panel/VBox/PlayButton
@onready var quit_button: Button = $Panel/VBox/QuitButton
@onready var lore_button: Button = $Panel/VBox/LoreButton
@onready var lore_panel: PanelContainer = $LorePanel
@onready var lore_label: Label = $LorePanel/Margin/LoreLabel
@onready var click_sound: AudioStreamPlayer = $ClickSound


func _ready() -> void:
	background.texture = load("res://assets/background/background.png")
	logo.texture = load("res://assets/ui/frog_hunt_logo.png")
	lore_label.text = LORE_TEXT
	lore_panel.visible = false

	play_button.pressed.connect(_on_play_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	lore_button.pressed.connect(_on_lore_pressed)


func _on_play_pressed() -> void:
	click_sound.play()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://scenes/loading_screen.tscn")


func _on_quit_pressed() -> void:
	click_sound.play()
	await get_tree().create_timer(0.1).timeout
	get_tree().quit()


func _on_lore_pressed() -> void:
	click_sound.play()
	lore_panel.visible = not lore_panel.visible
