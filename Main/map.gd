@tool
extends Node3D

<<<<<<< Updated upstream
@export var clear_old_scene_siblings: bool = false

const KEY_INTERACT := KEY_E
const INTERACT_DISTANCE := 4.0
const HOLD_DISTANCE := 2.15
const THROW_FORCE := 17.0
const EPS := 0.04
=======
const WALL_H: float = 4.6
const WALL_T: float = 0.28
const CEIL_T: float = 0.22
const FLOOR_T: float = 0.18
>>>>>>> Stashed changes

const HALL_X0: float = -54.0
const HALL_X1: float = 54.0
const HALL_Z0: float = -6.0
const HALL_Z1: float = 6.0

const POOL_X0: float = -30.0
const POOL_X1: float = 30.0
const POOL_Z0: float = -34.0
const POOL_Z1: float = -6.0

const CLASS_X0: float = -54.0
const CLASS_X1: float = -18.0
const LAB_X0: float = -18.0
const LAB_X1: float = 18.0
const OFFICE_X0: float = 18.0
const OFFICE_X1: float = 54.0
const ROOM_Z0: float = 6.0
const ROOM_Z1: float = 34.0

var mats: Dictionary = {}
var doors: Array[Dictionary] = []


func _ready() -> void:
	build_map()


func _process(delta: float) -> void:
	for door_data: Dictionary in doors:
		var pivot: Node3D = door_data["pivot"] as Node3D
		var target: float = float(door_data["target"])
		pivot.rotation.y = lerp_angle(pivot.rotation.y, target, minf(delta * 10.0, 1.0))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_E:
			_toggle_nearest_door()


func build_map() -> void:
	_clear()
	mats.clear()
	doors.clear()

	_build_structure()
	_build_hallway()
	_build_pool()
	_build_classroom()
	_build_lab()
	_build_office()
	_build_pickups()
	_build_lights()


func _clear() -> void:
	for child: Node in get_children():
		child.queue_free()


func _mat(id: String, color: Color, alpha: float = 1.0) -> StandardMaterial3D:
	var key: String = id + "_" + str(alpha)
	if mats.has(key):
		return mats[key] as StandardMaterial3D

	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(color.r, color.g, color.b, alpha)
	material.roughness = 0.95
	material.metallic = 0.0

	if alpha < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.alpha_scissor_threshold = 0.02

	mats[key] = material
	return material


func _box(name: String, pos: Vector3, size: Vector3, material: Material, collision: bool = true, parent: Node = self) -> Node3D:
	var node: Node3D
	if collision:
		node = StaticBody3D.new()
	else:
		node = Node3D.new()

	node.name = name
	node.position = pos
	parent.add_child(node)

	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size

	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	node.add_child(mesh_instance)

	if collision:
		var shape: BoxShape3D = BoxShape3D.new()
		shape.size = size

		var collision_shape: CollisionShape3D = CollisionShape3D.new()
		collision_shape.shape = shape
		node.add_child(collision_shape)

	return node


func _cylinder(name: String, pos: Vector3, radius: float, height: float, material: Material, collision: bool = true, parent: Node = self) -> Node3D:
	var node: Node3D
	if collision:
		node = StaticBody3D.new()
	else:
		node = Node3D.new()

	node.name = name
	node.position = pos
	parent.add_child(node)

	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 8

	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	node.add_child(mesh_instance)

	if collision:
		var shape: CylinderShape3D = CylinderShape3D.new()
		shape.radius = radius
		shape.height = height

		var collision_shape: CollisionShape3D = CollisionShape3D.new()
		collision_shape.shape = shape
		node.add_child(collision_shape)

	return node


func _pickup_box(name: String, pos: Vector3, size: Vector3, material: Material, mass_value: float = 0.45) -> RigidBody3D:
	var body: RigidBody3D = RigidBody3D.new()
	body.name = name
	body.position = pos
	body.mass = mass_value
	body.gravity_scale = 1.0
	body.linear_damp = 0.2
	body.angular_damp = 0.2
	body.add_to_group("pickup")
	add_child(body)

	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size

	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	body.add_child(mesh_instance)

	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size

	var collision_shape: CollisionShape3D = CollisionShape3D.new()
	collision_shape.shape = shape
	body.add_child(collision_shape)

	return body


func _pickup_cylinder(name: String, pos: Vector3, radius: float, height: float, material: Material, mass_value: float = 0.35) -> RigidBody3D:
	var body: RigidBody3D = RigidBody3D.new()
	body.name = name
	body.position = pos
	body.mass = mass_value
	body.gravity_scale = 1.0
	body.linear_damp = 0.2
	body.angular_damp = 0.2
	body.add_to_group("pickup")
	add_child(body)

	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 8

	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	body.add_child(mesh_instance)

	var shape: CylinderShape3D = CylinderShape3D.new()
	shape.radius = radius
	shape.height = height

	var collision_shape: CollisionShape3D = CollisionShape3D.new()
	collision_shape.shape = shape
	body.add_child(collision_shape)

	return body


func _opening(center: float, width: float, bottom: float, height: float) -> Dictionary:
	return {
		"center": center,
		"width": width,
		"bottom": bottom,
		"height": height
	}


func _wall_x(name: String, z: float, x0: float, x1: float, openings: Array = []) -> void:
	var sorted: Array = openings.duplicate()
	sorted.sort_custom(func(a: Variant, b: Variant) -> bool:
		var da: Dictionary = a as Dictionary
		var db: Dictionary = b as Dictionary
		return float(da["center"]) < float(db["center"])
	)

	var cursor: float = x0

	for item: Variant in sorted:
		var opening_data: Dictionary = item as Dictionary
		var center: float = float(opening_data["center"])
		var width: float = float(opening_data["width"])
		var bottom: float = float(opening_data["bottom"])
		var height: float = float(opening_data["height"])
		var left: float = maxf(x0, center - width * 0.5)
		var right: float = minf(x1, center + width * 0.5)
		var top: float = bottom + height

		if left > cursor:
			_wall_x_piece(name + "_solid", z, cursor, left, 0.0, WALL_H)

		if bottom > 0.0:
			_wall_x_piece(name + "_sill", z, left, right, 0.0, bottom)

		if top < WALL_H:
			_wall_x_piece(name + "_header", z, left, right, top, WALL_H)

		cursor = right

	if cursor < x1:
		_wall_x_piece(name + "_solid", z, cursor, x1, 0.0, WALL_H)


func _wall_z(name: String, x: float, z0: float, z1: float, openings: Array = []) -> void:
	var sorted: Array = openings.duplicate()
	sorted.sort_custom(func(a: Variant, b: Variant) -> bool:
		var da: Dictionary = a as Dictionary
		var db: Dictionary = b as Dictionary
		return float(da["center"]) < float(db["center"])
	)

	var cursor: float = z0

	for item: Variant in sorted:
		var opening_data: Dictionary = item as Dictionary
		var center: float = float(opening_data["center"])
		var width: float = float(opening_data["width"])
		var bottom: float = float(opening_data["bottom"])
		var height: float = float(opening_data["height"])
		var left: float = maxf(z0, center - width * 0.5)
		var right: float = minf(z1, center + width * 0.5)
		var top: float = bottom + height

		if left > cursor:
			_wall_z_piece(name + "_solid", x, cursor, left, 0.0, WALL_H)

		if bottom > 0.0:
			_wall_z_piece(name + "_sill", x, left, right, 0.0, bottom)

		if top < WALL_H:
			_wall_z_piece(name + "_header", x, left, right, top, WALL_H)

		cursor = right

	if cursor < z1:
		_wall_z_piece(name + "_solid", x, cursor, z1, 0.0, WALL_H)


