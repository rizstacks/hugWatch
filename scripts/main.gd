extends Node3D

var player: CharacterBody3D
var camera_holder: Node3D
var camera: Camera3D
var ray: RayCast3D

var held_object: RigidBody3D = null
var score := 0
var game_time := 180.0
var game_over := false

var npcs: Array[CharacterBody3D] = []
var hugging_pairs: Array = []

var ui_score: Label
var ui_time: Label
var ui_prompt: Label
var ui_message: Label

const GRAVITY := 9.8
const WALK_SPEED := 6.5
const SPRINT_SPEED := 10.5
const JUMP_VELOCITY := 5.0
const MOUSE_SENS := 0.002
const THROW_FORCE := 28.0
const HOLD_DISTANCE := 2.4

func _ready() -> void:
	randomize()
	build_map()
	create_player()
	create_ui()
	spawn_npcs()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta: float) -> void:
	if game_over:
		return

	game_time -= delta
	ui_time.text = "Time: " + str(int(game_time))
	ui_score.text = "Score: " + str(score)

	if game_time <= 0:
		win_game()

	check_hug_events()
	update_prompt()

func _physics_process(delta: float) -> void:
	if player == null:
		return

	var velocity := player.velocity

	if not player.is_on_floor():
		velocity.y -= GRAVITY * delta

	if Input.is_key_pressed(KEY_SPACE) and player.is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_x := 0.0
	var input_z := 0.0

	if Input.is_key_pressed(KEY_A):
		input_x -= 1
	if Input.is_key_pressed(KEY_D):
		input_x += 1
	if Input.is_key_pressed(KEY_W):
		input_z -= 1
	if Input.is_key_pressed(KEY_S):
		input_z += 1

	var dir := (player.transform.basis * Vector3(input_x, 0, input_z)).normalized()
	var speed := SPRINT_SPEED if Input.is_key_pressed(KEY_SHIFT) else WALK_SPEED

	velocity.x = dir.x * speed
	velocity.z = dir.z * speed

	player.velocity = velocity
	player.move_and_slide()

	update_held_object()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		player.rotate_y(-event.relative.x * MOUSE_SENS)
		camera_holder.rotate_x(-event.relative.y * MOUSE_SENS)
		camera_holder.rotation.x = clamp(camera_holder.rotation.x, deg_to_rad(-80), deg_to_rad(80))

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

		if event.keycode == KEY_E:
			interact()

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and held_object:
			throw_object()

func build_map() -> void:
	box("Floor", Vector3(120, 0.4, 90), Vector3(0, -0.2, 0), Color(0.32, 0.32, 0.36))
	box("Ceiling", Vector3(120, 0.4, 90), Vector3(0, 6, 0), Color(0.14, 0.14, 0.17))

	box("Back Wall", Vector3(120, 6, 0.5), Vector3(0, 3, -45), Color(0.65, 0.62, 0.55))
	box("Front Wall", Vector3(120, 6, 0.5), Vector3(0, 3, 45), Color(0.65, 0.62, 0.55))
	box("Left Wall", Vector3(0.5, 6, 90), Vector3(-60, 3, 0), Color(0.65, 0.62, 0.55))
	box("Right Wall", Vector3(0.5, 6, 90), Vector3(60, 3, 0), Color(0.65, 0.62, 0.55))

	box("Hall Left Wall", Vector3(0.4, 5, 80), Vector3(-8, 2.5, 0), Color(0.45, 0.47, 0.52))
	box("Hall Right Wall", Vector3(0.4, 5, 80), Vector3(8, 2.5, 0), Color(0.45, 0.47, 0.52))

	room("Classroom A", Vector3(-32, 0, -22), Color(0.72, 0.68, 0.55))
	classroom_props(Vector3(-32, 0, -22), "A")

	room("Classroom B", Vector3(32, 0, -22), Color(0.72, 0.68, 0.55))
	classroom_props(Vector3(32, 0, -22), "B")

	room("Science Lab", Vector3(-32, 0, 18), Color(0.52, 0.68, 0.62))
	lab_props(Vector3(-32, 0, 18))

	room("Pool Room", Vector3(32, 0, 18), Color(0.45, 0.58, 0.75))
	pool_props(Vector3(32, 0, 18))

	for i in range(15):
		box("Locker L", Vector3(0.8, 3, 1.2), Vector3(-7.4, 1.5, -36 + i * 5), Color(0.08, 0.15, 0.45))
		box("Locker R", Vector3(0.8, 3, 1.2), Vector3(7.4, 1.5, -36 + i * 5), Color(0.08, 0.15, 0.45))

	for i in range(8):
		pickup("Book", Vector3(0.8, 0.15, 0.6), Vector3(-2, 0.5, -32 + i * 8), Color(0.85, 0.1, 0.1), 0.6)
		pickup("Backpack", Vector3(1.2, 0.8, 0.7), Vector3(2.5, 0.5, -30 + i * 8), Color(0.04, 0.04, 0.08), 1.5)
		pickup("Trash Can", Vector3(1, 1.5, 1), Vector3(5, 0.8, -32 + i * 8), Color(0.1, 0.1, 0.1), 2.0)

	add_lights()

