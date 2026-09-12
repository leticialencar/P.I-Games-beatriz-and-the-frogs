extends Control

## Overlay de pause: processa mesmo com a árvore pausada.

@onready var resume_button: Button = $Center/Panel/Margin/VBox/ResumeButton
@onready var menu_button: Button = $Center/Panel/Margin/VBox/MenuButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	resume_button.pressed.connect(_resume)
	menu_button.pressed.connect(_to_menu)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	if event.keycode == KEY_F11:
		_toggle_fullscreen()
		get_viewport().set_input_as_handled()
		return

	if event.keycode != KEY_ESCAPE:
		return

	if visible:
		_resume()
	elif _can_pause():
		_pause()
	get_viewport().set_input_as_handled()


func _can_pause() -> bool:
	var game := get_tree().current_scene
	if game == null or not game.has_method("can_pause"):
		return true
	return game.can_pause()


func _pause() -> void:
	visible = true
	get_tree().paused = true
	resume_button.grab_focus()


func _resume() -> void:
	visible = false
	get_tree().paused = false


func _to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _toggle_fullscreen() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