<<<<<<< Updated upstream
	create_static_box("Window Left Reveal", Vector3(0.16, height + 0.06, WALL_T + 0.20), Vector3(center - width * 0.5, y, z), WALL_INNER)
	create_static_box("Window Right Reveal", Vector3(0.16, height + 0.06, WALL_T + 0.20), Vector3(center + width * 0.5, y, z), WALL_INNER)
	create_static_box("Window Top Reveal", Vector3(width + 0.08, 0.16, WALL_T + 0.20), Vector3(center, bottom + height, z), WALL_INNER)
	create_static_box("Window Bottom Reveal", Vector3(width + 0.08, 0.16, WALL_T + 0.20), Vector3(center, bottom, z), WALL_INNER)

	create_static_box("Window Frame Top", Vector3(width, 0.08, 0.09), Vector3(center, bottom + height + 0.01, frame_z), TRIM, false)
	create_static_box("Window Frame Bottom", Vector3(width, 0.08, 0.09), Vector3(center, bottom - 0.01, frame_z), TRIM, false)
	create_static_box("Window Frame Left", Vector3(0.08, height, 0.09), Vector3(center - width * 0.5 - 0.01, y, frame_z), TRIM, false)
	create_static_box("Window Frame Right", Vector3(0.08, height, 0.09), Vector3(center + width * 0.5 + 0.01, y, frame_z), TRIM, false)
	create_static_box("Window Frame Center", Vector3(0.07, height, 0.09), Vector3(center, y, frame_z), TRIM, false)
	create_static_box("Window Sill", Vector3(width + 0.30, 0.12, 0.32), Vector3(center, bottom - 0.16, frame_z), TRIM)

func create_school_door(pos: Vector3, opens_north: bool) -> void:
	var pivot: Node3D = Node3D.new()
	pivot.name = "School Door Pivot"
	pivot.position = Vector3(pos.x - 2.00, 0, pos.z)
	add_child(pivot)

	var face: float = -1.0 if opens_north else 1.0
	var z_off: float = face * 0.070
	var trim_z: float = pos.z + face * 0.16

	create_static_box("Door Frame Top", Vector3(4.42, 0.16, 0.22), Vector3(pos.x, 4.03, trim_z), TRIM, false)
	create_static_box("Door Frame Left", Vector3(0.16, 4.06, 0.22), Vector3(pos.x - 2.12, 2.02, trim_z), TRIM, false)
	create_static_box("Door Frame Right", Vector3(0.16, 4.06, 0.22), Vector3(pos.x + 2.12, 2.02, trim_z), TRIM, false)
	create_static_box("Door Inner Left Reveal", Vector3(0.08, 3.92, 0.30), Vector3(pos.x - 2.00, 1.96, pos.z + face * 0.02), WALL_INNER, false)
	create_static_box("Door Inner Right Reveal", Vector3(0.08, 3.92, 0.30), Vector3(pos.x + 2.00, 1.96, pos.z + face * 0.02), WALL_INNER, false)
	create_static_box("Door Threshold", Vector3(4.24, 0.08, 0.46), Vector3(pos.x, 0.04, pos.z + face * 0.02), METAL, false)

	create_child_box(pivot, "Door Panel", Vector3(4.00, 3.96, 0.14), Vector3(2.00, 1.98, z_off), DOOR)
	create_child_box(pivot, "Door Inset Top", Vector3(3.12, 0.86, 0.030), Vector3(2.00, 2.12, z_off * 1.75), DOOR_DARK, false)
	create_child_box(pivot, "Door Inset Bottom", Vector3(3.12, 0.92, 0.030), Vector3(2.00, 1.02, z_off * 1.75), DOOR_DARK, false)
	create_child_box(pivot, "Door Window", Vector3(0.72, 0.82, 0.040), Vector3(2.00, 3.00, z_off * 1.85), GLASS, false)
	create_child_box(pivot, "Door Handle", Vector3(0.11, 0.22, 0.11), Vector3(3.52, 1.92, z_off * 2.05), METAL)
	create_child_box(pivot, "Door Kick Plate", Vector3(3.25, 0.16, 0.030), Vector3(2.00, 0.42, z_off * 1.88), METAL, false)

	var open_angle: float = 108.0 if opens_north else -108.0
	doors.append({
		"node": pivot,
		"open": false,
		"closed": Vector3.ZERO,
		"opened": Vector3(0, open_angle, 0)
	})

func build_hallway() -> void:
	create_static_box("Hallway Floor", Vector3(BUILDING_W - 2.0, 0.08, HALL_Z1 - HALL_Z0), Vector3(0, 0.04, 0), HALL_FLOOR)
	create_static_box("Hallway Center Band", Vector3(BUILDING_W - 4.0, 0.09, 2.15), Vector3(0, 0.095, 0), Color(0.66, 0.62, 0.48))

	add_base_trim_x(HALL_Z0 + 0.22, -HALF_W, HALF_W, [opening(0, 4.8, 0, 4.1)])
	add_base_trim_x(HALL_Z1 - 0.22, -HALF_W, HALF_W, [
		opening(-36, 4.8, 0, 4.1),
		opening(0, 4.8, 0, 4.1),
		opening(36, 4.8, 0, 4.1)
	])

	for x in range(-44, 45, 8):
		create_light_fixture(Vector3(float(x), WALL_H + 0.12, 0))

	create_locker_bank(Vector3(-42.0, 0, HALL_Z0 + 1.12), -1, 3)
	create_locker_bank(Vector3(38.0, 0, HALL_Z1 - 1.12), 1, 3)

	create_bench(Vector3(-28.0, 0, -4.30), 0)
	create_bench(Vector3(25.0, 0, -4.30), 0)
	create_bench(Vector3(-25.0, 0, 4.30), 180)

	create_water_fountain(Vector3(-45.4, 0, -4.0), 90)
	create_trash_can(Vector3(-18.0, 0, -4.82))
	create_trash_can(Vector3(34.0, 0, -4.82))
	create_trash_can(Vector3(21.0, 0, 4.82))

	create_bulletin_board(Vector3(-25, 2.45, HALL_Z0 + 0.24), false)
	create_bulletin_board(Vector3(23, 2.45, HALL_Z1 - 0.24), true)

func add_base_trim_x(z: float, x0: float, x1: float, blocked: Array) -> void:
	var cuts: Array = [x0, x1]

	for o in blocked:
		cuts.append(float(o["center"]) - float(o["width"]) * 0.5)
		cuts.append(float(o["center"]) + float(o["width"]) * 0.5)

	cuts.sort()

	for i in range(cuts.size() - 1):
		var a: float = float(cuts[i])
		var b: float = float(cuts[i + 1])
		var mid: float = (a + b) * 0.5

		if b - a <= 0.01:
			continue
		if blocked_at(mid, blocked):
			continue

		create_static_box("Base Trim", Vector3((b - a) + EPS, 0.18, 0.08), Vector3(mid, 0.34, z), TRIM)

func blocked_at(axis: float, blocked: Array) -> bool:
	for o in blocked:
		var left: float = float(o["center"]) - float(o["width"]) * 0.5
		var right: float = float(o["center"]) + float(o["width"]) * 0.5
		if axis >= left and axis <= right:
			return true
	return false

func create_locker_bank(pos: Vector3, side: int, count: int) -> void:
	var z: float = pos.z

	for i in range(count):
		var x: float = pos.x + float(i) * 1.55
		create_static_box("Locker Body", Vector3(1.25, 2.78, 0.42), Vector3(x, 1.39, z), BLUE)
		create_static_box("Locker Recess", Vector3(0.94, 2.18, 0.055), Vector3(x, 1.39, z - 0.24 * float(side)), BLUE.darkened(0.12), false)
		create_static_box("Locker Vent", Vector3(0.60, 0.045, 0.055), Vector3(x, 2.28, z - 0.27 * float(side)), METAL, false)
		create_static_box("Locker Handle", Vector3(0.06, 0.26, 0.06), Vector3(x + 0.34, 1.38, z - 0.29 * float(side)), METAL)
		create_static_box("Locker Base", Vector3(1.18, 0.10, 0.06), Vector3(x, 0.06, z - 0.28 * float(side)), TRIM)

