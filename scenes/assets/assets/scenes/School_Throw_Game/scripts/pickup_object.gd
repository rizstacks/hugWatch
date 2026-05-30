extends RigidBody3D

func get_interaction_text() -> String:
	return get_meta("interaction_text", "Press E: Pick up")

func interact(player: Node) -> void:
	if player.has_method("pickup"):
		player.call("pickup", self)
