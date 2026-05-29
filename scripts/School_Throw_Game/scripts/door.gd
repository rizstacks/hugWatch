extends StaticBody3D

var is_open := false
var closed_rotation := 0.0
var open_rotation := 90.0

func _ready() -> void:
	closed_rotation = rotation_degrees.y
	open_rotation = closed_rotation + 90.0

func get_interaction_text() -> String:
	return "Press E: close door" if is_open else "Press E: open door"

func interact(player: Node) -> void:
	is_open = !is_open
	rotation_degrees.y = open_rotation if is_open else closed_rotation