func build_room_101_pool() -> void:
	create_static_box("Room 101 Floor", Vector3(35.5, 0.08, 26.4), Vector3(0, 0.04, -21.0), Color(0.68, 0.78, 0.80))
	create_static_box("Pool Basin", Vector3(22.0, 0.26, 11.0), Vector3(0, -0.70, -21.6), Color(0.02, 0.38, 0.60))
	create_static_box("Pool Water", Vector3(21.2, 0.08, 10.2), Vector3(0, 0.13, -21.6), WATER, false)

	create_static_box("Pool Rim North", Vector3(23.0, 0.42, 0.42), Vector3(0, 0.26, -27.25), WHITE)
	create_static_box("Pool Rim South", Vector3(23.0, 0.42, 0.42), Vector3(0, 0.26, -15.95), WHITE)
	create_static_box("Pool Rim West", Vector3(0.42, 0.42, 11.3), Vector3(-11.5, 0.26, -21.6), WHITE)
	create_static_box("Pool Rim East", Vector3(0.42, 0.42, 11.3), Vector3(11.5, 0.26, -21.6), WHITE)

	for lane in range(4):
		create_static_box("Pool Lane Divider", Vector3(0.08, 0.08, 10.0), Vector3(-6.0 + float(lane) * 4.0, 0.25, -21.6), RED, false)

	for i in range(5):
		create_static_box("Pool Starting Block", Vector3(0.95, 0.50, 0.85), Vector3(-8.0 + float(i) * 4.0, 0.32, -15.2), Color(0.82, 0.76, 0.38))

	for z in [-28.5, -25.7, -22.9, -20.1]:
		create_bench(Vector3(-13.4, 0, z), 90)

	create_static_box("Lifeguard Pole", Vector3(0.20, 2.3, 0.20), Vector3(13.2, 1.15, -15.2), METAL)
	create_static_box("Lifeguard Seat", Vector3(1.35, 0.16, 1.25), Vector3(13.2, 2.38, -15.2), RED)
	create_static_box("Lifeguard Back", Vector3(1.35, 0.90, 0.14), Vector3(13.2, 2.85, -15.85), RED)

func build_room_102_classroom() -> void:
	var x: float = -36.0
	var z: float = 21.0

	create_static_box("Room 102 Floor", Vector3(23.4, 0.08, 26.4), Vector3(x, 0.04, z), Color(0.74, 0.63, 0.48))
	create_static_box("Blackboard", Vector3(9.6, 1.9, 0.10), Vector3(x, 2.85, 33.74), Color(0.04, 0.30, 0.14))
	create_static_box("Board Tray", Vector3(9.8, 0.10, 0.16), Vector3(x, 1.84, 33.58), METAL)

	create_teacher_desk(Vector3(x, 0, 29.5), 0)

	for row in range(3):
		for col in range(3):
			create_student_desk(Vector3(x - 6.2 + float(col) * 6.2, 0, z - 4.8 + float(row) * 4.4), 0)

	create_bookshelf(Vector3(x - 10.3, 0, 29.0), 90)

func build_room_103_lab() -> void:
	var x: float = 0.0
	var z: float = 21.0

	create_static_box("Room 103 Floor", Vector3(35.5, 0.08, 26.4), Vector3(x, 0.04, z), Color(0.58, 0.70, 0.60))
	create_static_box("Lab Board", Vector3(8.4, 1.9, 0.10), Vector3(x - 4.5, 2.85, 33.74), Color(0.82, 0.86, 0.70))

	for i in range(3):
		create_lab_table(Vector3(x, 0, z - 6.5 + float(i) * 5.4))

	for i in range(5):
		create_microscope(Vector3(x - 6.0 + float(i) * 3.0, 0, z - 7.2 + float(i % 3) * 5.4))

	create_cabinet(Vector3(-14, 0, 30.2), 0, GREEN)
	create_cabinet(Vector3(14, 0, 30.2), 0, GREEN)
	create_cabinet(Vector3(-14, 0, 18.8), 180, GREEN)
	create_cabinet(Vector3(14, 0, 18.8), 180, GREEN)

func build_room_104_office() -> void:
	var x: float = 36.0

	create_static_box("Room 104 Carpet", Vector3(23.4, 0.08, 26.4), Vector3(x, 0.04, 21.0), Color(0.58, 0.35, 0.36))

	create_principal_desk(Vector3(x, 0, 28.8), 0)
	create_office_chair(Vector3(x, 0, 31.05), 0)
	create_cabinet(Vector3(x - 10.0, 0, 28.6), 90, Color(0.54, 0.54, 0.50))
	create_bookshelf(Vector3(x + 10.2, 0, 24.5), -90)
	create_office_couch(Vector3(x - 5.0, 0, 16.2), 0)

func build_pickups() -> void:
	pickup_floor("Hall Backpack", Vector3(0.9, 0.7, 0.45), -8.5, 3.4, Color(0.58, 0.14, 0.30), 1.2)
	pickup_floor("Hall Ball Block", Vector3(0.62, 0.62, 0.62), 14.0, -3.8, Color(0.76, 0.34, 0.08), 1.0)
	pickup_floor("Mop Bucket", Vector3(0.85, 0.55, 0.85), 41.0, -4.3, Color(0.20, 0.38, 0.58), 1.4)

	pickup_on_table("Book Red", Vector3(0.65, 0.14, 0.50), -35.0, 29.5, 1.09, RED, 0.6)
	pickup_on_table("Book Blue", Vector3(0.65, 0.14, 0.50), -32.0, 20.0, 0.82, BLUE, 0.6)
	pickup_on_table("Clipboard", Vector3(0.75, 0.08, 0.55), -39.5, 16.8, 0.82, Color(0.76, 0.66, 0.42), 0.5)

	pickup_on_table("Lab Sample", Vector3(0.36, 0.52, 0.36), 3.5, 24.0, 1.05, Color(0.20, 0.62, 0.38), 0.6)
	pickup_on_table("Lab Notebook", Vector3(0.72, 0.10, 0.52), -4.0, 19.5, 1.05, Color(0.18, 0.24, 0.50), 0.5)

	pickup_on_table("Office Stamp", Vector3(0.42, 0.30, 0.42), 38.4, 28.4, 1.10, RED, 0.8)
	pickup_on_table("Office Folder", Vector3(0.78, 0.08, 0.52), 34.2, 28.8, 1.10, Color(0.70, 0.56, 0.22), 0.5)

	pickup_on_table("Pool Float Board", Vector3(1.3, 0.12, 0.55), -12.0, -25.7, 0.62, Color(0.82, 0.72, 0.24), 0.7)
	pickup_on_table("Pool Towel", Vector3(1.1, 0.10, 0.55), -13.2, -22.9, 0.62, Color(0.68, 0.24, 0.28), 0.5)

func pickup_floor(n: String, size: Vector3, x: float, z: float, col: Color, mass_value: float) -> void:
	pickup_box(n, size, Vector3(x, size.y * 0.5 + 0.03, z), col, mass_value)

func pickup_on_table(n: String, size: Vector3, x: float, z: float, table_y: float, col: Color, mass_value: float) -> void:
	pickup_box(n, size, Vector3(x, table_y + size.y * 0.5 + 0.025, z), col, mass_value)

func pickup_box(n: String, size: Vector3, pos: Vector3, col: Color, mass_value: float) -> RigidBody3D:
	var body: RigidBody3D = RigidBody3D.new()
	body.name = n
	body.position = pos
	body.mass = mass_value
	body.collision_layer = 1
	body.collision_mask = 1
	add_child(body)

	var mesh_inst: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	mesh_inst.mesh = mesh
	mesh_inst.material_override = material(col)
	body.add_child(mesh_inst)

	var col_shape: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	col_shape.shape = shape
	body.add_child(col_shape)

	pickups.append(body)
	return body

