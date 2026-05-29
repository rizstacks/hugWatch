extends RigidBody3D

@export var item_name: String = "Object"

func get_interaction_text() -> String:
	return "E: pick up " + item_name

func interact(player: Node) -> void:
	if player.has_method("pick_up"):
		player.call("pick_up", self)
