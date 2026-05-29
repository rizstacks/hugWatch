extends StaticBody3D

@export var open_angle: float = 90.0
@export var open_speed: float = 5.0
@export var locked: bool = false
@export var locked_message: String = "The door is locked."

var is_open := false
var closed_rotation_y := 0.0
var target_rotation_y := 0.0

func _ready() -> void:
	closed_rotation_y = rotation.y
	target_rotation_y = closed_rotation_y

func get_interaction_text() -> String:
	if locked:
		return "Open Door"
	return "Close Door" if is_open else "Open Door"

func interact(player: Node) -> void:
	if locked:
		_show(locked_message)
		return
	is_open = not is_open
	target_rotation_y = closed_rotation_y + deg_to_rad(open_angle if is_open else 0.0)
	_show("The door opens." if is_open else "The door closes.")

func _process(delta: float) -> void:
	rotation.y = lerp_angle(rotation.y, target_rotation_y, delta * open_speed)

func _show(text: String) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.call("show_message", text, 2.2)