func interact() -> void:
	if held != null and is_instance_valid(held):
		throw_held()
=======
func _wall_x_piece(name: String, z: float, x0: float, x1: float, y0: float, y1: float) -> void:
	if x1 <= x0 or y1 <= y0:
>>>>>>> Stashed changes
		return

	_box(
		name,
		Vector3((x0 + x1) * 0.5, (y0 + y1) * 0.5, z),
		Vector3(x1 - x0, y1 - y0, WALL_T),
		_mat("wall", Color(0.58, 0.62, 0.52))
	)


func _wall_z_piece(name: String, x: float, z0: float, z1: float, y0: float, y1: float) -> void:
	if z1 <= z0 or y1 <= y0:
		return

	_box(
		name,
		Vector3(x, (y0 + y1) * 0.5, (z0 + z1) * 0.5),
		Vector3(WALL_T, y1 - y0, z1 - z0),
		_mat("wall", Color(0.58, 0.62, 0.52))
	)


func _floor(name: String, x0: float, x1: float, z0: float, z1: float, material: Material) -> void:
	_box(
		name,
		Vector3((x0 + x1) * 0.5, -FLOOR_T * 0.5, (z0 + z1) * 0.5),
		Vector3(x1 - x0, FLOOR_T, z1 - z0),
		material
	)


func _ceiling(name: String, x0: float, x1: float, z0: float, z1: float) -> void:
	_box(
		name,
		Vector3((x0 + x1) * 0.5, WALL_H + CEIL_T * 0.5 - 0.02, (z0 + z1) * 0.5),
		Vector3(x1 - x0 + 0.22, CEIL_T, z1 - z0 + 0.22),
		_mat("ceiling", Color(0.43, 0.44, 0.36))
	)


func _build_structure() -> void:
	_floor("HallFloor", HALL_X0, HALL_X1, HALL_Z0, HALL_Z1, _mat("hall_floor", Color(0.44, 0.55, 0.53)))
	_box("HallRunner", Vector3(0.0, 0.035, 0.0), Vector3(100.0, 0.045, 1.85), _mat("runner_clean", Color(0.66, 0.61, 0.36)), false)

	_floor("PoolFloor", POOL_X0, POOL_X1, POOL_Z0, POOL_Z1, _mat("pool_floor", Color(0.43, 0.58, 0.60)))
	_floor("ClassroomFloor", CLASS_X0, CLASS_X1, ROOM_Z0, ROOM_Z1, _mat("class_floor", Color(0.54, 0.50, 0.40)))
	_floor("LabFloor", LAB_X0, LAB_X1, ROOM_Z0, ROOM_Z1, _mat("lab_floor", Color(0.34, 0.50, 0.47)))
	_floor("OfficeFloor", OFFICE_X0, OFFICE_X1, ROOM_Z0, ROOM_Z1, _mat("office_floor", Color(0.43, 0.31, 0.36)))

	_ceiling("HallCeiling", HALL_X0, HALL_X1, HALL_Z0, HALL_Z1)
	_ceiling("PoolCeiling", POOL_X0, POOL_X1, POOL_Z0, POOL_Z1)
	_ceiling("ClassroomCeiling", CLASS_X0, CLASS_X1, ROOM_Z0, ROOM_Z1)
	_ceiling("LabCeiling", LAB_X0, LAB_X1, ROOM_Z0, ROOM_Z1)
	_ceiling("OfficeCeiling", OFFICE_X0, OFFICE_X1, ROOM_Z0, ROOM_Z1)

	_wall_x("HallNorthLeftSolid", HALL_Z0, HALL_X0, POOL_X0, [])
	_wall_x("HallNorthPool", HALL_Z0, POOL_X0, POOL_X1, [
		_opening(0.0, 2.5, 0.0, 3.2),
		_opening(-15.0, 7.8, 1.35, 1.5),
		_opening(15.0, 7.8, 1.35, 1.5)
	])
	_wall_x("HallNorthRightSolid", HALL_Z0, POOL_X1, HALL_X1, [])

	_wall_x("HallSouthRooms", HALL_Z1, HALL_X0, HALL_X1, [
		_opening(-35.5, 2.5, 0.0, 3.2),
		_opening(-25.0, 6.3, 1.35, 1.5),
		_opening(0.0, 2.5, 0.0, 3.2),
		_opening(9.0, 6.3, 1.35, 1.5),
		_opening(35.5, 2.5, 0.0, 3.2),
		_opening(25.0, 6.3, 1.35, 1.5)
	])

	_wall_z("WestWall", HALL_X0, HALL_Z0, ROOM_Z1, [])
	_wall_z("EastWall", HALL_X1, HALL_Z0, ROOM_Z1, [])

	_wall_x("PoolNorthWall", POOL_Z0, POOL_X0, POOL_X1, [
		_opening(-12.0, 7.2, 1.3, 1.55),
		_opening(12.0, 7.2, 1.3, 1.55)
	])
	_wall_z("PoolWestWall", POOL_X0, POOL_Z0, POOL_Z1, [])
	_wall_z("PoolEastWall", POOL_X1, POOL_Z0, POOL_Z1, [])

	_wall_x("ClassSouthWall", ROOM_Z1, CLASS_X0, CLASS_X1, [
		_opening(-42.0, 6.8, 1.3, 1.55),
		_opening(-28.0, 6.8, 1.3, 1.55)
	])
	_wall_x("LabSouthWall", ROOM_Z1, LAB_X0, LAB_X1, [
		_opening(-8.0, 6.6, 1.3, 1.55),
		_opening(8.0, 6.6, 1.3, 1.55)
	])
	_wall_x("OfficeSouthWall", ROOM_Z1, OFFICE_X0, OFFICE_X1, [
		_opening(27.0, 6.6, 1.3, 1.55),
		_opening(42.0, 6.6, 1.3, 1.55)
	])

	_wall_z("ClassLabWall", LAB_X0, ROOM_Z0, ROOM_Z1, [])
	_wall_z("LabOfficeWall", LAB_X1, ROOM_Z0, ROOM_Z1, [])

	_make_window_x("PoolHallWindowA", HALL_Z0, -15.0, 7.8, 1.35, 1.5)
	_make_window_x("PoolHallWindowB", HALL_Z0, 15.0, 7.8, 1.35, 1.5)
	_make_window_x("ClassHallWindow", HALL_Z1, -25.0, 6.3, 1.35, 1.5)
	_make_window_x("LabHallWindow", HALL_Z1, 9.0, 6.3, 1.35, 1.5)
	_make_window_x("OfficeHallWindow", HALL_Z1, 25.0, 6.3, 1.35, 1.5)

	_make_window_x("PoolOutsideWindowA", POOL_Z0, -12.0, 7.2, 1.3, 1.55)
	_make_window_x("PoolOutsideWindowB", POOL_Z0, 12.0, 7.2, 1.3, 1.55)
	_make_window_x("ClassOutsideWindowA", ROOM_Z1, -42.0, 6.8, 1.3, 1.55)
	_make_window_x("ClassOutsideWindowB", ROOM_Z1, -28.0, 6.8, 1.3, 1.55)
	_make_window_x("LabOutsideWindowA", ROOM_Z1, -8.0, 6.6, 1.3, 1.55)
	_make_window_x("LabOutsideWindowB", ROOM_Z1, 8.0, 6.6, 1.3, 1.55)
	_make_window_x("OfficeOutsideWindowA", ROOM_Z1, 27.0, 6.6, 1.3, 1.55)
	_make_window_x("OfficeOutsideWindowB", ROOM_Z1, 42.0, 6.6, 1.3, 1.55)

	_make_door_x("Door101Pool", HALL_Z0, 0.0, true, Color(0.18, 0.28, 0.34))
	_make_door_x("Door102Classroom", HALL_Z1, -35.5, false, Color(0.23, 0.13, 0.08))
	_make_door_x("Door103Lab", HALL_Z1, 0.0, false, Color(0.18, 0.28, 0.34))
	_make_door_x("Door104Office", HALL_Z1, 35.5, false, Color(0.27, 0.14, 0.08))


