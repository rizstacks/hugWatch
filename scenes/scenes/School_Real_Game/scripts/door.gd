extends StaticBody3D

@export var open_angle: float = 85.0
@export var open_speed: float = 5.0
var is_open := false
var target_y := 0.0

func _ready() -> void:
	target_y = rotation_degrees.y

func _process(delta: float) -> void:
	rotation_degrees.y = lerp(rotation_degrees.y, target_y, delta * open_speed)

func get_interaction_text() -> String:
	return "E: open/close door"

func interact(player: Node) -> void:
	is_open = !is_open
	target_y = open_angle if is_open else 0.0
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.call("show_message", "Door " + ("opened" if is_open else "closed"), 1.5)
