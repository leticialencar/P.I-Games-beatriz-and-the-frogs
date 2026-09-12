extends Control

const LORE_TEXT := (
	"De Barbalha para o mundo, Beatriz, ou Bea para os mais "
	+ "próximos, é uma das três netas de Tadeu e uma caçadora "
	+ "de sapinhos que nunca recusa um bingo. "
	+ "Dizem que ela consegue encontrar qualquer sapinho... "
	+ "desde que não esteja ocupada marcando a cartela."
)

@onready var background: TextureRect = $Background
@onready var logo: TextureRect = $Center/Panel/Margin/VBox/Logo
@onready var play_button: Button = $Center/Panel/Margin/VBox/PlayButton
@onready var quit_button: Button = $Center/Panel/Margin/VBox/QuitButton
@onready var lore_button: Button = $Center/Panel/Margin/VBox/LoreButton
@onready var lore_label: Label = $Center/Panel/Margin/VBox/LoreLabel
@onready var click_sound: AudioStreamPlayer = $ClickSound

var showing_lore := false


func _ready() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	background.texture = load("res://assets/background/background.png")
	logo.texture = load("res://assets/ui/frog_hunt_logo.png")
	lore_label.text = LORE_TEXT
	lore_label.visible = false

	play_button.pressed.connect(_on_play_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	lore_button.pressed.connect(_on_lore_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		_toggle_fullscreen()


func _toggle_fullscreen() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


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
	showing_lore = not showing_lore
	lore_label.visible = showing_lore
	play_button.visible = not showing_lore
	quit_button.visible = not showing_lore
	lore_button.text = "Voltar" if showing_lore else "Sobre a Bea"