func _make_window_x(name: String, z: float, center_x: float, width: float, bottom: float, height: float) -> void:
	var frame: Material = _mat("window_frame", Color(0.12, 0.16, 0.16))
	var trim: Material = _mat("window_trim", Color(0.64, 0.67, 0.59))
	var glass: Material = _mat("glass", Color(0.70, 0.84, 0.90), 0.42)

	var y: float = bottom + height * 0.5
	var top: float = bottom + height
	var front_z: float = z + 0.03
	var t: float = 0.10

	_box(name + "_Glass", Vector3(center_x, y, front_z), Vector3(width - 0.34, height - 0.20, 0.035), glass, false)
	_box(name + "_FrameL", Vector3(center_x - width * 0.5, y, front_z), Vector3(t, height + 0.10, 0.12), frame)
	_box(name + "_FrameR", Vector3(center_x + width * 0.5, y, front_z), Vector3(t, height + 0.10, 0.12), frame)
	_box(name + "_FrameT", Vector3(center_x, top, front_z), Vector3(width + 0.10, t, 0.12), frame)
	_box(name + "_FrameB", Vector3(center_x, bottom, front_z), Vector3(width + 0.10, t, 0.12), frame)
	_box(name + "_Center", Vector3(center_x, y, front_z + 0.01), Vector3(t, height, 0.13), frame)
	_box(name + "_Sill", Vector3(center_x, bottom - 0.20, front_z + 0.05), Vector3(width + 0.55, 0.10, 0.42), trim)


func _make_door_x(name: String, z: float, center_x: float, opens_north: bool, door_color: Color) -> void:
	var frame: Material = _mat("door_frame", Color(0.08, 0.10, 0.10))
	var door: Material = _mat(name + "_mat", door_color)
	var inset: Material = _mat(name + "_inset", door_color.darkened(0.25))
	var glass: Material = _mat("door_glass", Color(0.65, 0.78, 0.82), 0.48)
	var metal: Material = _mat("metal", Color(0.68, 0.65, 0.50))

	var frame_w: float = 2.55
	var frame_h: float = 3.22
	var door_w: float = 1.82
	var door_h: float = 3.02
	var side: float = -1.0 if opens_north else 1.0
	var z_panel: float = z + side * 0.10

	_box(name + "_JambL", Vector3(center_x - frame_w * 0.5, frame_h * 0.5, z), Vector3(0.14, frame_h, 0.34), frame)
	_box(name + "_JambR", Vector3(center_x + frame_w * 0.5, frame_h * 0.5, z), Vector3(0.14, frame_h, 0.34), frame)
	_box(name + "_Header", Vector3(center_x, frame_h + 0.07, z), Vector3(frame_w + 0.14, 0.14, 0.34), frame)
	_box(name + "_Threshold", Vector3(center_x, 0.04, z + side * 0.08), Vector3(frame_w, 0.08, 0.28), frame)

	var pivot: Node3D = Node3D.new()
	pivot.name = name + "_Hinge"
	pivot.position = Vector3(center_x - door_w * 0.5, 0.0, z_panel)
	add_child(pivot)

	var open_angle: float = deg_to_rad(-78.0) if opens_north else deg_to_rad(78.0)
	pivot.rotation.y = open_angle

	_box(name + "_DoorPanel", Vector3(door_w * 0.5, door_h * 0.5, 0.0), Vector3(door_w, door_h, 0.10), door, false, pivot)
	_box(name + "_LowerInset", Vector3(door_w * 0.5, 1.12, -0.058), Vector3(door_w - 0.34, 1.25, 0.035), inset, false, pivot)
	_box(name + "_Window", Vector3(door_w * 0.5, 2.45, -0.062), Vector3(0.62, 0.42, 0.035), glass, false, pivot)
	_box(name + "_KickPlate", Vector3(door_w * 0.5, 0.28, -0.065), Vector3(door_w - 0.30, 0.25, 0.035), metal, false, pivot)
	_box(name + "_Handle", Vector3(door_w - 0.25, 1.48, -0.10), Vector3(0.08, 0.28, 0.08), metal, false, pivot)

	doors.append({
		"pivot": pivot,
		"closed": 0.0,
		"open": open_angle,
		"target": open_angle
	})


func _toggle_nearest_door() -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return

	var best: Dictionary = {}
	var best_dist: float = 999.0

	for door_data: Dictionary in doors:
		var pivot: Node3D = door_data["pivot"] as Node3D
		var dist: float = camera.global_position.distance_to(pivot.global_position)
		if dist < best_dist:
			best_dist = dist
			best = door_data

	if best.is_empty() or best_dist > 4.0:
		return

<<<<<<< Updated upstream
	held.freeze = false
	held.gravity_scale = 1.0
	held.linear_velocity = (-camera.global_transform.basis.z * THROW_FORCE) + Vector3(0, 3.0, 0)
	held.angular_velocity = Vector3(randf_range(-5.5, 5.5), randf_range(-6.0, 6.0), randf_range(-5.5, 5.5))
	
	var thrown = held
	held = null
	thrown.contact_monitor = true
	thrown.max_contacts_reported = 4
	thrown.body_entered.connect(func(body):
		if body.is_in_group("npc") and body.currState == body.State.STUCK:
			body.receive_hit(thrown.linear_velocity.length())
	)
=======
	if abs(float(best["target"]) - float(best["open"])) < 0.05:
		best["target"] = float(best["closed"])
	else:
		best["target"] = float(best["open"])
>>>>>>> Stashed changes


func _build_hallway() -> void:
	var blue: Material = _mat("locker_blue", Color(0.05, 0.12, 0.34))
	var wood: Material = _mat("wood", Color(0.25, 0.13, 0.07))
	var dark: Material = _mat("dark", Color(0.03, 0.04, 0.04))
	var paper: Material = _mat("paper", Color(0.82, 0.78, 0.62))
	var board: Material = _mat("board", Color(0.27, 0.12, 0.07))

	_make_locker_bank("HallLockersA", Vector3(-47.0, 0.0, -5.0), 0.0, 3, blue)
	_make_locker_bank("HallLockersB", Vector3(44.0, 0.0, 5.0), PI, 3, blue)

	_make_bench("BenchA", Vector3(-38.0, 0.0, 4.35), 0.0, wood)
	_make_bench("BenchB", Vector3(38.0, 0.0, -4.35), PI, wood)

	_cylinder("TrashHallA", Vector3(-24.0, 0.45, 4.8), 0.42, 0.9, dark)
	_cylinder("TrashHallB", Vector3(24.0, 0.45, -4.8), 0.42, 0.9, dark)

	_make_water_fountain("WaterFountain", Vector3(-52.0, 0.0, -2.2), PI * 0.5)

	_box("BulletinA", Vector3(-43.0, 2.1, -5.86), Vector3(6.6, 1.25, 0.06), board, false)
	_box("BulletinA_Paper1", Vector3(-44.4, 2.2, -5.91), Vector3(0.8, 0.55, 0.035), paper, false)
	_box("BulletinA_Paper2", Vector3(-42.8, 1.95, -5.91), Vector3(0.7, 0.45, 0.035), _mat("redpaper", Color(0.55, 0.10, 0.08)), false)
	_box("BulletinA_Paper3", Vector3(-41.4, 2.15, -5.91), Vector3(0.85, 0.50, 0.035), paper, false)

	_box("BulletinB", Vector3(45.0, 2.1, 5.86), Vector3(6.3, 1.25, 0.06), board, false)
	_box("BulletinB_Paper1", Vector3(43.9, 2.2, 5.91), Vector3(0.8, 0.55, 0.035), paper, false)
	_box("BulletinB_Paper2", Vector3(46.0, 1.95, 5.91), Vector3(0.85, 0.45, 0.035), _mat("bluepaper", Color(0.12, 0.18, 0.48)), false)

	for x_value: float in [-44.0, -28.0, -12.0, 4.0, 20.0, 36.0]:
		_make_light("HallLight" + str(x_value), Vector3(x_value, WALL_H - 0.08, 0.0))


