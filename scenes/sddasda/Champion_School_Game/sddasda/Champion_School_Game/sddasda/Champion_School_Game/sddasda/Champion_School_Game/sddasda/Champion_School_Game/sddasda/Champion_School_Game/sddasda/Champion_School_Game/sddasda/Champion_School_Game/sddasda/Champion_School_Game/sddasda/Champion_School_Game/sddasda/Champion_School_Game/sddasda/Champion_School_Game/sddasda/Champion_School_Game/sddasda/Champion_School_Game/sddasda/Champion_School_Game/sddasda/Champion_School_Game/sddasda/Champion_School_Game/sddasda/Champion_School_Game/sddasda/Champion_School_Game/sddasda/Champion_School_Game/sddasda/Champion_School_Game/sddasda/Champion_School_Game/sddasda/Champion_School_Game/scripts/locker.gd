extends StaticBody3D

@export var locker_number: String = "104"
@export var is_locked: bool = false
@export_multiline var contents: String = "Old books, dust, and a cracked pencil."

func get_interaction_text() -> String:
	return "Check Locker " + locker_number

func interact(player: Node) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		if is_locked:
			hud.call("show_message", "Locker " + locker_number + " is locked.")
		else:
			hud.call("show_message", "Locker " + locker_number + ": " + contents)
