extends StaticBody3D

@export_multiline var board_text: String = "Board: Tomorrow's exam is cancelled. Something feels wrong."

func get_interaction_text() -> String:
	return "Read Whiteboard"

func interact(player: Node) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.call("show_message", board_text, 5.0)