func _make_locker_bank(name: String, pos: Vector3, rot_y: float, count: int, mat: Material) -> void:
	var node: Node3D = Node3D.new()
	node.name = name
	node.position = pos
	node.rotation.y = rot_y
	add_child(node)

	for i: int in range(count):
		var x: float = float(i) * 0.78
		_box(name + "_Body" + str(i), Vector3(x, 1.15, 0.0), Vector3(0.68, 2.3, 0.48), mat, true, node)
		_box(name + "_Inset" + str(i), Vector3(x, 1.18, -0.255), Vector3(0.48, 1.75, 0.03), _mat("locker_shadow", Color(0.02, 0.04, 0.14)), false, node)
		_box(name + "_Vent" + str(i), Vector3(x, 1.95, -0.28), Vector3(0.32, 0.035, 0.035), _mat("metal", Color(0.65, 0.63, 0.48)), false, node)
		_box(name + "_Handle" + str(i), Vector3(x + 0.21, 1.12, -0.285), Vector3(0.055, 0.28, 0.04), _mat("metal", Color(0.65, 0.63, 0.48)), false, node)


func _make_bench(name: String, pos: Vector3, rot_y: float, mat: Material) -> void:
	var node: Node3D = Node3D.new()
	node.name = name
	node.position = pos
	node.rotation.y = rot_y
	add_child(node)

	_box(name + "_Seat", Vector3(0.0, 0.55, 0.0), Vector3(3.4, 0.20, 0.55), mat, true, node)
	_box(name + "_Back", Vector3(0.0, 1.08, 0.34), Vector3(3.4, 0.75, 0.18), mat, true, node)

	for x: float in [-1.35, 1.35]:
		_box(name + "_LegA" + str(x), Vector3(x, 0.25, -0.18), Vector3(0.16, 0.50, 0.16), mat, true, node)
		_box(name + "_LegB" + str(x), Vector3(x, 0.25, 0.20), Vector3(0.16, 0.50, 0.16), mat, true, node)


func _make_water_fountain(name: String, pos: Vector3, rot_y: float) -> void:
	var node: Node3D = Node3D.new()
	node.name = name
	node.position = pos
	node.rotation.y = rot_y
	add_child(node)

	var metal: Material = _mat("fountain", Color(0.47, 0.53, 0.52))
	var dark: Material = _mat("dark", Color(0.03, 0.04, 0.04))

	_box(name + "_Back", Vector3(0.0, 0.8, 0.0), Vector3(0.7, 1.5, 0.16), metal, true, node)
	_box(name + "_Bowl", Vector3(0.0, 0.72, -0.22), Vector3(0.72, 0.24, 0.42), metal, true, node)
	_box(name + "_Spout", Vector3(0.0, 0.92, -0.46), Vector3(0.15, 0.08, 0.12), dark, true, node)


func _build_pool() -> void:
	var water: Material = _mat("water", Color(0.18, 0.55, 0.68), 0.62)
	var tile: Material = _mat("pool_tile", Color(0.72, 0.74, 0.64))
	var red: Material = _mat("lane", Color(0.55, 0.08, 0.06))
	var bench: Material = _mat("pool_bench", Color(0.34, 0.40, 0.38))

	_box("PoolWater", Vector3(0.0, 0.05, -20.0), Vector3(22.0, 0.10, 13.0), water, false)
	_box("PoolBorderN", Vector3(0.0, 0.15, -26.75), Vector3(23.6, 0.14, 0.45), tile)
	_box("PoolBorderS", Vector3(0.0, 0.15, -13.25), Vector3(23.6, 0.14, 0.45), tile)
	_box("PoolBorderW", Vector3(-11.75, 0.15, -20.0), Vector3(0.45, 0.14, 13.8), tile)
	_box("PoolBorderE", Vector3(11.75, 0.15, -20.0), Vector3(0.45, 0.14, 13.8), tile)

	for x_value: float in [-7.0, 0.0, 7.0]:
		_box("PoolLane" + str(x_value), Vector3(x_value, 0.18, -20.0), Vector3(0.08, 0.025, 12.3), red, false)

	_make_bench("PoolBenchA", Vector3(-23.0, 0.0, -15.0), PI * 0.5, bench)
	_make_bench("PoolBenchB", Vector3(23.0, 0.0, -25.0), -PI * 0.5, bench)
	_make_locker_bank("PoolLockers", Vector3(-27.8, 0.0, -28.0), PI * 0.5, 4, _mat("pool_locker", Color(0.08, 0.20, 0.24)))
	_make_lifeguard_chair(Vector3(15.0, 0.0, -13.0))


func _make_lifeguard_chair(pos: Vector3) -> void:
	var node: Node3D = Node3D.new()
	node.name = "LifeguardChair"
	node.position = pos
	add_child(node)

	var mat: Material = _mat("lifeguard", Color(0.84, 0.75, 0.48))
	var metal: Material = _mat("metal", Color(0.65, 0.63, 0.48))

	_box("LifeguardSeat", Vector3(0.0, 2.15, 0.0), Vector3(1.1, 0.20, 0.85), mat, true, node)
	_box("LifeguardBack", Vector3(0.0, 2.55, 0.42), Vector3(1.1, 0.65, 0.16), mat, true, node)

	for x: float in [-0.45, 0.45]:
		for z: float in [-0.28, 0.28]:
			_box("LifeguardLeg", Vector3(x, 1.05, z), Vector3(0.12, 2.1, 0.12), metal, true, node)

	_box("LifeguardStep1", Vector3(0.0, 0.8, -0.7), Vector3(1.15, 0.10, 0.15), metal, true, node)
	_box("LifeguardStep2", Vector3(0.0, 1.25, -0.7), Vector3(1.15, 0.10, 0.15), metal, true, node)


func _build_classroom() -> void:
	var desk: Material = _mat("desk", Color(0.30, 0.17, 0.10))
	var desk_shadow: Material = _mat("desk_shadow", Color(0.14, 0.08, 0.04))
	var chair: Material = _mat("chair", Color(0.06, 0.12, 0.34))
	var metal: Material = _mat("dark_metal", Color(0.09, 0.10, 0.10))
	var board: Material = _mat("blackboard", Color(0.02, 0.12, 0.07))

	_box("ClassBlackboard", Vector3(CLASS_X0 + 0.16, 2.35, 21.0), Vector3(0.10, 1.45, 9.0), board, false)
	_box("ClassBoardTray", Vector3(CLASS_X0 + 0.25, 1.55, 21.0), Vector3(0.18, 0.08, 9.3), _mat("chalk", Color(0.70, 0.72, 0.65)), false)

	_make_big_desk("TeacherDesk", Vector3(CLASS_X0 + 5.0, 0.0, 21.0), PI * 0.5, desk)

	var xs: Array[float] = [-44.0, -37.0, -30.0, -23.0]
	var zs: Array[float] = [13.0, 19.0, 25.0]
	var index: int = 0

	for z_value: float in zs:
		for x_value: float in xs:
			_make_student_desk("StudentDesk" + str(index), Vector3(x_value, 0.0, z_value), 0.0, desk, desk_shadow, chair, metal)
			index += 1

	_make_bookshelf("ClassBookshelf", Vector3(CLASS_X1 - 1.2, 0.0, 30.0), 0.0)
	_box("ClassPosterA", Vector3(-43.0, 2.35, ROOM_Z0 + 0.16), Vector3(1.5, 0.80, 0.05), _mat("poster_red", Color(0.55, 0.10, 0.08)), false)
	_box("ClassPosterB", Vector3(-38.0, 2.45, ROOM_Z0 + 0.16), Vector3(2.2, 0.90, 0.05), _mat("poster_yellow", Color(0.75, 0.66, 0.22)), false)