func room(n: String, c: Vector3, wall_color: Color) -> void:
	var x := c.x
	var z := c.z

	box(n + " Back Wall", Vector3(24, 5, 0.4), Vector3(x, 2.5, z - 10), wall_color)
	box(n + " Left Wall", Vector3(0.4, 5, 20), Vector3(x - 12, 2.5, z), wall_color)
	box(n + " Right Wall", Vector3(0.4, 5, 20), Vector3(x + 12, 2.5, z), wall_color)
	box(n + " Front Left", Vector3(8, 5, 0.4), Vector3(x - 8, 2.5, z + 10), wall_color)
	box(n + " Front Right", Vector3(8, 5, 0.4), Vector3(x + 8, 2.5, z + 10), wall_color)

func classroom_props(c: Vector3, label: String) -> void:
	var x0 := c.x
	var z0 := c.z

	box("Whiteboard " + label, Vector3(9, 2, 0.15), Vector3(x0, 2.8, z0 - 9.7), Color(0.9, 0.95, 0.9))
	box("Teacher Desk " + label, Vector3(5, 1, 2), Vector3(x0, 0.5, z0 - 6.5), Color(0.42, 0.22, 0.1))

	for row in range(3):
		for col in range(3):
			var x := x0 - 6 + col * 6
			var z := z0 - 1 + row * 4
			box("Desk", Vector3(3, 0.8, 1.8), Vector3(x, 0.4, z), Color(0.48, 0.25, 0.12))
			pickup("Chair", Vector3(1.2, 1, 1.2), Vector3(x, 0.6, z + 2), Color(0.12, 0.12, 0.15), 2.0)

	for i in range(5):
		pickup("Book", Vector3(0.8, 0.15, 0.6), Vector3(x0 - 7 + i * 3.5, 1.1, z0 + 4), Color(0.8, 0.1, 0.1), 0.6)
		pickup("Pencil", Vector3(0.15, 0.15, 1), Vector3(x0 - 6 + i * 3, 1.2, z0 + 6), Color(1.0, 0.8, 0.1), 0.3)
		pickup("Backpack", Vector3(1, 0.8, 0.6), Vector3(x0 - 6 + i * 3, 0.5, z0 + 7.5), Color(0.04, 0.04, 0.08), 1.3)

func lab_props(c: Vector3) -> void:
	var x0 := c.x
	var z0 := c.z

	box("Lab Board", Vector3(9, 2, 0.15), Vector3(x0, 2.8, z0 - 9.7), Color(0.9, 0.95, 0.9))

	for i in range(3):
		box("Lab Table", Vector3(7, 1, 2), Vector3(x0, 0.5, z0 - 4 + i * 5), Color(0.35, 0.35, 0.38))
		pickup("Beaker", Vector3(0.4, 0.8, 0.4), Vector3(x0 - 2, 1.3, z0 - 4 + i * 5), Color(0.25, 0.8, 0.9), 0.6)
		pickup("Flower Vase", Vector3(0.6, 1, 0.6), Vector3(x0 + 2, 1.4, z0 - 4 + i * 5), Color(0.75, 0.4, 0.85), 1.0)

