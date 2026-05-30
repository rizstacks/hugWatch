extends Node3D

const PlayerController = preload("res://scripts/player_controller.gd")
const PickupObject = preload("res://scripts/pickup_object.gd")
const DoorScript = preload("res://scripts/door.gd")
const NPCTarget = preload("res://scripts/npc_target.gd")
const HUDScript = preload("res://scripts/hud.gd")

var player: CharacterBody3D
var hud: CanvasLayer

func _ready() -> void:
	_build_lighting()
	_build_map()
	_build_player()
	_build_hud()
	_build_interactables()

func _build_lighting() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.08, 0.09, 0.12)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.60, 0.75)
	e.ambient_light_energy = 0.55
	env.environment = e
	add_child(env)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-55, 35, 0)
	sun.light_energy = 1.4
	add_child(sun)

	var room_light := OmniLight3D.new()
	room_light.name = "RoomLight"
	room_light.position = Vector3(0, 5.5, 0)
	room_light.light_energy = 5.0
	room_light.omni_range = 35
	add_child(room_light)

func _build_map() -> void:
	# Main floor and ceiling
	_create_static_box("Floor", Vector3(48, 0.4, 36), Vector3(0, -0.2, 0), Color(0.38, 0.39, 0.43))
	_create_static_box("Ceiling", Vector3(48, 0.4, 36), Vector3(0, 5.2, 0), Color(0.18, 0.18, 0.20))

	# Outer walls
	_create_static_box("BackWall", Vector3(48, 5, 0.5), Vector3(0, 2.5, -18), Color(0.58, 0.55, 0.47))
	_create_static_box("FrontWall", Vector3(48, 5, 0.5), Vector3(0, 2.5, 18), Color(0.58, 0.55, 0.47))
	_create_static_box("LeftWall", Vector3(0.5, 5, 36), Vector3(-24, 2.5, 0), Color(0.50, 0.50, 0.52))
	_create_static_box("RightWall", Vector3(0.5, 5, 36), Vector3(24, 2.5, 0), Color(0.50, 0.50, 0.52))

	# Hallway / classroom divider walls, with openings
	_create_static_box("HallLeft", Vector3(0.4, 5, 12), Vector3(-7, 2.5, -8), Color(0.62, 0.59, 0.50))
	_create_static_box("HallLeft2", Vector3(0.4, 5, 10), Vector3(-7, 2.5, 12), Color(0.62, 0.59, 0.50))
	_create_static_box("HallRight", Vector3(0.4, 5, 12), Vector3(7, 2.5, -8), Color(0.62, 0.59, 0.50))
	_create_static_box("HallRight2", Vector3(0.4, 5, 10), Vector3(7, 2.5, 12), Color(0.62, 0.59, 0.50))
	_create_static_box("ClassBackWall", Vector3(34, 5, 0.4), Vector3(0, 2.5, 5), Color(0.66, 0.64, 0.55))

	# Chalk board
	_create_static_box("Whiteboard", Vector3(6, 2, 0.15), Vector3(0, 2.6, 4.72), Color(0.08, 0.12, 0.10), true, "Whiteboard: Rhythm class starts now. Find objects to throw.")

	# Desks and chairs in classroom
	for row in range(3):
		for col in range(4):
			var x := -5.0 + col * 3.3
			var z := 9.0 + row * 2.6
			_create_static_box("Desk", Vector3(2.0, 0.35, 1.3), Vector3(x, 1.0, z), Color(0.50, 0.28, 0.14), true, "A heavy desk. You can inspect it, but not pick it up yet.")
			_create_static_box("Chair", Vector3(0.9, 0.9, 0.9), Vector3(x, 0.55, z + 1.1), Color(0.16, 0.16, 0.18), true, "A classroom chair.")

	# Lockers in hallway
	for i in range(6):
		_create_static_box("Locker", Vector3(0.6, 2.2, 1.0), Vector3(-22.8, 1.1, -10 + i * 2), Color(0.14, 0.22, 0.33), true, "Locker %d: empty, but it rattles." % (i + 1))

	# Door to classroom
	_create_door("ClassroomDoor", Vector3(-7, 1.2, 3.6))

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(0, 1.1, -12)
	player.script = PlayerController
	add_child(player)

	var collision := CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	var capsule := CapsuleShape3D.new()
	capsule.height = 1.8
	capsule.radius = 0.35
	collision.shape = capsule
	collision.position.y = 0.9
	player.add_child(collision)

	var camera_holder := Node3D.new()
	camera_holder.name = "CameraHolder"
	camera_holder.position.y = 1.6
	player.add_child(camera_holder)

	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.fov = 75
	camera.current = true
	camera_holder.add_child(camera)

	var ray := RayCast3D.new()
	ray.name = "InteractionRay"
	ray.enabled = true
	ray.target_position = Vector3(0, 0, -3)
	camera.add_child(ray)

func _build_hud() -> void:
	hud = CanvasLayer.new()
	hud.name = "HUD"
	hud.script = HUDScript
	add_child(hud)
	player.set("hud", hud)

func _build_interactables() -> void:
	_create_pickup("Book", Vector3(1.2, 0.25, 0.8), Vector3(3, 1.45, 9), Color(0.20, 0.25, 0.70), 2.0)
	_create_pickup("Bottle", Vector3(0.35, 0.8, 0.35), Vector3(-2, 1.4, 11), Color(0.25, 0.75, 0.95), 1.0)
	_create_pickup("Drumstick", Vector3(0.18, 0.18, 1.5), Vector3(0, 1.4, 13), Color(0.75, 0.55, 0.28), 0.5)
	_create_npc("TargetStudent", Vector3(13, 1, 10), Color(0.85, 0.55, 0.40))

func _create_static_box(name: String, size: Vector3, pos: Vector3, color: Color, interactable := false, message := "") -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = name
	body.position = pos
	add_child(body)

	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _mat(color)
	body.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)

	if interactable:
		body.set_meta("interaction_text", "Press E: " + name)
		body.set_meta("message", message)
		body.script = preload("res://scripts/interactable_object.gd")
	return body

func _create_pickup(name: String, size: Vector3, pos: Vector3, color: Color, mass: float) -> RigidBody3D:
	var body := RigidBody3D.new()
	body.name = name
	body.position = pos
	body.mass = mass
	body.script = PickupObject
	body.set_meta("interaction_text", "Press E: Pick up " + name)
	add_child(body)

	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _mat(color)
	body.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	return body

func _create_door(name: String, pos: Vector3) -> StaticBody3D:
	var door := _create_static_box(name, Vector3(0.25, 2.4, 1.6), pos, Color(0.35, 0.18, 0.08))
	door.script = DoorScript
	door.set_meta("interaction_text", "Press E: Open/close door")
	return door

func _create_npc(name: String, pos: Vector3, color: Color) -> RigidBody3D:
	var npc := RigidBody3D.new()
	npc.name = name
	npc.position = pos
	npc.freeze = true
	npc.script = NPCTarget
	add_child(npc)

	var mesh_instance := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.height = 2.0
	mesh.radius = 0.45
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _mat(color)
	npc.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.height = 2.0
	shape.radius = 0.45
	collision.shape = shape
	npc.add_child(collision)
	return npc

func _mat(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	return material
