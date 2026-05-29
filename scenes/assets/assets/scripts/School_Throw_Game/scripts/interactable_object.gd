extends StaticBody3D

func get_interaction_text() -> String:
	return get_meta("interaction_text", "Press E: interact")

func interact(player: Node) -> void:
	var h := get_tree().get_first_node_in_group("hud")
	var msg: String = get_meta("message", "Nothing interesting.")
	if h:
		h.call("show_message", msg)
