class_name MobileControls
extends Control

signal direction_changed(direction: Vector2)
signal catch_pressed

const JOYSTICK_RADIUS := 74.0
const KNOB_RADIUS := 31.0
const ACTION_RADIUS := 58.0

var joystick_touch := -1
var action_touch := -1
var joystick_center := Vector2.ZERO
var action_center := Vector2.ZERO
var knob_position := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_controls()


func _layout_controls() -> void:
	joystick_center = Vector2(112.0, size.y - 112.0)
	action_center = Vector2(size.x - 112.0, size.y - 112.0)
	if joystick_touch == -1:
		knob_position = joystick_center
	queue_redraw()


func _draw() -> void:
	if joystick_center == Vector2.ZERO:
		_layout_controls()
	draw_circle(joystick_center, JOYSTICK_RADIUS, Color(0.05, 0.12, 0.05, 0.62))
	draw_arc(joystick_center, JOYSTICK_RADIUS, 0.0, TAU, 32, Color(0.55, 0.9, 0.28, 0.85), 3.0)
	draw_circle(knob_position, KNOB_RADIUS, Color(0.42, 0.82, 0.2, 0.85))
	draw_circle(action_center, ACTION_RADIUS, Color(0.95, 0.62, 0.15, 0.85))
	draw_arc(action_center, ACTION_RADIUS, 0.0, TAU, 32, Color(1, 0.92, 0.45, 1), 3.0)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event.index, event.position, event.pressed)
	elif event is InputEventScreenDrag:
		if event.index == joystick_touch:
			_update_joystick(event.position)


func _handle_touch(index: int, position: Vector2, pressed: bool) -> void:
	if pressed:
		if position.x < size.x * 0.55 and joystick_touch == -1:
			joystick_touch = index
			_update_joystick(position)
		elif action_touch == -1:
			action_touch = index
			catch_pressed.emit()
			queue_redraw()
		return
	if index == joystick_touch:
		joystick_touch = -1
		knob_position = joystick_center
		direction_changed.emit(Vector2.ZERO)
	if index == action_touch:
		action_touch = -1
	queue_redraw()


func _update_joystick(position: Vector2) -> void:
	var offset := position - joystick_center
	if offset.length() > JOYSTICK_RADIUS:
		offset = offset.normalized() * JOYSTICK_RADIUS
	knob_position = joystick_center + offset
	direction_changed.emit(offset / JOYSTICK_RADIUS)
	queue_redraw()