func _make_student_desk(name: String, pos: Vector3, rot_y: float, desk_mat: Material, desk_shadow: Material, chair_mat: Material, metal_mat: Material) -> void:
	var node: Node3D = Node3D.new()
	node.name = name
	node.position = pos
	node.rotation.y = rot_y
	add_child(node)

	_box(name + "_Top", Vector3(0.0, 0.72, 0.0), Vector3(1.9, 0.16, 1.0), desk_mat, true, node)
	_box(name + "_Bin", Vector3(0.0, 0.52, 0.18), Vector3(1.65, 0.25, 0.65), desk_shadow, true, node)

	for x: float in [-0.75, 0.75]:
		for z: float in [-0.35, 0.35]:
			_box(name + "_Leg", Vector3(x, 0.33, z), Vector3(0.09, 0.66, 0.09), metal_mat, true, node)

	_box(name + "_ChairSeat", Vector3(0.0, 0.45, 1.05), Vector3(0.95, 0.15, 0.75), chair_mat, true, node)
	_box(name + "_ChairBack", Vector3(0.0, 0.92, 1.42), Vector3(0.95, 0.75, 0.15), chair_mat, true, node)


func _make_big_desk(name: String, pos: Vector3, rot_y: float, mat: Material) -> void:
	var node: Node3D = Node3D.new()
	node.name = name
	node.position = pos
	node.rotation.y = rot_y
	add_child(node)

	_box(name + "_Top", Vector3(0.0, 0.85, 0.0), Vector3(3.2, 0.20, 1.25), mat, true, node)
	_box(name + "_Front", Vector3(0.0, 0.45, 0.47), Vector3(3.2, 0.70, 0.18), mat, true, node)
	_box(name + "_LegL", Vector3(-1.35, 0.38, -0.35), Vector3(0.22, 0.75, 0.22), mat, true, node)
	_box(name + "_LegR", Vector3(1.35, 0.38, -0.35), Vector3(0.22, 0.75, 0.22), mat, true, node)


func _make_bookshelf(name: String, pos: Vector3, rot_y: float) -> void:
	var node: Node3D = Node3D.new()
	node.name = name
	node.position = pos
	node.rotation.y = rot_y
	add_child(node)

	var wood: Material = _mat("shelf", Color(0.20, 0.10, 0.05))
	var red: Material = _mat("book_red", Color(0.50, 0.08, 0.07))
	var blue: Material = _mat("book_blue", Color(0.05, 0.10, 0.45))

	_box(name + "_Back", Vector3(0.0, 1.25, 0.0), Vector3(3.0, 2.5, 0.32), wood, true, node)

	for y: float in [0.55, 1.20, 1.85]:
		_box(name + "_Shelf" + str(y), Vector3(0.0, y, -0.25), Vector3(3.1, 0.10, 0.42), wood, true, node)

	for i: int in range(12):
		var bx: float = -1.25 + float(i) * 0.23
		var by: float = 0.86 + float(i % 3) * 0.62
		var book_mat: Material = red if i % 2 == 0 else blue
		_box(name + "_Book" + str(i), Vector3(bx, by, -0.52), Vector3(0.14, 0.42, 0.18), book_mat, false, node)


func _build_lab() -> void:
	var table: Material = _mat("lab_table", Color(0.04, 0.16, 0.13))
	var cabinet: Material = _mat("lab_cabinet", Color(0.12, 0.24, 0.15))
	var black: Material = _mat("black", Color(0.02, 0.025, 0.025))

	for z_value: float in [14.0, 23.0]:
		_make_lab_table("LabTableA" + str(z_value), Vector3(-7.0, 0.0, z_value), table)
		_make_lab_table("LabTableB" + str(z_value), Vector3(7.0, 0.0, z_value), table)

	_make_lab_cabinet("LabCabinetLeft", Vector3(LAB_X0 + 1.2, 0.0, 30.0), cabinet)
	_make_lab_cabinet("LabCabinetRight", Vector3(LAB_X1 - 1.2, 0.0, 30.0), cabinet)

	_box("LabStorage", Vector3(0.0, 1.45, ROOM_Z1 - 0.28), Vector3(5.0, 2.5, 0.42), cabinet)
	_box("LabBoard", Vector3(LAB_X0 + 0.16, 2.25, 19.0), Vector3(0.08, 1.25, 7.0), _mat("lab_board", Color(0.02, 0.12, 0.08)), false)

	_make_microscope("Microscope1", Vector3(-7.0, 1.03, 14.0), black)
	_make_microscope("Microscope2", Vector3(7.0, 1.03, 14.0), black)
	_make_microscope("Microscope3", Vector3(-7.0, 1.03, 23.0), black)
	_make_microscope("Microscope4", Vector3(7.0, 1.03, 23.0), black)

	for i: int in range(8):
		var bottle_x: float = -2.0 + float(i) * 0.55
		var bottle_color: Color = Color(0.65, 0.10 + 0.05 * float(i % 3), 0.10)
		_cylinder("ChemBottle" + str(i), Vector3(bottle_x, 1.1, ROOM_Z1 - 0.62), 0.11, 0.48, _mat("chem" + str(i), bottle_color), false)


func _make_lab_table(name: String, pos: Vector3, mat: Material) -> void:
	var node: Node3D = Node3D.new()
	node.name = name
	node.position = pos
	add_child(node)

	_box(name + "_Top", Vector3(0.0, 0.86, 0.0), Vector3(5.0, 0.20, 1.7), mat, true, node)
	_box(name + "_Base", Vector3(0.0, 0.43, 0.0), Vector3(4.5, 0.70, 1.2), _mat("lab_base", Color(0.03, 0.10, 0.08)), true, node)
	_box(name + "_Sink", Vector3(1.5, 1.00, 0.0), Vector3(0.75, 0.07, 0.55), _mat("sink", Color(0.50, 0.55, 0.55)), false, node)


func _make_lab_cabinet(name: String, pos: Vector3, mat: Material) -> void:
	var node: Node3D = Node3D.new()
	node.name = name
	node.position = pos
	add_child(node)

	_box(name + "_Body", Vector3(0.0, 1.05, 0.0), Vector3(1.8, 2.1, 0.75), mat, true, node)
	_box(name + "_HandleL", Vector3(-0.2, 1.15, -0.40), Vector3(0.07, 0.32, 0.04), _mat("metal", Color(0.65, 0.63, 0.48)), false, node)
	_box(name + "_HandleR", Vector3(0.2, 1.15, -0.40), Vector3(0.07, 0.32, 0.04), _mat("metal", Color(0.65, 0.63, 0.48)), false, node)


func _make_microscope(name: String, pos: Vector3, mat: Material) -> void:
	var node: Node3D = Node3D.new()
	node.name = name
	node.position = pos
	add_child(node)

	_box(name + "_Base", Vector3(0.0, 0.04, 0.0), Vector3(0.55, 0.08, 0.40), mat, false, node)
	_box(name + "_Arm", Vector3(0.05, 0.30, 0.0), Vector3(0.10, 0.52, 0.10), mat, false, node)
	_box(name + "_Head", Vector3(0.18, 0.58, -0.06), Vector3(0.35, 0.16, 0.16), mat, false, node)
	_box(name + "_Stage", Vector3(0.0, 0.24, 0.0), Vector3(0.42, 0.05, 0.30), mat, false, node)


