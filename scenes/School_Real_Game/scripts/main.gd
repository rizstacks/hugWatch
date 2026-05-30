extends Node3D

const SCHOOL_PATH := "res://assets/source/school_assemble2-2.glb"
const PLAYER_SCRIPT := preload("res://scripts/player_controller.gd")
const PICKUP_SCRIPT := preload("res://scripts/pickup_object.gd")
const DOOR_SCRIPT := preload("res://scripts/door.gd")

var hud_prompt: Label
var hud_objective: Label
var hud_message: Label
var message_timer: Timer

func _ready() -> void:
	_build_lighting()
	_build_hud()
	_load_school_model()
	_add_safety_floor()
	_create_player()
	_add_gameplay_props()
	_show_message("Find objects. Press E to pick up / interact. Left click to throw.", 4.0)

func _build_lighting() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.03, 0.035, 0.045)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.58, 0.7)
	e.ambient_light_energy = 0.45
	e.fog_enabled = true
	e.fog_density = 0.01
	e.fog_light_color = Color(0.45, 0.48, 0.55)
	env.environment = e
	add_child(env)

	var sun := DirectionalLight3D.new()
	sun.name = "ColdSun"
	sun.rotation_degrees = Vector3(-50, 40, 0)
	sun.light_energy = 1.2
	add_child(sun)

	var hall_light := OmniLight3D.new()
	hall_light.name = "HallwayLight"
	hall_light.position = Vector3(0, 5, 0)
	hall_light.omni_range = 35
	hall_light.light_energy = 7.0
	add_child(hall_light)

func _build_hud() -> void:
	var ui := CanvasLayer.new()
	ui.name = "HUD"
	ui.add_to_group("hud")
	add_child(ui)

	hud_objective = Label.new()
	hud_objective.name = "Objective"
	hud_objective.text = "Objective: Explore the school. Pick something up and throw it."
	hud_objective.position = Vector2(16, 16)
	hud_objective.add_theme_color_override("font_color", Color.WHITE)
	ui.add_child(hud_objective)

	var crosshair := Label.new()
	crosshair.name = "Crosshair"
	crosshair.text = "+"
	crosshair.add_theme_font_size_override("font_size", 22)
	crosshair.add_theme_color_override("font_color", Color.WHITE)
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-6, -12)
	ui.add_child(crosshair)

	hud_prompt = Label.new()
	hud_prompt.name = "Prompt"
	hud_prompt.text = ""
	hud_prompt.add_theme_font_size_override("font_size", 20)
	hud_prompt.add_theme_color_override("font_color", Color(0.9, 1.0, 0.65))
	hud_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hud_prompt.position = Vector2(-160, -90)
	ui.add_child(hud_prompt)

	hud_message = Label.new()
	hud_message.name = "Message"
	hud_message.text = ""
	hud_message.add_theme_font_size_override("font_size", 18)
	hud_message.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0))
	hud_message.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hud_message.position = Vector2(-280, -145)
	ui.add_child(hud_message)

	message_timer = Timer.new()
	message_timer.one_shot = true
	message_timer.timeout.connect(func(): hud_message.text = "")
	ui.add_child(message_timer)

func show_prompt(text: String) -> void:
	hud_prompt.text = text

func hide_prompt() -> void:
	hud_prompt.text = ""

func show_message(text: String, duration: float = 3.0) -> void:
	_show_message(text, duration)

func _show_message(text: String, duration: float = 3.0) -> void:
	hud_message.text = text
	message_timer.start(duration)

func _load_school_model() -> void:
	var packed := load(SCHOOL_PATH)
	if packed == null:
		_show_message("School model failed to load. Check assets/source folder.", 10.0)
		return

	var school := packed.instantiate()
	school.name = "School_Hallway_Rooftop_Stairs_Model"
	# The uploaded GLB origin is offset. This centers it and places floor near Y=0.
	school.position = Vector3(63.7, 5.0, -12.8)
	add_child(school)
	await get_tree().process_frame
	_add_trimesh_collision_recursive(school)

func _add_trimesh_collision_recursive(node: Node) -> void:
	if node is MeshInstance3D and node.mesh != null:
		var faces := node.mesh.get_faces()
		if faces.size() >= 3:
			var body := StaticBody3D.new()
			body.name = "AutoCollision"
			var shape := ConcavePolygonShape3D.new()
			shape.set_faces(faces)
			var col := CollisionShape3D.new()
			col.shape = shape
			body.add_child(col)
			node.add_child(body)
	for child in node.get_children():
		_add_trimesh_collision_recursive(child)

func _add_safety_floor() -> void:
	var body := StaticBody3D.new()
	body.name = "InvisibleSafetyFloor"
	body.position = Vector3(0, -0.08, 0)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(120, 0.2, 120)
	col.shape = shape
	body.add_child(col)
	add_child(body)

func _create_player() -> void:
	var player := CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(0, 1.8, 0)
	player.script = PLAYER_SCRIPT
	add_child(player)

	var body_col := CollisionShape3D.new()
	body_col.name = "CollisionShape3D"
	var cap := CapsuleShape3D.new()
	cap.height = 1.8
	cap.radius = 0.35
	body_col.shape = cap
	body_col.position = Vector3(0, 0.9, 0)
	player.add_child(body_col)

	var camera_holder := Node3D.new()
	camera_holder.name = "CameraHolder"
	camera_holder.position = Vector3(0, 1.55, 0)
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

	var hold := Node3D.new()
	hold.name = "HoldPoint"
	hold.position = Vector3(0, -0.2, -1.6)
	camera.add_child(hold)

func _add_gameplay_props() -> void:
	# These are extra gameplay props mixed into the 3D school model.
	_create_pickup("Book", Vector3(0, 1.1, 2.2), Vector3(0.45, 0.12, 0.65), Color(0.1, 0.25, 0.9), 0.8)
	_create_pickup("Bottle", Vector3(1.2, 1.1, 2.8), Vector3(0.25, 0.6, 0.25), Color(0.2, 0.8, 0.7), 0.6)
	_create_pickup("Chair", Vector3(-1.5, 0.65, 2.6), Vector3(0.8, 0.8, 0.8), Color(0.4, 0.25, 0.16), 2.0)
	_create_door("Test Door", Vector3(3.0, 2.0, 1.5), Vector3(1.0, 2.8, 0.18), Color(0.35, 0.18, 0.06))
	_create_target_dummy(Vector3(0, 1.0, 6.0))

func _create_pickup(label: String, pos: Vector3, size: Vector3, color: Color, mass: float) -> void:
	var body := RigidBody3D.new()
	body.name = label
	body.position = pos
	body.mass = mass
	body.script = PICKUP_SCRIPT
	body.set("item_name", label)
	body.add_to_group("pickup")

	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _mat(color)
	body.add_child(mesh_instance)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	add_child(body)

func _create_door(label: String, pos: Vector3, size: Vector3, color: Color) -> void:
	var door := StaticBody3D.new()
	door.name = label
	door.position = pos
	door.script = DOOR_SCRIPT

	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _mat(color)
	door.add_child(mesh_instance)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	door.add_child(col)
	add_child(door)

func _create_target_dummy(pos: Vector3) -> void:
	var dummy := RigidBody3D.new()
	dummy.name = "NPC_Target_Dummy"
	dummy.position = pos
	dummy.mass = 4.0

	var mesh_instance := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.35
	mesh.height = 1.8
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _mat(Color(0.7, 0.1, 0.1))
	dummy.add_child(mesh_instance)

	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.8
	col.shape = shape
	dummy.add_child(col)
	add_child(dummy)

func _mat(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.8
	return mat
