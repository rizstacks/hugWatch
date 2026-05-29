extends StaticBody3D

@export var hint_text: String = "Examine"
@export_multiline var examine_message: String = "There is nothing special here."
@export var one_time_only: bool = false
var used := false

func get_interaction_text() -> String:
	return hint_text

func interact(player: Node) -> void:
	if one_time_only and used:
		_show("You already checked this.")
		return
	used = true
	_show(examine_message)

func _show(text: String) -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.call("show_message", text)