func pool_props(c: Vector3) -> void:
	var x0 := c.x
	var z0 := c.z

	box("Pool Water", Vector3(15, 0.2, 9), Vector3(x0, 0.05, z0), Color(0.08, 0.45, 0.85))
	box("Pool Edge Back", Vector3(17, 0.5, 0.5), Vector3(x0, 0.25, z0 - 5), Color(0.9, 0.9, 0.85))
	box("Pool Edge Front", Vector3(17, 0.5, 0.5), Vector3(x0, 0.25, z0 + 5), Color(0.9, 0.9, 0.85))
	box("Pool Edge Left", Vector3(0.5, 0.5, 10), Vector3(x0 - 8.5, 0.25, z0), Color(0.9, 0.9, 0.85))
	box("Pool Edge Right", Vector3(0.5, 0.5, 10), Vector3(x0 + 8.5, 0.25, z0), Color(0.9, 0.9, 0.85))

	for i in range(5):
		box("Pool Bench", Vector3(3, 0.5, 1), Vector3(x0 - 7 + i * 3.5, 0.4, z0 + 7), Color(0.4, 0.25, 0.12))
		pickup("Pool Ball", Vector3(0.8, 0.8, 0.8), Vector3(x0 - 6 + i * 3, 0.8, z0 - 7), Color(0.95, 0.4, 0.1), 1.0)

func create_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.position = Vector3(0, 2, 38)
	add_child(player)

	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.height = 1.9
	shape.radius = 0.35
	col.shape = shape
	col.position = Vector3(0, 0.95, 0)
	player.add_child(col)

	camera_holder = Node3D.new()
	camera_holder.name = "CameraHolder"
	camera_holder.position = Vector3(0, 1.85, 0)
	player.add_child(camera_holder)

	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.fov = 75
	camera.current = true
	camera_holder.add_child(camera)

	ray = RayCast3D.new()
	ray.name = "InteractionRay"
	ray.target_position = Vector3(0, 0, -4)
	ray.enabled = true
	camera.add_child(ray)

func create_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	ui_score = Label.new()
	ui_score.position = Vector2(20, 20)
	ui_score.text = "Score: 0"
	canvas.add_child(ui_score)

	ui_time = Label.new()
	ui_time.position = Vector2(20, 50)
	ui_time.text = "Time: 180"
	canvas.add_child(ui_time)

	ui_prompt = Label.new()
	ui_prompt.position = Vector2(20, 90)
	ui_prompt.text = ""
	canvas.add_child(ui_prompt)

	ui_message = Label.new()
	ui_message.position = Vector2(20, 130)
	ui_message.text = "HUG MONITOR: Stop the hugs."
	canvas.add_child(ui_message)

func spawn_npcs() -> void:
	var letters := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

	for i in range(26):
		create_npc(letters[i] + "+", letters[i] + "-", Vector3(randf_range(-35, 35), 1, randf_range(-30, 30)))
		create_npc(letters[i] + "-", letters[i] + "+", Vector3(randf_range(-35, 35), 1, randf_range(-30, 30)))

func create_npc(n: String, pair: String, pos: Vector3) -> void:
	var npc := CharacterBody3D.new()
	npc.name = n
	npc.position = pos
	npc.set_meta("pair", pair)
	npc.set_meta("hugging", false)
	npc.set_meta("target", Vector3(randf_range(-35, 35), 1, randf_range(-30, 30)))
	npc.add_to_group("npc")
	add_child(npc)

	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.height = 1.8
	shape.radius = 0.35
	col.shape = shape
	col.position = Vector3(0, 0.9, 0)
	npc.add_child(col)

	var mesh := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.height = 1.8
	cap.radius = 0.35
	mesh.mesh = cap
	mesh.position = Vector3(0, 0.9, 0)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(randf(), randf(), randf())
	mesh.material_override = mat
	npc.add_child(mesh)

	npcs.append(npc)

func check_hug_events() -> void:
	for npc in npcs:
		move_npc(npc)

	for i in range(npcs.size()):
		var a = npcs[i]
		if a.get_meta("hugging"):
			continue

		for j in range(i + 1, npcs.size()):
			var b = npcs[j]
			if b.get_meta("hugging"):
				continue

			if a.get_meta("pair") == b.name and a.global_position.distance_to(b.global_position) < 2.0:
				start_hug(a, b)

