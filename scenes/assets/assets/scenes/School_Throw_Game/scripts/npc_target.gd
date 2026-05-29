extends RigidBody3D

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 8
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	var h := get_tree().get_first_node_in_group("hud")
	if h:
		h.call("show_message", "Target got hit. He is mad now.")
