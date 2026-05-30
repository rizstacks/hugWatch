extends Node3D

const PlayerController = preload("res://scripts/player_controller.gd")
const HUD = preload("res://scripts/hud.gd")
const InteractableObject = preload("res://scripts/interactable_object.gd")
const DoorScript = preload("res://scripts/door.gd")
const LockerScript = preload("res://scripts/locker.gd")
const WhiteboardScript = preload("res://scripts/whiteboard.gd")

func _ready() -> void:
	_setup_input()
	_build_lighting()
	_build_school()
	_build_player()

func _setup_input() -> void:
	_add_action("move_forward", KEY_W)
	_add_action("move_backward", KEY_S)
	_add_action("move_left", KEY_A)
	_add_action("move_right", KEY_D)
	_add_action("sprint", KEY_SHIFT)
	_add_action("jump", KEY_SPACE)
	_add_action("interact", KEY_E)

func _add_action(action_name: String, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var has_key := false
	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey and event.keycode == keycode:
			has_key = true
	if not has_key:
		var e := InputEventKey.new()
		e.keycode = keycode
		InputMap.action_add_event(action_name, e)

func _build_lighting() -> void:
	var world := WorldEnvironment.new()
	world.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.055, 0.075)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.45, 0.50, 0.65)
	env.ambient_light_energy = 0.35
	env.fog_enabled = true
	env.fog_density = 0.015
	env.fog_light_color = Color(0.35, 0.36, 0.42)
	world.environment = env
	add_child(world)

	var sun := DirectionalLight3D.new()
	sun.name = "DirectionalLight3D"
	sun.light_energy = 1.5
	sun.rotation_degrees = Vector3(-45, 35, 0)
	add_child(sun)

	var room_light := OmniLight3D.new()
	room_light.name = "MainRoomLight"
	room_light.position = Vector3(0, 5.7, 0)
	room_light.omni_range = 25
	room_light.light_energy = 2.5
	add_child(room_light)

func _build_player() -> void:
	var player := CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(0, 1.0, 13)
	player.set_script(PlayerController)
	add_child(player)

	var shape := CollisionShape3D.new()
	shape.name = "CollisionShape3D"
	var capsule := CapsuleShape3D.new()
	capsule.height = 1.8
	capsule.radius = 0.35
	shape.shape = capsule
	shape.position = Vector3(0, 0.9, 0)
	player.add_child(shape)

	var holder := Node3D.new()
	holder.name = "CameraHolder"
	holder.position = Vector3(0, 1.65, 0)
	player.add_child(holder)

	var cam := Camera3D.new()
	cam.name = "Camera3D"
	cam.fov = 75
	holder.add_child(cam)

	var ray := RayCast3D.new()
	ray.name = "InteractionRay"
	ray.enabled = true
	ray.target_position = Vector3(0, 0, -3.0)
	cam.add_child(ray)

	var ui := CanvasLayer.new()
	ui.name = "UI"
	ui.set_script(HUD)
	player.add_child(ui)

func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.9
	return m

func _create_box(parent: Node, name: String, pos: Vector3, size: Vector3, color: Color, collision := true, script: Script = null) -> Node3D:
	var body: Node3D
	if collision:
		body = StaticBody3D.new()
		body.collision_layer = 1
		body.collision_mask = 1
	else:
		body = Node3D.new()
	body.name = name
	body.position = pos
	if script != null:
		body.set_script(script)
	parent.add_child(body)

	var mesh := MeshInstance3D.new()
	mesh.name = name + "_Mesh"
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = _mat(color)
	body.add_child(mesh)

	if collision:
		var col := CollisionShape3D.new()
		col.name = "CollisionShape3D"
		var col_box := BoxShape3D.new()
		col_box.size = size
		col.shape = col_box
		body.add_child(col)
	return body