func move_npc(npc: CharacterBody3D) -> void:
	if npc.get_meta("hugging"):
		npc.velocity = Vector3.ZERO
		return

	var target: Vector3 = npc.get_meta("target")
	var dir := target - npc.global_position
	dir.y = 0

	if dir.length() < 1.5:
		npc.set_meta("target", Vector3(randf_range(-35, 35), 1, randf_range(-30, 30)))
	else:
		npc.velocity = dir.normalized() * 2.0
		npc.move_and_slide()

func start_hug(a: CharacterBody3D, b: CharacterBody3D) -> void:
	a.set_meta("hugging", true)
	b.set_meta("hugging", true)
	a.set_meta("partner", b)
	b.set_meta("partner", a)

	score -= 5
	ui_message.text = "HUG ALERT: " + a.name + " and " + b.name

func stop_hug(npc: CharacterBody3D) -> void:
	if not npc.get_meta("hugging"):
		return

	var partner = npc.get_meta("partner")
	npc.set_meta("hugging", false)
	npc.set_meta("target", Vector3(randf_range(-35, 35), 1, randf_range(-30, 30)))

	if partner:
		partner.set_meta("hugging", false)
		partner.set_meta("target", Vector3(randf_range(-35, 35), 1, randf_range(-30, 30)))

	score += 10
	ui_message.text = "BREAK IT UP! +10"

func interact() -> void:
	if held_object:
		drop_object()
		return

	ray.force_raycast_update()

	if ray.is_colliding():
		var obj = ray.get_collider()

		if obj is RigidBody3D and obj.is_in_group("pickup"):
			held_object = obj
			held_object.freeze = true
			held_object.gravity_scale = 0
			return

		if obj is CharacterBody3D and obj.is_in_group("npc"):
			stop_hug(obj)
			return

func update_prompt() -> void:
	ray.force_raycast_update()

	if held_object:
		ui_prompt.text = "Left Click: Throw | E: Drop"
		return

	if ray.is_colliding():
		var obj = ray.get_collider()
		if obj is RigidBody3D and obj.is_in_group("pickup"):
			ui_prompt.text = "E: Pick up " + obj.name
			return
		if obj is CharacterBody3D and obj.is_in_group("npc") and obj.get_meta("hugging"):
			ui_prompt.text = "E: BREAK UP HUG"
			return

	ui_prompt.text = ""

func update_held_object() -> void:
	if held_object:
		held_object.global_position = camera.global_position + -camera.global_transform.basis.z * HOLD_DISTANCE
		held_object.global_rotation = camera.global_rotation

func drop_object() -> void:
	held_object.freeze = false
	held_object.gravity_scale = 1
	held_object = null

func throw_object() -> void:
	var obj := held_object
	held_object = null

	obj.freeze = false
	obj.gravity_scale = 1
	obj.linear_velocity = Vector3.ZERO
	obj.angular_velocity = Vector3.ZERO
	obj.apply_impulse(-camera.global_transform.basis.z * THROW_FORCE)

func win_game() -> void:
	game_over = true
	ui_message.text = "BELL RANG. YOU WIN. FINAL SCORE: " + str(score)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func add_lights() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 35, 0)
	sun.light_energy = 1.2
	add_child(sun)

	for z in [-35, -20, 0, 20, 35]:
		var light := OmniLight3D.new()
		light.position = Vector3(0, 4.5, z)
		light.light_energy = 3
		light.omni_range = 28
		add_child(light)

func box(n: String, size: Vector3, pos: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = n
	body.position = pos

	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mi.material_override = mat

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape

	body.add_child(mi)
	body.add_child(col)
	add_child(body)
	return body

func pickup(n: String, size: Vector3, pos: Vector3, color: Color, mass_value: float) -> RigidBody3D:
	var body := RigidBody3D.new()
	body.name = n
	body.position = pos
	body.mass = mass_value
	body.add_to_group("pickup")

	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mi.material_override = mat

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape

	body.add_child(mi)
	body.add_child(col)
	add_child(body)
	return body