func _build_office() -> void:
	var desk: Material = _mat("office_desk", Color(0.25, 0.12, 0.08))
	var chair: Material = _mat("office_chair", Color(0.04, 0.05, 0.08))
	var couch: Material = _mat("couch", Color(0.05, 0.10, 0.31))
	var file: Material = _mat("file_cabinet", Color(0.24, 0.28, 0.30))

	_make_big_desk("PrincipalDesk", Vector3(36.0, 0.0, 28.5), PI, desk)
	_make_office_chair("PrincipalChair", Vector3(36.0, 0.0, 30.6), PI, chair)
	_make_couch("OfficeCouch", Vector3(49.0, 0.0, 18.0), -PI * 0.5, couch)
	_make_filing("OfficeFiling", Vector3(50.5, 0.0, 29.5), -PI * 0.5, file)
	_make_bookshelf("OfficeShelf", Vector3(20.0, 0.0, 30.5), 0.0)

	_box("OfficePicture", Vector3(36.0, 2.35, ROOM_Z0 + 0.16), Vector3(4.2, 1.0, 0.05), _mat("picture", Color(0.27, 0.18, 0.10)), false)
	_box("OfficePaperA", Vector3(35.2, 0.98, 28.1), Vector3(0.75, 0.05, 0.50), _mat("paper", Color(0.82, 0.78, 0.62)), false)
	_box("OfficePaperB", Vector3(36.3, 1.00, 28.0), Vector3(0.65, 0.05, 0.42), _mat("paper2", Color(0.72, 0.78, 0.86)), false)


func _make_office_chair(name: String, pos: Vector3, rot_y: float, mat: Material) -> void:
	var node: Node3D = Node3D.new()
	node.name = name
	node.position = pos
	node.rotation.y = rot_y
	add_child(node)

	_box(name + "_Seat", Vector3(0.0, 0.60, 0.0), Vector3(1.1, 0.18, 1.0), mat, true, node)
	_box(name + "_Back", Vector3(0.0, 1.15, 0.45), Vector3(1.1, 1.0, 0.18), mat, true, node)
	_box(name + "_Post", Vector3(0.0, 0.32, 0.0), Vector3(0.18, 0.64, 0.18), mat, true, node)


func _make_couch(name: String, pos: Vector3, rot_y: float, mat: Material) -> void:
	var node: Node3D = Node3D.new()
	node.name = name
	node.position = pos
	node.rotation.y = rot_y
	add_child(node)

	_box(name + "_Seat", Vector3(0.0, 0.55, 0.0), Vector3(4.2, 0.35, 1.15), mat, true, node)
	_box(name + "_Back", Vector3(0.0, 1.15, 0.55), Vector3(4.2, 1.1, 0.35), mat, true, node)
	_box(name + "_ArmL", Vector3(-2.25, 0.9, 0.0), Vector3(0.35, 1.0, 1.25), mat, true, node)
	_box(name + "_ArmR", Vector3(2.25, 0.9, 0.0), Vector3(0.35, 1.0, 1.25), mat, true, node)


func _make_filing(name: String, pos: Vector3, rot_y: float, mat: Material) -> void:
	var node: Node3D = Node3D.new()
	node.name = name
	node.position = pos
	node.rotation.y = rot_y
	add_child(node)

	_box(name + "_Body", Vector3(0.0, 1.05, 0.0), Vector3(1.2, 2.1, 0.85), mat, true, node)

	for y: float in [0.65, 1.15, 1.65]:
		_box(name + "_Drawer" + str(y), Vector3(0.0, y, -0.45), Vector3(1.0, 0.32, 0.04), _mat("drawer", Color(0.18, 0.21, 0.23)), false, node)
		_box(name + "_Handle" + str(y), Vector3(0.0, y, -0.50), Vector3(0.40, 0.05, 0.04), _mat("metal", Color(0.65, 0.63, 0.48)), false, node)


func _build_pickups() -> void:
	_pickup_box("PickupNotebookHall", Vector3(-12.0, 0.35, 1.8), Vector3(0.65, 0.08, 0.45), _mat("book_blue", Color(0.05, 0.10, 0.45)), 0.35)
	_pickup_box("PickupFolderHall", Vector3(18.0, 0.35, -1.7), Vector3(0.75, 0.06, 0.50), _mat("folder", Color(0.74, 0.62, 0.20)), 0.25)
	_pickup_box("PickupBackpackClass", Vector3(-24.0, 0.50, 28.0), Vector3(0.90, 0.55, 0.75), _mat("backpack", Color(0.16, 0.07, 0.24)), 0.90)
	_pickup_cylinder("PickupBottleHall", Vector3(26.5, 0.35, 1.7), 0.18, 0.65, _mat("bottle", Color(0.45, 0.70, 0.80), 0.65), 0.25)
	_pickup_box("PickupClipboardOffice", Vector3(35.8, 1.12, 28.1), Vector3(0.75, 0.08, 0.50), _mat("clipboard", Color(0.44, 0.27, 0.12)), 0.35)
	_pickup_box("PickupPoolKickboard", Vector3(8.0, 0.35, -13.2), Vector3(1.2, 0.12, 0.55), _mat("kickboard", Color(0.78, 0.65, 0.12)), 0.50)
	_pickup_box("PickupEraserClass", Vector3(CLASS_X0 + 5.0, 1.05, 20.5), Vector3(0.45, 0.12, 0.22), _mat("eraser", Color(0.12, 0.12, 0.10)), 0.25)
	_pickup_box("PickupBeakerLab", Vector3(4.0, 1.20, 14.0), Vector3(0.34, 0.34, 0.34), _mat("beaker", Color(0.60, 0.82, 0.85), 0.55), 0.25)


func _make_light(name: String, pos: Vector3) -> void:
	var frame: Material = _mat("light_frame", Color(0.04, 0.04, 0.035))
	var glow: Material = _mat("light_glow", Color(1.0, 0.92, 0.55))

	_box(name + "_Frame", pos, Vector3(1.6, 0.06, 0.42), frame, false)
	_box(name + "_Panel", pos + Vector3(0.0, -0.04, 0.0), Vector3(1.24, 0.035, 0.28), glow, false)

	var light: OmniLight3D = OmniLight3D.new()
<<<<<<< Updated upstream
	light.name = "Ceiling Light"
	light.position = pos
	light.omni_range = range_value
	light.light_energy = energy
	light.light_color = col
	light.shadow_enabled = false
=======
	light.name = name + "_Omni"
	light.position = pos + Vector3(0.0, -0.35, 0.0)
	light.light_color = Color(1.0, 0.92, 0.62)
	light.light_energy = 0.65
	light.omni_range = 11.0
>>>>>>> Stashed changes
	add_child(light)


func _build_lights() -> void:
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.name = "SoftSun"
	sun.rotation_degrees = Vector3(-45.0, -35.0, 0.0)
	sun.light_energy = 0.75
	sun.light_color = Color(0.96, 0.96, 0.84)
	add_child(sun)

	var world_env: WorldEnvironment = WorldEnvironment.new()
	world_env.name = "WorldEnvironment"

	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.58, 0.68, 0.78)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.65, 0.68, 0.58)
	environment.ambient_light_energy = 0.82
	environment.fog_enabled = true
	environment.fog_density = 0.012
	environment.fog_light_color = Color(0.60, 0.64, 0.56)

	world_env.environment = environment
	add_child(world_env)

	var light_positions: Array[Vector3] = [
		Vector3(0.0, WALL_H - 0.08, -20.0),
		Vector3(-36.0, WALL_H - 0.08, 20.0),
		Vector3(0.0, WALL_H - 0.08, 20.0),
		Vector3(36.0, WALL_H - 0.08, 20.0)
	]

	for pos: Vector3 in light_positions:
		_make_light("RoomLight" + str(pos.x) + "_" + str(pos.z), pos)