func _build_school() -> void:
	var school := Node3D.new()
	school.name = "GeneratedSchool"
	add_child(school)

	# Closed room box / playable space
	_create_box(school, "Floor", Vector3(0, -0.1, 0), Vector3(38, 0.2, 38), Color(0.25, 0.25, 0.28))
	_create_box(school, "Ceiling", Vector3(0, 6.0, 0), Vector3(38, 0.25, 38), Color(0.11, 0.12, 0.15))
	_create_box(school, "BackWall", Vector3(0, 3, -19), Vector3(38, 6, 0.35), Color(0.50, 0.48, 0.42))
	_create_box(school, "FrontWall", Vector3(0, 3, 19), Vector3(38, 6, 0.35), Color(0.50, 0.48, 0.42))
	_create_box(school, "LeftWall", Vector3(-19, 3, 0), Vector3(0.35, 6, 38), Color(0.48, 0.46, 0.40))
	_create_box(school, "RightWall", Vector3(19, 3, 0), Vector3(0.35, 6, 38), Color(0.48, 0.46, 0.40))

	# Hallway and classrooms partitions
	_create_box(school, "HallLeftWall", Vector3(-6, 2.5, 0), Vector3(0.25, 5, 28), Color(0.60, 0.57, 0.48))
	_create_box(school, "HallRightWall", Vector3(6, 2.5, 0), Vector3(0.25, 5, 28), Color(0.60, 0.57, 0.48))
	_create_box(school, "ClassroomBackWall", Vector3(0, 2.5, -7), Vector3(38, 5, 0.25), Color(0.57, 0.54, 0.47))
	_create_box(school, "ClassroomFrontWall", Vector3(0, 2.5, 7), Vector3(38, 5, 0.25), Color(0.57, 0.54, 0.47))

	# Door openings are represented by interactive doors placed on walls
	var door1 := _create_box(school, "Door_Classroom_A", Vector3(-6.05, 1.25, 10), Vector3(0.25, 2.5, 1.2), Color(0.38, 0.20, 0.10), true, DoorScript)
	door1.set("open_angle", -95.0)
	var door2 := _create_box(school, "Door_Classroom_B", Vector3(6.05, 1.25, -10), Vector3(0.25, 2.5, 1.2), Color(0.38, 0.20, 0.10), true, DoorScript)
	door2.set("open_angle", 95.0)

	# Classroom desks
	for i in range(4):
		for j in range(3):
			_create_desk(school, Vector3(-12 + j * 3.0, 0.55, -3 + i * 2.4))
			_create_desk(school, Vector3(9 + j * 3.0, 0.55, 3 - i * 2.4))

	# Lockers in hallway
	for k in range(6):
		var locker := _create_box(school, "Locker_%d" % (101 + k), Vector3(-18.7, 1.3, -12 + k * 2.2), Vector3(0.4, 2.6, 1.2), Color(0.20, 0.28, 0.42), true, LockerScript)
		locker.set("locker_number", str(101 + k))
		locker.set("contents", "A few notebooks and a forgotten lunch. It smells terrible.")

	# Whiteboard and radio/objective props
	var board := _create_box(school, "Whiteboard", Vector3(-12, 2.2, -18.75), Vector3(6.5, 2.0, 0.12), Color(0.85, 0.88, 0.82), true, WhiteboardScript)
	board.set("board_text", "Whiteboard: ROOM 204 - MUSIC PRACTICE AFTER SCHOOL. The handwriting looks rushed.")

	var note := _create_box(school, "Desk_Note", Vector3(12, 1.15, 16), Vector3(1.2, 0.1, 0.8), Color(0.9, 0.82, 0.55), true, InteractableObject)
	note.set("hint_text", "Read Note")
	note.set("examine_message", "The note says: Check the lockers before leaving. Someone was here after class.")

	var radio := _create_box(school, "Old_Radio", Vector3(0, 0.65, -15), Vector3(1.1, 0.6, 0.5), Color(0.06, 0.06, 0.07), true, InteractableObject)
	radio.set("hint_text", "Use Radio")
	radio.set("examine_message", "Static fills the hallway. For a second, you hear footsteps behind you.")

	# Some overhead lights
	for z in [-12, 0, 12]:
		var light := OmniLight3D.new()
		light.name = "HallLight"
		light.position = Vector3(0, 5.4, z)
		light.omni_range = 9
		light.light_energy = 1.4
		school.add_child(light)

func _create_desk(parent: Node, pos: Vector3) -> void:
	var desk := _create_box(parent, "Desk", pos, Vector3(1.5, 0.25, 1.0), Color(0.42, 0.25, 0.13), true, InteractableObject)
	desk.set("hint_text", "Examine Desk")
	desk.set("examine_message", "A scratched school desk. Someone carved the word 'RUN' into the corner.")
	_create_box(desk, "DeskLeg1", Vector3(-0.55, -0.45, -0.35), Vector3(0.15, 0.9, 0.15), Color(0.25, 0.25, 0.25), true)
	_create_box(desk, "DeskLeg2", Vector3(0.55, -0.45, -0.35), Vector3(0.15, 0.9, 0.15), Color(0.25, 0.25, 0.25), true)
	_create_box(desk, "DeskLeg3", Vector3(-0.55, -0.45, 0.35), Vector3(0.15, 0.9, 0.15), Color(0.25, 0.25, 0.25), true)
	_create_box(desk, "DeskLeg4", Vector3(0.55, -0.45, 0.35), Vector3(0.15, 0.9, 0.15), Color(0.25, 0.25, 0.25), true)
