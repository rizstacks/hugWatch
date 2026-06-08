extends Node3D

# ──────────────────────────────────────────────────────────────────────────────
#  CONSTANTS  (unchanged from original — do not touch)
# ──────────────────────────────────────────────────────────────────────────────
const WALL_H: float = 4.6
const WALL_T: float = 0.28
const CEIL_T: float = 0.22
const FLOOR_T: float = 0.18

const HALL_X0: float = -54.0
const HALL_X1: float =  54.0
const HALL_Z0: float =  -6.0
const HALL_Z1: float =   6.0

const POOL_X0: float = -30.0
const POOL_X1: float =  30.0
const POOL_Z0: float = -34.0
const POOL_Z1: float =  -6.0

const CLASS_X0: float = -54.0
const CLASS_X1: float = -18.0
const LAB_X0:   float = -18.0
const LAB_X1:   float =  18.0
const OFFICE_X0: float = 18.0
const OFFICE_X1: float = 54.0
const ROOM_Z0:  float =   6.0
const ROOM_Z1:  float =  34.0

# ──────────────────────────────────────────────────────────────────────────────
#  STATE
# ──────────────────────────────────────────────────────────────────────────────
var mats: Dictionary = {}
var doors: Array[Dictionary] = []

# ──────────────────────────────────────────────────────────────────────────────
#  LIFECYCLE
# ──────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	build_map()


func _process(delta: float) -> void:
	for i: int in range(doors.size()):
		var door_data: Dictionary = doors[i]
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

# ──────────────────────────────────────────────────────────────────────────────
#  MATERIAL CACHE
# ──────────────────────────────────────────────────────────────────────────────
func _mat(id: String, color: Color, alpha: float = 1.0) -> StandardMaterial3D:
	var key: String = id + "_" + color.to_html(false) + "_" + str(alpha)
	if mats.has(key):
		return mats[key] as StandardMaterial3D

	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(color.r, color.g, color.b, alpha)
	material.roughness   = 0.95
	material.metallic    = 0.0

	if alpha < 1.0:
		material.transparency          = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.alpha_scissor_threshold = 0.02

	mats[key] = material
	return material

# ──────────────────────────────────────────────────────────────────────────────
#  PRIMITIVE BUILDERS  (unchanged signatures — gameplay scripts untouched)
# ──────────────────────────────────────────────────────────────────────────────
func _box(name: String, pos: Vector3, size: Vector3, material: Material,
		  collision: bool = true, parent: Node = null) -> Node3D:
	var node: Node3D
	if collision:
		node = StaticBody3D.new()
	else:
		node = Node3D.new()

	node.name     = name
	node.position = pos

	var target_parent: Node = self if parent == null else parent
	target_parent.add_child(node)

	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size

	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.mesh              = mesh
	mesh_instance.material_override = material
	node.add_child(mesh_instance)

	if collision:
		var shape: BoxShape3D = BoxShape3D.new()
		shape.size = size

		var collision_shape: CollisionShape3D = CollisionShape3D.new()
		collision_shape.shape = shape
		node.add_child(collision_shape)

	return node


func _cylinder(name: String, pos: Vector3, radius: float, height: float,
			   material: Material, collision: bool = true, parent: Node = null) -> Node3D:
	var node: Node3D
	if collision:
		node = StaticBody3D.new()
	else:
		node = Node3D.new()

	node.name     = name
	node.position = pos

	var target_parent: Node = self if parent == null else parent
	target_parent.add_child(node)

	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius      = radius
	mesh.bottom_radius   = radius
	mesh.height          = height
	mesh.radial_segments = 8

	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.mesh              = mesh
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


func _pickup_box(name: String, pos: Vector3, size: Vector3, material: Material,
				 mass_value: float = 0.45) -> RigidBody3D:
	var body: RigidBody3D = RigidBody3D.new()
	body.name          = name
	body.position      = pos
	body.mass          = mass_value
	body.gravity_scale = 1.0
	body.linear_damp   = 0.2
	body.angular_damp  = 0.2
	body.add_to_group("pickup")
	add_child(body)

	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size

	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.mesh              = mesh
	mesh_instance.material_override = material
	body.add_child(mesh_instance)

	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size

	var collision_shape: CollisionShape3D = CollisionShape3D.new()
	collision_shape.shape = shape
	body.add_child(collision_shape)

	return body


func _pickup_cylinder(name: String, pos: Vector3, radius: float, height: float,
					  material: Material, mass_value: float = 0.35) -> RigidBody3D:
	var body: RigidBody3D = RigidBody3D.new()
	body.name          = name
	body.position      = pos
	body.mass          = mass_value
	body.gravity_scale = 1.0
	body.linear_damp   = 0.2
	body.angular_damp  = 0.2
	body.add_to_group("pickup")
	add_child(body)

	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius      = radius
	mesh.bottom_radius   = radius
	mesh.height          = height
	mesh.radial_segments = 8

	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.mesh              = mesh
	mesh_instance.material_override = material
	body.add_child(mesh_instance)

	var shape: CylinderShape3D = CylinderShape3D.new()
	shape.radius = radius
	shape.height = height

	var collision_shape: CollisionShape3D = CollisionShape3D.new()
	collision_shape.shape = shape
	body.add_child(collision_shape)

	return body

# ──────────────────────────────────────────────────────────────────────────────
#  WALL / OPENING HELPERS  (unchanged)
# ──────────────────────────────────────────────────────────────────────────────
func _opening(center: float, width: float, bottom: float, height: float) -> Dictionary:
	return { "center": center, "width": width, "bottom": bottom, "height": height }


func _wall_x(name: String, z: float, x0: float, x1: float, openings: Array = []) -> void:
	var sorted: Array = openings.duplicate()
	sorted.sort_custom(func(a: Variant, b: Variant) -> bool:
		return float((a as Dictionary)["center"]) < float((b as Dictionary)["center"])
	)
	var cursor: float = x0
	var segment_index: int = 0
	for item: Variant in sorted:
		var d: Dictionary = item as Dictionary
		var center: float = float(d["center"])
		var width:  float = float(d["width"])
		var bottom: float = float(d["bottom"])
		var height: float = float(d["height"])
		var left:  float  = maxf(x0, center - width * 0.5)
		var right: float  = minf(x1, center + width * 0.5)
		var top:   float  = bottom + height

		if left > cursor:
			_wall_x_piece(name + "_solid_" + str(segment_index), z, cursor, left, 0.0, WALL_H)
			segment_index += 1
		if bottom > 0.0:
			_wall_x_piece(name + "_sill_" + str(segment_index), z, left, right, 0.0, bottom)
			segment_index += 1
		if top < WALL_H:
			_wall_x_piece(name + "_header_" + str(segment_index), z, left, right, top, WALL_H)
			segment_index += 1

		cursor = maxf(cursor, right)

	if cursor < x1:
		_wall_x_piece(name + "_solid_" + str(segment_index), z, cursor, x1, 0.0, WALL_H)


func _wall_z(name: String, x: float, z0: float, z1: float, openings: Array = []) -> void:
	var sorted: Array = openings.duplicate()
	sorted.sort_custom(func(a: Variant, b: Variant) -> bool:
		return float((a as Dictionary)["center"]) < float((b as Dictionary)["center"])
	)
	var cursor: float = z0
	var segment_index: int = 0
	for item: Variant in sorted:
		var d: Dictionary = item as Dictionary
		var center: float = float(d["center"])
		var width:  float = float(d["width"])
		var bottom: float = float(d["bottom"])
		var height: float = float(d["height"])
		var left:  float  = maxf(z0, center - width * 0.5)
		var right: float  = minf(z1, center + width * 0.5)
		var top:   float  = bottom + height

		if left > cursor:
			_wall_z_piece(name + "_solid_" + str(segment_index), x, cursor, left, 0.0, WALL_H)
			segment_index += 1
		if bottom > 0.0:
			_wall_z_piece(name + "_sill_" + str(segment_index), x, left, right, 0.0, bottom)
			segment_index += 1
		if top < WALL_H:
			_wall_z_piece(name + "_header_" + str(segment_index), x, left, right, top, WALL_H)
			segment_index += 1

		cursor = maxf(cursor, right)

	if cursor < z1:
		_wall_z_piece(name + "_solid_" + str(segment_index), x, cursor, z1, 0.0, WALL_H)


func _wall_x_piece(name: String, z: float, x0: float, x1: float, y0: float, y1: float) -> void:
	if x1 <= x0 or y1 <= y0:
		return
	# Retro-horror wall: slightly yellowed institutional green
	_box(name, Vector3((x0 + x1) * 0.5, (y0 + y1) * 0.5, z),
		 Vector3(x1 - x0, y1 - y0, WALL_T),
		 _mat("wall", Color(0.52, 0.57, 0.44)))


func _wall_z_piece(name: String, x: float, z0: float, z1: float, y0: float, y1: float) -> void:
	if z1 <= z0 or y1 <= y0:
		return
	_box(name, Vector3(x, (y0 + y1) * 0.5, (z0 + z1) * 0.5),
		 Vector3(WALL_T, y1 - y0, z1 - z0),
		 _mat("wall", Color(0.52, 0.57, 0.44)))


func _floor(name: String, x0: float, x1: float, z0: float, z1: float, material: Material) -> void:
	_box(name, Vector3((x0 + x1) * 0.5, -FLOOR_T * 0.5, (z0 + z1) * 0.5),
		 Vector3(x1 - x0, FLOOR_T, z1 - z0), material)


func _ceiling(name: String, x0: float, x1: float, z0: float, z1: float) -> void:
	_box(name, Vector3((x0 + x1) * 0.5, WALL_H + CEIL_T * 0.5 - 0.02, (z0 + z1) * 0.5),
		 Vector3(x1 - x0 + 0.22, CEIL_T, z1 - z0 + 0.22),
		 _mat("ceiling", Color(0.38, 0.39, 0.30)))

# ──────────────────────────────────────────────────────────────────────────────
#  STRUCTURE  (layout unchanged, palette upgraded, baseboard trim added)
# ──────────────────────────────────────────────────────────────────────────────
func _build_structure() -> void:
	# Floors — slightly grimier tones
	_floor("HallFloor",      HALL_X0,  HALL_X1,  HALL_Z0, HALL_Z1,
		   _mat("hall_floor",  Color(0.38, 0.48, 0.46)))
	_floor("PoolFloor",      POOL_X0,  POOL_X1,  POOL_Z0, POOL_Z1,
		   _mat("pool_floor",  Color(0.36, 0.50, 0.53)))
	_floor("ClassroomFloor", CLASS_X0, CLASS_X1, ROOM_Z0, ROOM_Z1,
		   _mat("class_floor", Color(0.46, 0.42, 0.32)))
	_floor("LabFloor",       LAB_X0,   LAB_X1,   ROOM_Z0, ROOM_Z1,
		   _mat("lab_floor",   Color(0.28, 0.42, 0.38)))
	_floor("OfficeFloor",    OFFICE_X0, OFFICE_X1, ROOM_Z0, ROOM_Z1,
		   _mat("office_floor", Color(0.36, 0.24, 0.28)))

	# Hallway runner — worn carpet strip
	_box("HallRunner",    Vector3(0.0, 0.05, 0.0),  Vector3(106.0, 0.07, 1.7),
		 _mat("runner", Color(0.58, 0.52, 0.28)), false)
	# Worn centre seam on runner
	_box("HallRunnerSeam", Vector3(0.0, 0.06, 0.0), Vector3(106.0, 0.02, 0.06),
		 _mat("runner_seam", Color(0.42, 0.38, 0.18)), false)

	# Baseboard trim along every major wall — low poly detail pass
	var bh: float = 0.18   # baseboard height
	var bt: float = 0.06   # baseboard thickness
	var bm: Material = _mat("baseboard", Color(0.22, 0.24, 0.18))
	# Hall north/south baseboards
	_box("BaseHallN", Vector3(0.0, bh * 0.5, HALL_Z0 + bt * 0.5),
		 Vector3(HALL_X1 - HALL_X0, bh, bt), bm, false)
	_box("BaseHallS", Vector3(0.0, bh * 0.5, HALL_Z1 - bt * 0.5),
		 Vector3(HALL_X1 - HALL_X0, bh, bt), bm, false)
	# Outer room south walls
	_box("BaseClassS", Vector3((CLASS_X0 + CLASS_X1) * 0.5, bh * 0.5, ROOM_Z1 - bt * 0.5),
		 Vector3(CLASS_X1 - CLASS_X0, bh, bt), bm, false)
	_box("BaseLabS",   Vector3((LAB_X0 + LAB_X1) * 0.5,     bh * 0.5, ROOM_Z1 - bt * 0.5),
		 Vector3(LAB_X1 - LAB_X0, bh, bt), bm, false)
	_box("BaseOffS",   Vector3((OFFICE_X0 + OFFICE_X1) * 0.5, bh * 0.5, ROOM_Z1 - bt * 0.5),
		 Vector3(OFFICE_X1 - OFFICE_X0, bh, bt), bm, false)

	# Ceilings
	_ceiling("HallCeiling",      HALL_X0,   HALL_X1,   HALL_Z0, HALL_Z1)
	_ceiling("PoolCeiling",      POOL_X0,   POOL_X1,   POOL_Z0, POOL_Z1)
	_ceiling("ClassroomCeiling", CLASS_X0,  CLASS_X1,  ROOM_Z0, ROOM_Z1)
	_ceiling("LabCeiling",       LAB_X0,    LAB_X1,    ROOM_Z0, ROOM_Z1)
	_ceiling("OfficeCeiling",    OFFICE_X0, OFFICE_X1, ROOM_Z0, ROOM_Z1)

	# Ceiling edge shadow strip — sells the drop-tile look
	var cm: Material = _mat("ceil_edge", Color(0.18, 0.18, 0.14))
	_box("CeilEdgeHallE", Vector3(HALL_X1 - 0.06, WALL_H - 0.05, 0.0),
		 Vector3(0.12, 0.14, HALL_Z1 - HALL_Z0 + 0.1), cm, false)
	_box("CeilEdgeHallW", Vector3(HALL_X0 + 0.06, WALL_H - 0.05, 0.0),
		 Vector3(0.12, 0.14, HALL_Z1 - HALL_Z0 + 0.1), cm, false)

	# Walls — identical call-sites, palette already in _wall_x_piece
	_wall_x("HallNorthLeftSolid", HALL_Z0, HALL_X0, POOL_X0, [])
	_wall_x("HallNorthPool",      HALL_Z0, POOL_X0, POOL_X1, [
		_opening(0.0, 2.5, 0.0, 3.2),
		_opening(-15.0, 7.8, 1.35, 1.5),
		_opening( 15.0, 7.8, 1.35, 1.5)
	])
	_wall_x("HallNorthRightSolid", HALL_Z0, POOL_X1, HALL_X1, [])

	_wall_x("HallSouthRooms", HALL_Z1, HALL_X0, HALL_X1, [
		_opening(-35.5, 2.5, 0.0, 3.2),
		_opening(-25.0, 6.3, 1.35, 1.5),
		_opening(  0.0, 2.5, 0.0, 3.2),
		_opening(  9.0, 6.3, 1.35, 1.5),
		_opening( 35.5, 2.5, 0.0, 3.2),
		_opening( 25.0, 6.3, 1.35, 1.5)
	])

	_wall_z("WestWall", HALL_X0, HALL_Z0, ROOM_Z1, [])
	_wall_z("EastWall", HALL_X1, HALL_Z0, ROOM_Z1, [])

	_wall_x("PoolNorthWall", POOL_Z0, POOL_X0, POOL_X1, [
		_opening(-12.0, 7.2, 1.3, 1.55),
		_opening( 12.0, 7.2, 1.3, 1.55)
	])
	_wall_z("PoolWestWall", POOL_X0, POOL_Z0, POOL_Z1, [])
	_wall_z("PoolEastWall", POOL_X1, POOL_Z0, POOL_Z1, [])

	_wall_x("ClassSouthWall", ROOM_Z1, CLASS_X0, CLASS_X1, [
		_opening(-42.0, 6.8, 1.3, 1.55),
		_opening(-28.0, 6.8, 1.3, 1.55)
	])
	_wall_x("LabSouthWall",   ROOM_Z1, LAB_X0,   LAB_X1, [
		_opening(-8.0, 6.6, 1.3, 1.55),
		_opening( 8.0, 6.6, 1.3, 1.55)
	])
	_wall_x("OfficeSouthWall", ROOM_Z1, OFFICE_X0, OFFICE_X1, [
		_opening(27.0, 6.6, 1.3, 1.55),
		_opening(42.0, 6.6, 1.3, 1.55)
	])

	_wall_z("ClassLabWall",   LAB_X0,  ROOM_Z0, ROOM_Z1, [])
	_wall_z("LabOfficeWall",  LAB_X1,  ROOM_Z0, ROOM_Z1, [])

	# Windows
	_make_window_x("PoolHallWindowA",   HALL_Z0, -15.0, 7.8, 1.35, 1.5)
	_make_window_x("PoolHallWindowB",   HALL_Z0,  15.0, 7.8, 1.35, 1.5)
	_make_window_x("ClassHallWindow",   HALL_Z1, -25.0, 6.3, 1.35, 1.5)
	_make_window_x("LabHallWindow",     HALL_Z1,   9.0, 6.3, 1.35, 1.5)
	_make_window_x("OfficeHallWindow",  HALL_Z1,  25.0, 6.3, 1.35, 1.5)
	_make_window_x("PoolOutsideWindowA",  POOL_Z0, -12.0, 7.2, 1.3, 1.55)
	_make_window_x("PoolOutsideWindowB",  POOL_Z0,  12.0, 7.2, 1.3, 1.55)
	_make_window_x("ClassOutsideWindowA", ROOM_Z1, -42.0, 6.8, 1.3, 1.55)
	_make_window_x("ClassOutsideWindowB", ROOM_Z1, -28.0, 6.8, 1.3, 1.55)
	_make_window_x("LabOutsideWindowA",   ROOM_Z1,  -8.0, 6.6, 1.3, 1.55)
	_make_window_x("LabOutsideWindowB",   ROOM_Z1,   8.0, 6.6, 1.3, 1.55)
	_make_window_x("OfficeOutsideWindowA", ROOM_Z1, 27.0, 6.6, 1.3, 1.55)
	_make_window_x("OfficeOutsideWindowB", ROOM_Z1, 42.0, 6.6, 1.3, 1.55)

	# Doors
	_make_door_x("Door101Pool",      HALL_Z0,  0.0,    true,  Color(0.10, 0.18, 0.24))
	_make_door_x("Door102Classroom", HALL_Z1, -35.5,   false, Color(0.18, 0.10, 0.06))
	_make_door_x("Door103Lab",       HALL_Z1,  0.0,    false, Color(0.10, 0.18, 0.24))
	_make_door_x("Door104Office",    HALL_Z1,  35.5,   false, Color(0.20, 0.10, 0.06))

	# Room name signs above doors (thin plates)
	var sign_mat: Material = _mat("sign_bg", Color(0.06, 0.06, 0.05))
	var sign_txt: Material = _mat("sign_txt", Color(0.78, 0.72, 0.48))
	# Pool sign
	_box("SignPool",    Vector3(0.0,   3.8, HALL_Z0 - 0.18), Vector3(2.2, 0.30, 0.04), sign_mat, false)
	_box("SignPoolTxt", Vector3(0.0,   3.8, HALL_Z0 - 0.21), Vector3(1.85, 0.16, 0.03), sign_txt, false)
	# Classroom sign
	_box("SignClass",    Vector3(-35.5, 3.8, HALL_Z1 + 0.18), Vector3(2.4, 0.30, 0.04), sign_mat, false)
	_box("SignClassTxt", Vector3(-35.5, 3.8, HALL_Z1 + 0.21), Vector3(2.0, 0.16, 0.03), sign_txt, false)
	# Lab sign
	_box("SignLab",    Vector3(0.0,   3.8, HALL_Z1 + 0.18), Vector3(2.0, 0.30, 0.04), sign_mat, false)
	_box("SignLabTxt", Vector3(0.0,   3.8, HALL_Z1 + 0.21), Vector3(1.65, 0.16, 0.03), sign_txt, false)
	# Office sign
	_box("SignOffice",    Vector3(35.5, 3.8, HALL_Z1 + 0.18), Vector3(2.4, 0.30, 0.04), sign_mat, false)
	_box("SignOfficeTxt", Vector3(35.5, 3.8, HALL_Z1 + 0.21), Vector3(2.0, 0.16, 0.03), sign_txt, false)


# ──────────────────────────────────────────────────────────────────────────────
#  WINDOW  (upgraded: darker tinted glass, heavier frame)
# ──────────────────────────────────────────────────────────────────────────────
func _make_window_x(name: String, z: float, center_x: float,
					width: float, bottom: float, height: float) -> void:
	var frame: Material = _mat("window_frame", Color(0.08, 0.10, 0.10))
	var trim:  Material = _mat("window_trim",  Color(0.52, 0.55, 0.46))
	var glass: Material = _mat("glass",        Color(0.50, 0.68, 0.74), 0.38)

	var y:       float = bottom + height * 0.5
	var top:     float = bottom + height
	var front_z: float = z + 0.03
	var t:       float = 0.12   # frame thickness (slightly beefier)

	# Glass pane
	_box(name + "_Glass",   Vector3(center_x, y, front_z),
		 Vector3(width - 0.38, height - 0.24, 0.04), glass, false)
	# Cross divider
	_box(name + "_DivH",   Vector3(center_x, y, front_z + 0.01),
		 Vector3(width - 0.38, t * 0.5, 0.05), frame, false)
	_box(name + "_DivV",   Vector3(center_x, y, front_z + 0.01),
		 Vector3(t * 0.5, height - 0.24, 0.05), frame, false)
	# Frame sides
	_box(name + "_FrameL", Vector3(center_x - width * 0.5, y, front_z),
		 Vector3(t, height + 0.12, 0.14), frame)
	_box(name + "_FrameR", Vector3(center_x + width * 0.5, y, front_z),
		 Vector3(t, height + 0.12, 0.14), frame)
	_box(name + "_FrameT", Vector3(center_x, top,    front_z),
		 Vector3(width + 0.12, t, 0.14), frame)
	_box(name + "_FrameB", Vector3(center_x, bottom, front_z),
		 Vector3(width + 0.12, t, 0.14), frame)
	# Sill — protruding ledge
	_box(name + "_Sill",   Vector3(center_x, bottom - 0.22, front_z + 0.06),
		 Vector3(width + 0.60, 0.10, 0.50), trim)
	# Sill nose bevel (thin strip at front edge)
	_box(name + "_SillNose", Vector3(center_x, bottom - 0.27, front_z + 0.30),
		 Vector3(width + 0.60, 0.06, 0.04), frame, false)

# ──────────────────────────────────────────────────────────────────────────────
#  DOOR  (tighter frame to eliminate wall gaps)
# ──────────────────────────────────────────────────────────────────────────────
func _make_door_x(name: String, z: float, center_x: float,
				  opens_north: bool, door_color: Color) -> void:
	var frame:  Material = _mat("door_frame",   Color(0.06, 0.08, 0.08))
	var door:   Material = _mat(name + "_mat",  door_color)
	var inset:  Material = _mat(name + "_ins",  door_color.darkened(0.30))
	var glass:  Material = _mat("door_glass",   Color(0.50, 0.64, 0.70), 0.45)
	var metal:  Material = _mat("metal_handle", Color(0.56, 0.54, 0.40))

	var frame_w: float = 2.55
	var frame_h: float = 3.22
	var door_w:  float = 1.82
	var door_h:  float = 3.02
	var side:    float = -1.0 if opens_north else 1.0
	var z_panel: float = z + side * 0.10

	# Jambs — sized to overlap wall fully (WALL_T + 0.04 deep)
	_box(name + "_JambL",    Vector3(center_x - frame_w * 0.5, frame_h * 0.5, z),
		 Vector3(0.16, frame_h, WALL_T + 0.04), frame)
	_box(name + "_JambR",    Vector3(center_x + frame_w * 0.5, frame_h * 0.5, z),
		 Vector3(0.16, frame_h, WALL_T + 0.04), frame)
	_box(name + "_Header",   Vector3(center_x, frame_h + 0.08, z),
		 Vector3(frame_w + 0.16, 0.16, WALL_T + 0.04), frame)
	_box(name + "_Threshold", Vector3(center_x, 0.04, z + side * 0.09),
		 Vector3(frame_w, 0.08, 0.30), frame)
	# Tiny stop-bead to fill the hinge-side gap
	_box(name + "_StopH",    Vector3(center_x - door_w * 0.5 + 0.02, door_h * 0.5, z_panel),
		 Vector3(0.04, door_h, 0.04), frame, false)

	# Pivot / swing
	var pivot: Node3D = Node3D.new()
	pivot.name     = name + "_Hinge"
	pivot.position = Vector3(center_x - door_w * 0.5, 0.0, z_panel)
	add_child(pivot)

	var open_angle: float = deg_to_rad(-78.0) if opens_north else deg_to_rad(78.0)
	pivot.rotation.y = 0.0

	# Door panel — slightly raised insets for low-poly detail
	_box(name + "_Panel",      Vector3(door_w * 0.5, door_h * 0.5, 0.0),
		 Vector3(door_w, door_h, 0.10), door, false, pivot)
	# Upper raised rail
	_box(name + "_RailTop",    Vector3(door_w * 0.5, door_h - 0.22, -0.055),
		 Vector3(door_w - 0.08, 0.10, 0.025), inset, false, pivot)
	# Lower panel inset
	_box(name + "_LowerInset", Vector3(door_w * 0.5, 1.05, -0.057),
		 Vector3(door_w - 0.34, 1.30, 0.035), inset, false, pivot)
	# Mid rail
	_box(name + "_RailMid",    Vector3(door_w * 0.5, 1.74, -0.055),
		 Vector3(door_w - 0.08, 0.08, 0.025), inset, false, pivot)
	# Window
	_box(name + "_Window",     Vector3(door_w * 0.5, 2.48, -0.062),
		 Vector3(0.64, 0.44, 0.035), glass, false, pivot)
	# Kick plate
	_box(name + "_KickPlate",  Vector3(door_w * 0.5, 0.26, -0.065),
		 Vector3(door_w - 0.28, 0.26, 0.035), metal, false, pivot)
	# Handle bar + backplate
	_box(name + "_Handle",     Vector3(door_w - 0.22, 1.46, -0.10),
		 Vector3(0.08, 0.30, 0.08), metal, false, pivot)
	_box(name + "_HandlePlate", Vector3(door_w - 0.22, 1.50, -0.062),
		 Vector3(0.14, 0.42, 0.025), inset, false, pivot)

	doors.append({
		"pivot":  pivot,
		"closed": 0.0,
		"open":   open_angle,
		"target": 0.0
	})


func _toggle_nearest_door() -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return

	var best_index: int = -1
	var best_dist: float = 999.0

	for i: int in range(doors.size()):
		var door_data: Dictionary = doors[i]
		var pivot: Node3D = door_data["pivot"] as Node3D
		var dist: float = camera.global_position.distance_to(pivot.global_position)
		if dist < best_dist:
			best_dist = dist
			best_index = i

	if best_index == -1 or best_dist > 4.0:
		return

	var best: Dictionary = doors[best_index]
	if absf(float(best["target"]) - float(best["open"])) < 0.05:
		best["target"] = float(best["closed"])
	else:
		best["target"] = float(best["open"])
	doors[best_index] = best

# ──────────────────────────────────────────────────────────────────────────────
#  HALLWAY  (richer lockers, bulletin boards, room signs, trash cans)
# ──────────────────────────────────────────────────────────────────────────────
func _build_hallway() -> void:
	var blue:  Material = _mat("locker_blue",  Color(0.04, 0.10, 0.28))
	var wood:  Material = _mat("wood",         Color(0.22, 0.11, 0.06))
	var dark:  Material = _mat("dark",         Color(0.03, 0.03, 0.03))
	var paper: Material = _mat("paper",        Color(0.80, 0.76, 0.58))
	var board: Material = _mat("board",        Color(0.22, 0.10, 0.05))

	# Locker banks — pushed flush to walls (z = ±(WALL_T/2 + 0.24))
	_make_locker_bank("HallLockersA", Vector3(-47.0, 0.0, HALL_Z0 + WALL_T * 0.5 + 0.32), 0.0,   4, blue)
	_make_locker_bank("HallLockersB", Vector3( 44.0, 0.0, HALL_Z1 - WALL_T * 0.5 - 0.32), PI,    4, blue)
	_make_locker_bank("HallLockersC", Vector3(-20.0, 0.0, HALL_Z0 + WALL_T * 0.5 + 0.32), 0.0,   3, blue)
	_make_locker_bank("HallLockersD", Vector3( 14.0, 0.0, HALL_Z1 - WALL_T * 0.5 - 0.32), PI,    3, blue)

	# Benches — kept, slightly repositioned for better spacing
	_make_bench("BenchA", Vector3(-36.0, 0.0, HALL_Z1 - 1.2), 0.0, wood)
	_make_bench("BenchB", Vector3( 36.0, 0.0, HALL_Z0 + 1.2), 0.0,  wood)

	# Trash cans (cylindrical, low poly)
	_make_trash_can("TrashHallA", Vector3(-24.0, 0.0, HALL_Z1 - 0.7))
	_make_trash_can("TrashHallB", Vector3( 24.0, 0.0, HALL_Z0 + 0.7))
	_make_trash_can("TrashHallC", Vector3(  4.0, 0.0, HALL_Z0 + 0.7))

	# Water fountain (flush to west wall)
	_make_water_fountain("WaterFountain", Vector3(HALL_X0 + 0.42, 0.0, -2.2), -PI * 0.5)

	# Bulletin boards — thicker, with layered papers
	_make_bulletin_board("BulletinA", Vector3(-43.0, 2.2, HALL_Z0 + 0.10))
	_make_bulletin_board("BulletinB", Vector3( 45.0, 2.2, HALL_Z1 - 0.10), false)

	# Ceiling lights
	var light_xs: Array[float] = [-48.0, -32.0, -16.0, 0.0, 16.0, 32.0, 48.0]
	for x_value: float in light_xs:
		_make_light("HallLight" + str(x_value), Vector3(x_value, WALL_H - 0.08, 0.0))

	# Scuff marks on floor (dark strips near lockers — cheap atmosphere)
	var scuff: Material = _mat("scuff", Color(0.18, 0.18, 0.16))
	_box("ScuffA", Vector3(-47.0, 0.011, HALL_Z0 + 0.9), Vector3(3.5, 0.01, 0.18), scuff, false)
	_box("ScuffB", Vector3( 44.0, 0.011, HALL_Z1 - 0.9), Vector3(3.5, 0.01, 0.18), scuff, false)


func _make_trash_can(name: String, pos: Vector3) -> void:
	var node: Node3D = Node3D.new()
	node.name     = name
	node.position = pos
	add_child(node)

	var body: Material = _mat("trash_body", Color(0.06, 0.07, 0.07))
	var lid:  Material = _mat("trash_lid",  Color(0.10, 0.11, 0.10))
	var bag:  Material = _mat("trash_bag",  Color(0.04, 0.04, 0.04))

	# Body (tapered via two boxes)
	_box(name + "_Lower", Vector3(0.0, 0.30, 0.0), Vector3(0.52, 0.60, 0.52), body, true, node)
	_box(name + "_Upper", Vector3(0.0, 0.72, 0.0), Vector3(0.56, 0.24, 0.56), body, true, node)
	# Rim
	_box(name + "_Rim",   Vector3(0.0, 0.86, 0.0), Vector3(0.60, 0.06, 0.60), lid, false, node)
	# Bag peek
	_box(name + "_Bag",   Vector3(0.0, 0.80, 0.0), Vector3(0.44, 0.05, 0.44), bag, false, node)


func _make_bulletin_board(name: String, pos: Vector3, flip: bool = false) -> void:
	var node: Node3D = Node3D.new()
	node.name     = name
	node.position = pos
	node.rotation.y = PI if flip else 0.0
	add_child(node)

	var board: Material = _mat("board",      Color(0.22, 0.10, 0.05))
	var frame: Material = _mat("bb_frame",   Color(0.08, 0.08, 0.07))
	var paper: Material = _mat("paper",      Color(0.80, 0.76, 0.58))
	var red_p: Material = _mat("redpaper",   Color(0.50, 0.08, 0.06))
	var blu_p: Material = _mat("bluepaper",  Color(0.08, 0.14, 0.44))
	var yel_p: Material = _mat("yelpaper",   Color(0.65, 0.58, 0.18))

	# Board surface
	_box(name + "_Surf",  Vector3(0.0, 0.0, 0.0), Vector3(7.0, 1.40, 0.06), board, false, node)
	# Frame — four borders
	_box(name + "_FrmT",  Vector3(0.0,  0.72, 0.0), Vector3(7.20, 0.10, 0.09), frame, false, node)
	_box(name + "_FrmB",  Vector3(0.0, -0.72, 0.0), Vector3(7.20, 0.10, 0.09), frame, false, node)
	_box(name + "_FrmL",  Vector3(-3.55, 0.0, 0.0), Vector3(0.10, 1.60, 0.09), frame, false, node)
	_box(name + "_FrmR",  Vector3( 3.55, 0.0, 0.0), Vector3(0.10, 1.60, 0.09), frame, false, node)

	# Scattered papers
	_box(name + "_P1",  Vector3(-2.6,  0.20, -0.05), Vector3(1.0, 0.60, 0.03), paper, false, node)
	_box(name + "_P2",  Vector3(-1.2, -0.10, -0.05), Vector3(0.80, 0.48, 0.03), red_p, false, node)
	_box(name + "_P3",  Vector3( 0.2,  0.25, -0.05), Vector3(1.1, 0.58, 0.03), paper, false, node)
	_box(name + "_P4",  Vector3( 1.8, -0.05, -0.05), Vector3(0.90, 0.50, 0.03), yel_p, false, node)
	_box(name + "_P5",  Vector3( 2.8,  0.30, -0.05), Vector3(0.85, 0.42, 0.03), blu_p, false, node)
	_box(name + "_P6",  Vector3(-0.5, -0.30, -0.05), Vector3(0.70, 0.38, 0.03), red_p, false, node)


# ──────────────────────────────────────────────────────────────────────────────
#  LOCKER  (more geometry: vent slats, handle, number plate, dent detail)
# ──────────────────────────────────────────────────────────────────────────────
func _make_locker_bank(name: String, pos: Vector3, rot_y: float,
					   count: int, mat: Material) -> void:
	var node: Node3D = Node3D.new()
	node.name        = name
	node.position    = pos
	node.rotation.y  = rot_y
	add_child(node)

	var shadow: Material = _mat("locker_shadow", Color(0.01, 0.02, 0.08))
	var metal:  Material = _mat("lck_metal",     Color(0.55, 0.52, 0.38))
	var plate:  Material = _mat("lck_plate",     Color(0.62, 0.60, 0.44))
	var hinge:  Material = _mat("lck_hinge",     Color(0.30, 0.28, 0.20))

	for i: int in range(count):
		var x: float = float(i) * 0.80

		# Main body
		_box(name + "_Body"  + str(i), Vector3(x, 1.18, 0.0),   Vector3(0.70, 2.36, 0.50), mat,    true, node)
		# Door inset (shadow)
		_box(name + "_Inset" + str(i), Vector3(x, 1.20, -0.26), Vector3(0.52, 1.90, 0.02), shadow, false, node)
		# Vent slats (3 slats near top)
		for sv: int in range(3):
			_box(name + "_Vent" + str(i) + "_" + str(sv),
				 Vector3(x, 2.18 - float(sv) * 0.08, -0.27),
				 Vector3(0.36, 0.025, 0.025), metal, false, node)
		# Handle — L-shaped: vertical bar + pull knob
		_box(name + "_HndV" + str(i), Vector3(x + 0.22, 1.18, -0.29),
			 Vector3(0.055, 0.32, 0.04), metal, false, node)
		_box(name + "_HndH" + str(i), Vector3(x + 0.22, 1.00, -0.31),
			 Vector3(0.055, 0.055, 0.08), metal, false, node)
		# Number plate
		_box(name + "_NumPl" + str(i), Vector3(x - 0.14, 2.10, -0.27),
			 Vector3(0.18, 0.14, 0.02), plate, false, node)
		# Hinge strip (left edge)
		_box(name + "_HingeStrip" + str(i), Vector3(x - 0.32, 1.20, -0.26),
			 Vector3(0.04, 1.80, 0.025), hinge, false, node)
		# Separation gap (thin dark strip between units)
		if i > 0:
			_box(name + "_Gap" + str(i), Vector3(x - 0.395, 1.18, 0.0),
				 Vector3(0.02, 2.36, 0.50), shadow, false, node)


# ──────────────────────────────────────────────────────────────────────────────
#  BENCH  (slatted seat, angled legs)
# ──────────────────────────────────────────────────────────────────────────────
func _make_bench(name: String, pos: Vector3, rot_y: float, mat: Material) -> void:
	var node: Node3D = Node3D.new()
	node.name       = name
	node.position   = pos
	node.rotation.y = rot_y
	add_child(node)

	var dark: Material = _mat("bench_dark", Color(0.10, 0.06, 0.03))

	# Three seat slats
	for si: int in range(3):
		_box(name + "_Slat" + str(si),
			 Vector3(0.0, 0.52, -0.14 + float(si) * 0.14),
			 Vector3(3.5, 0.07, 0.10), mat, true, node)

	# Backrest slats
	for bi: int in range(2):
		_box(name + "_Back" + str(bi),
			 Vector3(0.0, 0.88 + float(bi) * 0.26, 0.30),
			 Vector3(3.5, 0.07, 0.10), mat, true, node)

	# Seat base (collision filler under slats)
	_box(name + "_SeatFill", Vector3(0.0, 0.35, 0.0), Vector3(3.5, 0.38, 0.44), dark, true, node)

	# Legs — two frames (each an H shape)
	var leg_xs: Array[float] = [-1.45, 1.45]
	for lx: float in leg_xs:
		# Front leg
		_box(name + "_LegF" + str(lx), Vector3(lx, 0.22, -0.18),
			 Vector3(0.12, 0.44, 0.12), dark, true, node)
		# Rear leg
		_box(name + "_LegR" + str(lx), Vector3(lx, 0.22,  0.22),
			 Vector3(0.12, 0.44, 0.12), dark, true, node)
		# Cross brace
		_box(name + "_Brace" + str(lx), Vector3(lx, 0.18, 0.02),
			 Vector3(0.12, 0.10, 0.38), dark, true, node)

	# Backrest support posts
	for lx: float in leg_xs:
		_box(name + "_BSup" + str(lx), Vector3(lx, 0.78, 0.32),
			 Vector3(0.12, 0.60, 0.12), dark, true, node)


# ──────────────────────────────────────────────────────────────────────────────
#  WATER FOUNTAIN  (more detail: basin, spout arm, drain)
# ──────────────────────────────────────────────────────────────────────────────
func _make_water_fountain(name: String, pos: Vector3, rot_y: float) -> void:
	var node: Node3D = Node3D.new()
	node.name       = name
	node.position   = pos
	node.rotation.y = rot_y
	add_child(node)

	var metal: Material = _mat("fountain",     Color(0.40, 0.46, 0.44))
	var dark:  Material = _mat("fountain_drk", Color(0.06, 0.07, 0.07))
	var drain: Material = _mat("fountain_drn", Color(0.12, 0.14, 0.14))

	# Pedestal
	_box(name + "_Ped",    Vector3(0.0, 0.45, 0.0),   Vector3(0.60, 0.90, 0.20), metal, true, node)
	# Body flare
	_box(name + "_Flare",  Vector3(0.0, 0.84, 0.0),   Vector3(0.66, 0.10, 0.22), metal, true, node)
	# Basin
	_box(name + "_Basin",  Vector3(0.0, 0.76, -0.18), Vector3(0.68, 0.20, 0.40), metal, true, node)
	# Basin interior (dark)
	_box(name + "_BsnIn",  Vector3(0.0, 0.82, -0.20), Vector3(0.52, 0.08, 0.32), dark,  false, node)
	# Drain dot
	_box(name + "_Drain",  Vector3(0.0, 0.74, -0.24), Vector3(0.08, 0.04, 0.08), drain, false, node)
	# Spout arm
	_box(name + "_SpArm",  Vector3(0.0, 0.96, -0.36), Vector3(0.12, 0.06, 0.18), metal, false, node)
	_box(name + "_SpNoz",  Vector3(0.0, 0.99, -0.46), Vector3(0.07, 0.10, 0.07), dark,  false, node)
	# Push button
	_box(name + "_Btn",    Vector3(0.20, 0.85, -0.12), Vector3(0.07, 0.07, 0.07), dark, false, node)

# ──────────────────────────────────────────────────────────────────────────────
#  LIGHT FIXTURE  (fluorescent tube look)
# ──────────────────────────────────────────────────────────────────────────────
func _make_light(name: String, pos: Vector3) -> void:
	var frame: Material = _mat("light_frame", Color(0.06, 0.06, 0.05))
	var glow:  Material = _mat("light_glow",  Color(0.96, 0.90, 0.52))
	var chain: Material = _mat("light_chain", Color(0.08, 0.09, 0.08))

	# Housing box
	_box(name + "_Frame",  pos, Vector3(1.65, 0.07, 0.46), frame, false)
	# Diffuser panel
	_box(name + "_Panel",  pos + Vector3(0.0, -0.045, 0.0),
		 Vector3(1.30, 0.03, 0.32), glow, false)
	# Two tube segments
	_box(name + "_TubeA",  pos + Vector3(-0.30, -0.05, 0.0),
		 Vector3(0.50, 0.025, 0.06), glow, false)
	_box(name + "_TubeB",  pos + Vector3( 0.30, -0.05, 0.0),
		 Vector3(0.50, 0.025, 0.06), glow, false)
	# Mounting chain (tiny)
	_box(name + "_Chain",  pos + Vector3(0.0, 0.06, 0.0),
		 Vector3(0.04, 0.10, 0.04), chain, false)

	var light: OmniLight3D = OmniLight3D.new()
	light.name         = name + "_Omni"
	light.position     = pos + Vector3(0.0, -0.30, 0.0)
	light.light_color  = Color(1.0, 0.90, 0.60)
	light.light_energy = 0.60
	light.omni_range   = 11.0
	add_child(light)

# ──────────────────────────────────────────────────────────────────────────────
#  POOL ROOM  (pool 101 — improved tile border, benches, lockers, chair)
# ──────────────────────────────────────────────────────────────────────────────
func _build_pool() -> void:
	var water:  Material = _mat("water",      Color(0.16, 0.50, 0.64), 0.60)
	var tile:   Material = _mat("pool_tile",  Color(0.64, 0.66, 0.56))
	var grout:  Material = _mat("grout",      Color(0.28, 0.30, 0.26))
	var red:    Material = _mat("lane",       Color(0.52, 0.06, 0.04))
	var blue_l: Material = _mat("lane_blue",  Color(0.06, 0.12, 0.40))
	var bench:  Material = _mat("pool_bench", Color(0.28, 0.34, 0.32))

	# Pool water surface
	_box("PoolWater", Vector3(0.0, -0.06, -20.0), Vector3(22.0, 0.08, 13.4), water, false)

	# Pool surround — thicker tile borders with grout lines
	var bw: float = 0.55
	_box("PoolBorderN",  Vector3(0.0, 0.16, -26.9),  Vector3(23.5, 0.16, bw),  tile)
	_box("PoolBorderS",  Vector3(0.0, 0.16, -13.1),  Vector3(23.5, 0.16, bw),  tile)
	_box("PoolBorderW",  Vector3(-11.9, 0.16, -20.0), Vector3(bw, 0.16, 14.2), tile)
	_box("PoolBorderE",  Vector3( 11.9, 0.16, -20.0), Vector3(bw, 0.16, 14.2), tile)

	# Grout border inset lines
	_box("PoolGroutN",   Vector3(0.0, 0.18, -26.62),  Vector3(23.0, 0.025, 0.02), grout, false)
	_box("PoolGroutS",   Vector3(0.0, 0.18, -13.38),  Vector3(23.0, 0.025, 0.02), grout, false)

	# Deck edge strip (low lip around pool)
	var lip: Material = _mat("pool_lip", Color(0.72, 0.74, 0.64))
	_box("PoolDeckN",  Vector3(0.0, 0.22, -27.0),  Vector3(24.0, 0.06, 0.18), lip, false)
	_box("PoolDeckS",  Vector3(0.0, 0.22, -13.0),  Vector3(24.0, 0.06, 0.18), lip, false)
	_box("PoolDeckW",  Vector3(-12.0, 0.22, -20.0), Vector3(0.18, 0.06, 14.5), lip, false)
	_box("PoolDeckE",  Vector3( 12.0, 0.22, -20.0), Vector3(0.18, 0.06, 14.5), lip, false)

	# Lane lines
	var lane_xs: Array[float] = [-7.0, 0.0, 7.0]
	for x_value: float in lane_xs:
		_box("PoolLane" + str(x_value), Vector3(x_value, 0.005, -20.0),
			 Vector3(0.10, 0.025, 13.4), red, false)
	# Blue lane separators (thinner, between red)
	var blue_xs: Array[float] = [-5.25, -1.75, 1.75, 5.25]
	for bx: float in blue_xs:
		_box("PoolBlueLane" + str(bx), Vector3(bx, 0.006, -20.0),
			 Vector3(0.06, 0.020, 13.4), blue_l, false)

	# Depth markers on deck
	var depth: Material = _mat("depth_txt", Color(0.14, 0.14, 0.12))
	_box("DepthA", Vector3(-10.5, 0.19, -14.2), Vector3(0.45, 0.02, 0.25), depth, false)
	_box("DepthB", Vector3( 10.5, 0.19, -14.2), Vector3(0.45, 0.02, 0.25), depth, false)

	# Benches
	_make_bench("PoolBenchA", Vector3(-24.0, 0.0, -15.2), PI * 0.5, bench)
	_make_bench("PoolBenchB", Vector3( 24.0, 0.0, -24.8), -PI * 0.5, bench)

	# Lockers flush to west wall
	_make_locker_bank("PoolLockers", Vector3(POOL_X0 + 0.50, 0.0, -28.5), PI * 0.5, 5,
					  _mat("pool_locker", Color(0.06, 0.16, 0.20)))

	# Lifeguard chair
	_make_lifeguard_chair(Vector3(15.0, 0.0, -11.8))

	# Pool equipment box (kickboards / float storage)
	_make_equipment_bin("PoolEquipBin", Vector3(-21.5, 0.0, -28.5))

	# Overhead lights for pool, reduced to avoid overexposure
	for px: float in [-10.0, 10.0]:
		_make_light("PoolLight" + str(px), Vector3(px, WALL_H - 0.08, -20.0))


func _make_equipment_bin(name: String, pos: Vector3) -> void:
	var node: Node3D = Node3D.new()
	node.name     = name
	node.position = pos
	add_child(node)

	var bin: Material = _mat("equip_bin", Color(0.58, 0.52, 0.20))
	var rim: Material = _mat("equip_rim", Color(0.26, 0.24, 0.10))

	_box(name + "_Body",  Vector3(0.0, 0.40, 0.0), Vector3(2.0, 0.80, 0.80), bin,  true,  node)
	_box(name + "_Rim",   Vector3(0.0, 0.82, 0.0), Vector3(2.10, 0.08, 0.90), rim,  false, node)
	_box(name + "_Board1", Vector3(-0.20, 1.00, 0.0), Vector3(0.55, 0.12, 0.72), _mat("kb_y", Color(0.78, 0.65, 0.12)), false, node)
	_box(name + "_Board2", Vector3( 0.35, 1.04, 0.0), Vector3(0.55, 0.12, 0.68), _mat("kb_r", Color(0.72, 0.22, 0.12)), false, node)


func _make_lifeguard_chair(pos: Vector3) -> void:
	var node: Node3D = Node3D.new()
	node.name     = "LifeguardChair"
	node.position = pos
	add_child(node)

	var mat:   Material = _mat("lifeguard", Color(0.80, 0.70, 0.42))
	var metal: Material = _mat("lg_metal",  Color(0.52, 0.50, 0.36))
	var red:   Material = _mat("lg_red",    Color(0.60, 0.08, 0.06))

	# Seat platform
	_box("LGSeat",   Vector3(0.0, 2.16, 0.0),   Vector3(1.15, 0.18, 0.88), mat,   true, node)
	# Backrest with slats
	_box("LGBack1",  Vector3(0.0, 2.44, 0.44),  Vector3(1.15, 0.08, 0.14), mat,   true, node)
	_box("LGBack2",  Vector3(0.0, 2.66, 0.44),  Vector3(1.15, 0.08, 0.14), mat,   true, node)
	_box("LGBack3",  Vector3(0.0, 2.88, 0.44),  Vector3(1.15, 0.08, 0.14), mat,   true, node)
	# Armrests
	_box("LGArmL",   Vector3(-0.52, 2.42, 0.0), Vector3(0.08, 0.10, 0.80), metal, true, node)
	_box("LGArmR",   Vector3( 0.52, 2.42, 0.0), Vector3(0.08, 0.10, 0.80), metal, true, node)
	# Four legs
	var xs: Array[float] = [-0.42, 0.42]
	var zs: Array[float] = [-0.30, 0.30]
	for lx: float in xs:
		for lz: float in zs:
			_box("LGLeg", Vector3(lx, 1.08, lz), Vector3(0.10, 2.16, 0.10), metal, true, node)
	# Cross braces
	_box("LGBraceX", Vector3(0.0, 0.70, 0.0), Vector3(0.92, 0.08, 0.08), metal, true, node)
	_box("LGBraceZ", Vector3(0.0, 0.70, 0.0), Vector3(0.08, 0.08, 0.68), metal, true, node)
	# Steps
	_box("LGStep1",  Vector3(0.0, 0.82, -0.72), Vector3(1.15, 0.08, 0.14), metal, true, node)
	_box("LGStep2",  Vector3(0.0, 1.28, -0.72), Vector3(1.15, 0.08, 0.14), metal, true, node)
	# Rescue tube (red cylinder on side)
	_cylinder("LGTube", Vector3(0.68, 2.20, 0.0), 0.12, 0.90, red, false, node)

# ──────────────────────────────────────────────────────────────────────────────
#  CLASSROOM  (better desks, teacher station, blackboard, storage)
# ──────────────────────────────────────────────────────────────────────────────
func _build_classroom() -> void:
	var desk_top:  Material = _mat("desk_top",    Color(0.28, 0.15, 0.08))
	var desk_body: Material = _mat("desk_body",   Color(0.18, 0.09, 0.04))
	var chair_mat: Material = _mat("chair",       Color(0.05, 0.10, 0.30))
	var metal:     Material = _mat("cls_metal",   Color(0.08, 0.09, 0.09))
	var board:     Material = _mat("blackboard",  Color(0.02, 0.10, 0.06))
	var chalk:     Material = _mat("chalk",       Color(0.64, 0.66, 0.58))
	var chalk_wrt: Material = _mat("chalk_write", Color(0.80, 0.82, 0.70))

	# Blackboard (flush to west wall, with tray)
	_box("ClassBoardBacking", Vector3(CLASS_X0 + 0.10, 2.40, 20.0),
		 Vector3(0.08, 1.60, 9.5), board, false)
	_box("ClassBoardFace",    Vector3(CLASS_X0 + 0.16, 2.40, 20.0),
		 Vector3(0.06, 1.48, 9.2), board, false)
	# Chalk writing texture (faint marks via pale boxes)
	_box("ClassChalkA", Vector3(CLASS_X0 + 0.24, 2.55, 17.5),
		 Vector3(0.02, 0.18, 2.8), chalk_wrt, false)
	_box("ClassChalkB", Vector3(CLASS_X0 + 0.24, 2.30, 22.0),
		 Vector3(0.02, 0.12, 1.4), chalk_wrt, false)
	# Tray
	_box("ClassBoardTray",    Vector3(CLASS_X0 + 0.22, 1.56, 20.0),
		 Vector3(0.16, 0.09, 9.5), chalk)
	# Chalk sticks on tray
	for ci: int in range(4):
		_box("ClassChalkStick" + str(ci),
			 Vector3(CLASS_X0 + 0.20, 1.62, 18.0 + float(ci) * 0.70),
			 Vector3(0.04, 0.04, 0.45), chalk_wrt, false)

	# Board frame
	var bf: Material = _mat("board_frame", Color(0.06, 0.08, 0.06))
	_box("ClassBoardFrmT", Vector3(CLASS_X0 + 0.14, 3.20, 20.0), Vector3(0.10, 0.10, 9.7), bf, false)
	_box("ClassBoardFrmB", Vector3(CLASS_X0 + 0.14, 1.50, 20.0), Vector3(0.10, 0.10, 9.7), bf, false)
	_box("ClassBoardFrmL", Vector3(CLASS_X0 + 0.14, 2.40, 15.4), Vector3(0.10, 1.72, 0.10), bf, false)
	_box("ClassBoardFrmR", Vector3(CLASS_X0 + 0.14, 2.40, 24.6), Vector3(0.10, 1.72, 0.10), bf, false)

	# Teacher's station (against west wall, facing class)
	_make_teacher_station("TeacherStation", Vector3(CLASS_X0 + 4.5, 0.0, 18.5), desk_top, desk_body)

	# Student desks — 4 columns × 3 rows
	var xs: Array[float] = [-45.5, -38.0, -30.5, -23.2]
	var zs: Array[float] = [15.0, 21.0, 27.0]
	var idx: int = 0
	for z_value: float in zs:
		for x_value: float in xs:
			_make_student_desk("SD" + str(idx), Vector3(x_value, 0.0, z_value),
							   0.0, desk_top, desk_body, chair_mat, metal)
			idx += 1

	# Storage shelves along east classroom wall (no clip into lab)
	_make_bookshelf("ClassShelfA", Vector3(CLASS_X1 - 2.0, 0.0, 12.5), 0.0)
	_make_bookshelf("ClassShelfB", Vector3(CLASS_X1 - 2.0, 0.0, 19.0), 0.0)

	# Posters on hallway wall
	var pr: Material = _mat("poster_red",    Color(0.50, 0.08, 0.06))
	var py: Material = _mat("poster_yellow", Color(0.68, 0.58, 0.18))
	_box("ClassPosterA", Vector3(-48.0, 2.45, ROOM_Z1 - 0.18), Vector3(2.0, 0.90, 0.05), pr, false)
	_box("ClassPosterB", Vector3(-43.0, 2.55, ROOM_Z1 - 0.18), Vector3(2.5, 1.00, 0.05), py, false)

	# Overhead lights
	for cx: float in [-44.0, -36.0, -28.0]:
		for cz: float in [14.0, 22.0, 30.0]:
			_make_light("ClassLight" + str(cx) + "_" + str(cz),
						Vector3(cx, WALL_H - 0.08, cz))


func _make_teacher_station(name: String, pos: Vector3,
							top_mat: Material, body_mat: Material) -> void:
	var node: Node3D = Node3D.new()
	node.name       = name
	node.position   = pos
	node.rotation.y = 0.0   # fixed: faces student desks instead of the lab wall
	add_child(node)

	var metal: Material = _mat("ts_metal", Color(0.10, 0.10, 0.10))
	var paper: Material = _mat("paper",    Color(0.80, 0.76, 0.58))

	# Desk top
	_box(name + "_Top",   Vector3(0.0, 0.88, 0.0), Vector3(3.4, 0.16, 1.20), top_mat,  true, node)
	# Modesty panel (front face)
	_box(name + "_Front", Vector3(0.0, 0.48, 0.52), Vector3(3.4, 0.72, 0.14), body_mat, true, node)
	# Leg panels
	_box(name + "_PedL",  Vector3(-1.52, 0.44, 0.0), Vector3(0.30, 0.88, 1.05), body_mat, true, node)
	_box(name + "_PedR",  Vector3( 1.52, 0.44, 0.0), Vector3(0.30, 0.88, 1.05), body_mat, true, node)
	# Drawer unit (right ped)
	_box(name + "_Drw1",  Vector3(1.52, 0.65, -0.55), Vector3(0.28, 0.24, 0.06), metal, false, node)
	_box(name + "_Drw2",  Vector3(1.52, 0.35, -0.55), Vector3(0.28, 0.24, 0.06), metal, false, node)
	# Papers on desk
	_box(name + "_PaperA", Vector3(-0.3, 0.97, 0.0), Vector3(0.75, 0.04, 0.55), paper, false, node)
	_box(name + "_PaperB", Vector3( 0.4, 0.98, 0.1), Vector3(0.65, 0.04, 0.44), _mat("paper_b", Color(0.62, 0.68, 0.80)), false, node)
	# Name plate
	_box(name + "_NamePl", Vector3(0.0, 0.94, -0.45), Vector3(1.10, 0.12, 0.04), metal, false, node)


func _make_student_desk(name: String, pos: Vector3, rot_y: float,
						top_mat: Material, body_mat: Material,
						chair_mat: Material, metal_mat: Material) -> void:
	var node: Node3D = Node3D.new()
	node.name       = name
	node.position   = pos
	node.rotation.y = rot_y
	add_child(node)

	# Desk surface
	_box(name + "_Top",  Vector3(0.0, 0.74, 0.0),  Vector3(1.95, 0.12, 1.05), top_mat,  true, node)
	# Desk apron (front + back)
	_box(name + "_ApF",  Vector3(0.0, 0.55, -0.48), Vector3(1.75, 0.30, 0.08), body_mat, true, node)
	_box(name + "_ApB",  Vector3(0.0, 0.55,  0.48), Vector3(1.75, 0.30, 0.08), body_mat, true, node)
	# Under-desk book bin
	_box(name + "_Bin",  Vector3(0.0, 0.46, 0.20),  Vector3(1.55, 0.22, 0.60), body_mat, true, node)
	# Four legs
	var leg_xs: Array[float] = [-0.80, 0.80]
	var leg_zs: Array[float] = [-0.38, 0.38]
	for lx: float in leg_xs:
		for lz: float in leg_zs:
			_box(name + "_Leg", Vector3(lx, 0.32, lz), Vector3(0.07, 0.64, 0.07), metal_mat, true, node)
	# Leg brace (back pair)
	_box(name + "_Brace", Vector3(0.0, 0.14, 0.38), Vector3(1.60, 0.06, 0.06), metal_mat, true, node)

	# Chair — behind desk, angled for realism
	_box(name + "_CSeat",  Vector3(0.0, 0.44, 1.10),  Vector3(0.98, 0.12, 0.78), chair_mat, true, node)
	_box(name + "_CBack",  Vector3(0.0, 0.88, 1.48),  Vector3(0.98, 0.70, 0.12), chair_mat, true, node)
	# Chair back top rail
	_box(name + "_CRail",  Vector3(0.0, 1.26, 1.48),  Vector3(0.98, 0.08, 0.14), chair_mat, true, node)
	# Chair legs
	for clx: float in [-0.42, 0.42]:
		for clz: float in [0.80, 1.40]:
			_box(name + "_CLeg", Vector3(clx, 0.20, clz), Vector3(0.06, 0.40, 0.06), metal_mat, true, node)


func _make_bookshelf(name: String, pos: Vector3, rot_y: float) -> void:
	var node: Node3D = Node3D.new()
	node.name       = name
	node.position   = pos
	node.rotation.y = rot_y
	add_child(node)

	var wood:  Material = _mat("shelf_wood", Color(0.16, 0.08, 0.04))
	var red:   Material = _mat("book_red",   Color(0.48, 0.07, 0.06))
	var blue:  Material = _mat("book_blue",  Color(0.05, 0.08, 0.42))
	var green: Material = _mat("book_green", Color(0.08, 0.28, 0.12))
	var dark:  Material = _mat("book_dark",  Color(0.10, 0.06, 0.04))
	var back:  Material = _mat("shelf_back", Color(0.12, 0.06, 0.03))

	# Cabinet back panel
	_box(name + "_Back",  Vector3(0.0, 1.30, 0.02),  Vector3(3.10, 2.60, 0.28), back, true, node)
	# Side panels
	_box(name + "_SideL", Vector3(-1.55, 1.30, -0.14), Vector3(0.08, 2.60, 0.56), wood, true, node)
	_box(name + "_SideR", Vector3( 1.55, 1.30, -0.14), Vector3(0.08, 2.60, 0.56), wood, true, node)

	# Shelves (4 levels)
	var shelf_ys: Array[float] = [0.10, 0.80, 1.50, 2.20]
	for sy: float in shelf_ys:
		_box(name + "_Shelf" + str(sy),
			 Vector3(0.0, sy, -0.22), Vector3(3.10, 0.07, 0.50), wood, true, node)

	# Top panel
	_box(name + "_Top",   Vector3(0.0, 2.60, -0.14),  Vector3(3.10, 0.07, 0.56), wood, true, node)

	# Books — varied heights and colors
	var book_mats: Array[Material] = [red, blue, green, dark, red, blue, green, dark,
									  red, blue, green, dark, red, blue]
	for bi: int in range(14):
		var bx:   float    = -1.30 + float(bi % 7) * 0.40
		var by:   float    = 0.46 + float(bi / 7) * 0.70
		var bh:   float    = 0.38 + float(bi % 3) * 0.07
		var bmat: Material = book_mats[bi]
		_box(name + "_Book" + str(bi),
			 Vector3(bx, by, -0.46), Vector3(0.12, bh, 0.20), bmat, false, node)

# ──────────────────────────────────────────────────────────────────────────────
#  LABORATORY  (tables, sinks, microscopes, chemical storage, board)
# ──────────────────────────────────────────────────────────────────────────────
func _build_lab() -> void:
	var table:   Material = _mat("lab_table",   Color(0.04, 0.14, 0.12))
	var cabinet: Material = _mat("lab_cabinet", Color(0.10, 0.22, 0.14))
	var black:   Material = _mat("black",       Color(0.02, 0.02, 0.02))

	# Main lab tables (two rows of two)
	for zt: float in [14.5, 23.5]:
		_make_lab_table("LabTableA" + str(zt), Vector3(-9.0, 0.0, zt), table)
		_make_lab_table("LabTableB" + str(zt), Vector3( 9.0, 0.0, zt), table)

	# Wall cabinets — flush to south wall (ROOM_Z1)
	_make_lab_wall_cabinet("LabCabL", Vector3(LAB_X0 + 1.4, 0.0, ROOM_Z1 - 0.42), cabinet)
	_make_lab_wall_cabinet("LabCabR", Vector3(LAB_X1 - 1.4, 0.0, ROOM_Z1 - 0.42), cabinet)

	# Central storage counter (south wall, between cabinets)
	_make_lab_counter("LabCounter", Vector3(0.0, 0.0, ROOM_Z1 - 0.42), cabinet)

	# Demo board on west wall
	var lb: Material = _mat("lab_board", Color(0.02, 0.10, 0.06))
	_box("LabBoard",     Vector3(LAB_X0 + 0.14, 2.30, 19.0), Vector3(0.07, 1.35, 7.5), lb, false)
	_box("LabBoardFrmT", Vector3(LAB_X0 + 0.12, 3.00, 19.0), Vector3(0.10, 0.08, 7.7), black, false)
	_box("LabBoardFrmB", Vector3(LAB_X0 + 0.12, 1.60, 19.0), Vector3(0.10, 0.08, 7.7), black, false)
	# Chalk/marker marks
	var mk: Material = _mat("lab_mark", Color(0.72, 0.80, 0.64))
	_box("LabMarkA", Vector3(LAB_X0 + 0.24, 2.55, 16.5), Vector3(0.02, 0.10, 1.80), mk, false)
	_box("LabMarkB", Vector3(LAB_X0 + 0.24, 2.20, 20.5), Vector3(0.02, 0.12, 2.20), mk, false)

	# Microscopes on tables
	for mx: float in [-9.0, 9.0]:
		for mz: float in [14.5, 23.5]:
			_make_microscope("Micro" + str(mx) + "_" + str(mz), Vector3(mx, 0.98, mz), black)

	# Chemical bottles on counter
	for bi: int in range(8):
		var bx: float    = -2.2 + float(bi) * 0.58
		var hue_shift: float = float(bi % 4) * 0.08
		var bc: Color    = Color(0.60, 0.08 + hue_shift, 0.08)
		_cylinder("Bottle" + str(bi), Vector3(bx, 1.08, ROOM_Z1 - 0.78),
				  0.10, 0.46, _mat("chem" + str(bi), bc), false)
		# Bottle cap
		_cylinder("BottleCap" + str(bi), Vector3(bx, 1.34, ROOM_Z1 - 0.78),
				  0.06, 0.06, _mat("cap" + str(bi), Color(0.10, 0.10, 0.10)), false)

	# Eyewash station (wall-mounted)
	_make_eyewash("LabEyewash", Vector3(LAB_X1 - 0.85, 1.20, 10.0))

	# Overhead lights
	for lx: float in [-9.0, 0.0, 9.0]:
		for lz: float in [13.0, 21.0, 29.5]:
			_make_light("LabLight_" + str(lx) + "_" + str(lz), Vector3(lx, WALL_H - 0.08, lz))


func _make_lab_table(name: String, pos: Vector3, mat: Material) -> void:
	var node: Node3D = Node3D.new()
	node.name     = name
	node.position = pos
	add_child(node)

	var base_mat: Material = _mat("lab_base",  Color(0.03, 0.08, 0.06))
	var sink_mat: Material = _mat("sink",      Color(0.46, 0.50, 0.50))
	var metal:    Material = _mat("lab_metal", Color(0.32, 0.32, 0.28))

	# Table top
	_box(name + "_Top",    Vector3(0.0, 0.88, 0.0),   Vector3(5.2, 0.18, 1.75), mat,      true, node)
	# Apron (all four sides)
	_box(name + "_ApF",    Vector3(0.0, 0.58, -0.82), Vector3(5.0, 0.48, 0.10), base_mat, true, node)
	_box(name + "_ApB",    Vector3(0.0, 0.58,  0.82), Vector3(5.0, 0.48, 0.10), base_mat, true, node)
	_box(name + "_ApL",    Vector3(-2.55, 0.58, 0.0), Vector3(0.10, 0.48, 1.60), base_mat, true, node)
	_box(name + "_ApR",    Vector3( 2.55, 0.58, 0.0), Vector3(0.10, 0.48, 1.60), base_mat, true, node)
	# Under-shelf
	_box(name + "_UShelf", Vector3(0.0, 0.30, 0.0),   Vector3(4.8, 0.08, 1.45), base_mat, true, node)
	# Legs (4)
	for lx: float in [-2.40, 2.40]:
		for lz: float in [-0.70, 0.70]:
			_box(name + "_Leg", Vector3(lx, 0.44, lz), Vector3(0.08, 0.88, 0.08), metal, true, node)

	# Sink basin (inset into top)
	_box(name + "_SinkTop", Vector3(1.6, 0.95, 0.0),  Vector3(0.80, 0.06, 0.58), sink_mat, false, node)
	_box(name + "_SinkBsn", Vector3(1.6, 0.88, 0.0),  Vector3(0.66, 0.12, 0.44), base_mat, false, node)
	# Tap
	_box(name + "_Tap",     Vector3(1.6, 1.04, -0.25), Vector3(0.06, 0.20, 0.06), metal, false, node)
	_box(name + "_TapArm",  Vector3(1.6, 1.24, -0.14), Vector3(0.06, 0.06, 0.22), metal, false, node)


func _make_lab_wall_cabinet(name: String, pos: Vector3, mat: Material) -> void:
	var node: Node3D = Node3D.new()
	node.name     = name
	node.position = pos
	add_child(node)

	var metal: Material = _mat("lab_cab_met", Color(0.52, 0.50, 0.36))
	var dark:  Material = _mat("lab_cab_drk", Color(0.04, 0.06, 0.04))

	# Body
	_box(name + "_Body",  Vector3(0.0, 1.08, 0.0), Vector3(2.0, 2.16, 0.75), mat,   true, node)
	# Doors (two halves with inset)
	_box(name + "_DoorL", Vector3(-0.52, 1.08, -0.39), Vector3(0.85, 1.90, 0.04), mat,   false, node)
	_box(name + "_DoorR", Vector3( 0.52, 1.08, -0.39), Vector3(0.85, 1.90, 0.04), mat,   false, node)
	# Door gap line
	_box(name + "_Gap",   Vector3(0.0, 1.08, -0.39),   Vector3(0.04, 1.90, 0.04), dark,  false, node)
	# Handles
	_box(name + "_HndL",  Vector3(-0.10, 1.08, -0.44), Vector3(0.06, 0.28, 0.04), metal, false, node)
	_box(name + "_HndR",  Vector3( 0.10, 1.08, -0.44), Vector3(0.06, 0.28, 0.04), metal, false, node)
	# Toe kick
	_box(name + "_Toe",   Vector3(0.0, 0.08, -0.02), Vector3(1.95, 0.16, 0.70), dark, false, node)


func _make_lab_counter(name: String, pos: Vector3, mat: Material) -> void:
	var node: Node3D = Node3D.new()
	node.name     = name
	node.position = pos
	add_child(node)

	var top:  Material = _mat("counter_top", Color(0.06, 0.18, 0.14))
	var dark: Material = _mat("counter_drk", Color(0.03, 0.06, 0.04))

	_box(name + "_Top",  Vector3(0.0, 0.92, 0.0), Vector3(5.0, 0.10, 0.75), top,  true, node)
	_box(name + "_Body", Vector3(0.0, 0.46, 0.0), Vector3(5.0, 0.84, 0.72), mat,  true, node)
	_box(name + "_Toe",  Vector3(0.0, 0.07, -0.04), Vector3(4.9, 0.14, 0.65), dark, false, node)


func _make_microscope(name: String, pos: Vector3, mat: Material) -> void:
	var node: Node3D = Node3D.new()
	node.name     = name
	node.position = pos
	add_child(node)

	# Base plate
	_box(name + "_Base",  Vector3(0.0, 0.04, 0.0),   Vector3(0.58, 0.08, 0.42), mat, false, node)
	# Arm column
	_box(name + "_Arm",   Vector3(0.06, 0.32, 0.0),  Vector3(0.09, 0.54, 0.09), mat, false, node)
	# Head (angled box)
	_box(name + "_Head",  Vector3(0.20, 0.60, -0.05), Vector3(0.38, 0.14, 0.18), mat, false, node)
	# Eyepiece
	_box(name + "_Eye",   Vector3(0.28, 0.70, -0.05), Vector3(0.07, 0.18, 0.07), mat, false, node)
	# Stage
	_box(name + "_Stage", Vector3(0.0, 0.24, 0.0),   Vector3(0.44, 0.05, 0.32), mat, false, node)
	# Objective lenses (3 small cylinders via tiny boxes)
	for oi: int in range(3):
		_box(name + "_Obj" + str(oi),
			 Vector3(0.20 + float(oi) * 0.04, 0.52 - float(oi) * 0.03, -0.10 - float(oi) * 0.03),
			 Vector3(0.04, 0.10, 0.04), mat, false, node)
	# Focus knob
	_box(name + "_Knob",  Vector3(-0.04, 0.35, 0.08), Vector3(0.08, 0.08, 0.12), mat, false, node)


func _make_eyewash(name: String, pos: Vector3) -> void:
	var node: Node3D = Node3D.new()
	node.name     = name
	node.position = pos
	add_child(node)

	var metal: Material = _mat("eyewash_met", Color(0.46, 0.50, 0.48))
	var green: Material = _mat("eyewash_grn", Color(0.12, 0.50, 0.18))

	_box(name + "_Mount",  Vector3(0.0, 0.0, 0.0),   Vector3(0.14, 0.30, 0.14), metal, false, node)
	_box(name + "_Bowl",   Vector3(0.0, 0.16, -0.10), Vector3(0.30, 0.12, 0.28), metal, false, node)
	_box(name + "_Sign",   Vector3(0.0, 0.35, -0.05), Vector3(0.22, 0.12, 0.04), green, false, node)

# ──────────────────────────────────────────────────────────────────────────────
#  OFFICE  (principal's office — occupied, lived-in feel)
# ──────────────────────────────────────────────────────────────────────────────
func _build_office() -> void:
	var desk_top:  Material = _mat("off_desk_top",  Color(0.22, 0.10, 0.06))
	var desk_body: Material = _mat("off_desk_body", Color(0.14, 0.06, 0.03))
	var chair_mat: Material = _mat("off_chair",     Color(0.04, 0.04, 0.07))
	var couch_mat: Material = _mat("couch",         Color(0.04, 0.08, 0.28))
	var file_mat:  Material = _mat("file_cabinet",  Color(0.20, 0.24, 0.26))

	# Desk — rotated to face east, pushed from west wall
	_make_principal_desk("PrincipalDesk", Vector3(33.0, 0.0, 27.5), PI, desk_top, desk_body)
	# Chair behind desk
	_make_office_chair("PrincipalChair", Vector3(33.0, 0.0, 30.0), PI, chair_mat)

	# Couch — facing desk (south wall side, rotated to face north)
	# Position: flush to east wall, facing west
	_make_couch("OfficeCouch", Vector3(OFFICE_X1 - 2.8, 0.0, 18.0), PI * 0.5, couch_mat)

	# Filing cabinets along south wall — flush, no clip
	_make_filing("FilingA", Vector3(20.8, 0.0, ROOM_Z1 - 0.75), 0.0, file_mat)
	_make_filing("FilingB", Vector3(23.4, 0.0, ROOM_Z1 - 0.75), 0.0, file_mat)

	# Bookshelf along south wall (east end)
	_make_bookshelf("OfficeShelf", Vector3(48.0, 0.0, ROOM_Z1 - 1.4), 0.0)

	# Small meeting table with two chairs
	_make_side_table("OfficeSideTable", Vector3(38.0, 0.0, 16.0), chair_mat)

	# Wall decorations
	var pic:   Material = _mat("picture",    Color(0.24, 0.16, 0.08))
	var pic2:  Material = _mat("picture2",   Color(0.08, 0.10, 0.22))
	var frame: Material = _mat("pic_frame",  Color(0.06, 0.06, 0.05))
	# Picture on hallway wall
	_box("OfficePic1",       Vector3(33.0, 2.50, ROOM_Z0 + 0.14),  Vector3(3.8, 1.10, 0.05), pic,   false)
	_box("OfficePic1Frame",  Vector3(33.0, 2.50, ROOM_Z0 + 0.12),  Vector3(4.0, 1.25, 0.06), frame, false)
	_box("OfficePic2",       Vector3(42.0, 2.20, ROOM_Z0 + 0.14),  Vector3(2.0, 0.80, 0.05), pic2,  false)
	_box("OfficePic2Frame",  Vector3(42.0, 2.20, ROOM_Z0 + 0.12),  Vector3(2.15, 0.95, 0.06), frame, false)

	# Desk items
	var paper: Material = _mat("paper",   Color(0.80, 0.76, 0.58))
	_box("OfficePaperA",  Vector3(32.2, 1.02, 27.0), Vector3(0.75, 0.04, 0.52), paper, false)
	_box("OfficePaperB",  Vector3(33.4, 1.03, 26.8), Vector3(0.65, 0.04, 0.44), _mat("paper_b", Color(0.62, 0.68, 0.80)), false)
	# Desk lamp
	_make_desk_lamp("OfficeLamp", Vector3(31.6, 0.96, 27.2))
	# Phone on desk
	_make_desk_phone("OfficePhone", Vector3(34.4, 0.96, 27.6))

	# Award plaques on east wall
	var plaque: Material = _mat("plaque",     Color(0.55, 0.46, 0.22))
	var plq_bg: Material = _mat("plaque_bg",  Color(0.18, 0.08, 0.04))
	_box("PlaqueA",      Vector3(OFFICE_X1 - 0.14, 2.60, 20.8), Vector3(0.05, 0.60, 1.20), plaque, false)
	_box("PlaqueBg",     Vector3(OFFICE_X1 - 0.12, 2.60, 20.8), Vector3(0.04, 0.50, 1.00), plq_bg, false)
	_box("PlaqueB",      Vector3(OFFICE_X1 - 0.14, 2.60, 25.6), Vector3(0.05, 0.60, 1.20), plaque, false)
	_box("PlaqueBbg",    Vector3(OFFICE_X1 - 0.12, 2.60, 25.6), Vector3(0.04, 0.50, 1.00), plq_bg, false)

	# Overhead lights
	for ox: float in [26.0, 36.0, 46.0]:
		for oz: float in [13.0, 21.0, 29.5]:
			_make_light("OfficeLight_" + str(ox) + "_" + str(oz), Vector3(ox, WALL_H - 0.08, oz))


func _make_principal_desk(name: String, pos: Vector3, rot_y: float,
						   top_mat: Material, body_mat: Material) -> void:
	var node: Node3D = Node3D.new()
	node.name       = name
	node.position   = pos
	node.rotation.y = rot_y
	add_child(node)

	# L-shaped desk: main section + return
	_box(name + "_MainTop",  Vector3(0.0, 0.90, 0.0),   Vector3(3.4, 0.14, 1.25), top_mat,  true, node)
	_box(name + "_RetTop",   Vector3(-1.20, 0.90, -1.05), Vector3(1.0, 0.14, 2.10), top_mat, true, node)
	# Modesty panels
	_box(name + "_FrontPnl", Vector3(0.0, 0.50, 0.55),  Vector3(3.3, 0.76, 0.12), body_mat, true, node)
	# Pedestal left
	_box(name + "_PedL",     Vector3(-1.55, 0.44, 0.0), Vector3(0.28, 0.88, 1.12), body_mat, true, node)
	# Pedestal right
	_box(name + "_PedR",     Vector3( 1.55, 0.44, 0.0), Vector3(0.28, 0.88, 1.12), body_mat, true, node)
	# Drawers on right pedestal
	var metal: Material = _mat("desk_metal", Color(0.10, 0.10, 0.10))
	for di: int in range(3):
		_box(name + "_Drw" + str(di),
			 Vector3(1.55, 0.28 + float(di) * 0.28, -0.58),
			 Vector3(0.24, 0.20, 0.06), metal, false, node)
		_box(name + "_DPull" + str(di),
			 Vector3(1.55, 0.28 + float(di) * 0.28, -0.62),
			 Vector3(0.10, 0.04, 0.04), metal, false, node)


func _make_office_chair(name: String, pos: Vector3, rot_y: float, mat: Material) -> void:
	var node: Node3D = Node3D.new()
	node.name       = name
	node.position   = pos
	node.rotation.y = rot_y
	add_child(node)

	var metal: Material = _mat("off_ch_met", Color(0.10, 0.10, 0.10))

	# Seat cushion
	_box(name + "_Seat",   Vector3(0.0, 0.62, 0.0),  Vector3(1.12, 0.16, 1.02), mat,   true, node)
	# Backrest (taller executive)
	_box(name + "_Back",   Vector3(0.0, 1.25, 0.46), Vector3(1.12, 1.15, 0.16), mat,   true, node)
	# Head rest
	_box(name + "_Head",   Vector3(0.0, 1.90, 0.44), Vector3(0.72, 0.28, 0.18), mat,   true, node)
	# Arm rests
	_box(name + "_ArmL",   Vector3(-0.55, 0.90, 0.0), Vector3(0.08, 0.12, 0.90), metal, true, node)
	_box(name + "_ArmR",   Vector3( 0.55, 0.90, 0.0), Vector3(0.08, 0.12, 0.90), metal, true, node)
	# Post + base
	_box(name + "_Post",   Vector3(0.0, 0.30, 0.0),  Vector3(0.14, 0.60, 0.14), metal, true, node)
	_box(name + "_Base",   Vector3(0.0, 0.08, 0.0),  Vector3(0.90, 0.08, 0.90), metal, true, node)
	# Caster nubs (5 around base)
	for ci: int in range(5):
		var ang: float = float(ci) * TAU / 5.0
		_box(name + "_Cast" + str(ci),
			 Vector3(cos(ang) * 0.42, 0.04, sin(ang) * 0.42),
			 Vector3(0.08, 0.08, 0.08), metal, false, node)


func _make_couch(name: String, pos: Vector3, rot_y: float, mat: Material) -> void:
	var node: Node3D = Node3D.new()
	node.name       = name
	node.position   = pos
	node.rotation.y = rot_y
	add_child(node)

	var dark_mat: Material = _mat("couch_dark", Color(0.02, 0.04, 0.16))
	var leg_mat:  Material = _mat("couch_leg",  Color(0.14, 0.08, 0.04))

	# Cushion sections (3 seat pads for detail)
	for ci: int in range(3):
		_box(name + "_Cush" + str(ci),
			 Vector3(-1.22 + float(ci) * 1.22, 0.58, 0.0),
			 Vector3(1.14, 0.38, 1.16), mat, true, node)
	# Seat base
	_box(name + "_Base",   Vector3(0.0, 0.35, 0.0),   Vector3(4.25, 0.30, 1.22), dark_mat, true, node)
	# Back (three back cushions)
	for bi: int in range(3):
		_box(name + "_BCush" + str(bi),
			 Vector3(-1.22 + float(bi) * 1.22, 1.12, 0.54),
			 Vector3(1.14, 1.04, 0.36), mat, true, node)
	# Back rail
	_box(name + "_BackRail", Vector3(0.0, 1.68, 0.56), Vector3(4.25, 0.10, 0.38), dark_mat, true, node)
	# Arms
	_box(name + "_ArmL",   Vector3(-2.26, 0.88, 0.0), Vector3(0.32, 1.00, 1.28), mat,      true, node)
	_box(name + "_ArmR",   Vector3( 2.26, 0.88, 0.0), Vector3(0.32, 1.00, 1.28), mat,      true, node)
	# Legs (4)
	for lx: float in [-1.8, 1.8]:
		for lz: float in [-0.48, 0.48]:
			_box(name + "_Leg", Vector3(lx, 0.10, lz), Vector3(0.12, 0.20, 0.12), leg_mat, true, node)


func _make_filing(name: String, pos: Vector3, rot_y: float, mat: Material) -> void:
	var node: Node3D = Node3D.new()
	node.name       = name
	node.position   = pos
	node.rotation.y = rot_y
	add_child(node)

	var metal:    Material = _mat("file_metal",  Color(0.52, 0.50, 0.36))
	var drw_mat:  Material = _mat("file_drawer", Color(0.16, 0.19, 0.21))

	# Body
	_box(name + "_Body",  Vector3(0.0, 1.08, 0.0), Vector3(1.25, 2.16, 0.88), mat,   true, node)
	# Drawers
	var drawer_ys: Array[float] = [0.40, 0.90, 1.40, 1.90]
	for dy: float in drawer_ys:
		_box(name + "_Drw"  + str(dy), Vector3(0.0, dy, -0.46),
			 Vector3(1.05, 0.40, 0.04), drw_mat, false, node)
		_box(name + "_Pull" + str(dy), Vector3(0.0, dy,  -0.51),
			 Vector3(0.45, 0.06, 0.04), metal,   false, node)
	# Toe kick
	_box(name + "_Toe",   Vector3(0.0, 0.06, -0.04), Vector3(1.20, 0.12, 0.82), drw_mat, false, node)
	# Label slots on drawer faces
	for dy: float in drawer_ys:
		_box(name + "_Lbl" + str(dy), Vector3(-0.28, dy + 0.14, -0.48),
			 Vector3(0.50, 0.10, 0.03), _mat("label_slot", Color(0.70, 0.68, 0.52)), false, node)


func _make_side_table(name: String, pos: Vector3, chair_mat: Material) -> void:
	var node: Node3D = Node3D.new()
	node.name     = name
	node.position = pos
	add_child(node)

	var top: Material = _mat("side_top", Color(0.20, 0.10, 0.06))
	var leg: Material = _mat("side_leg", Color(0.08, 0.08, 0.08))

	# Table
	_box(name + "_Top", Vector3(0.0, 0.76, 0.0), Vector3(2.0, 0.10, 0.90), top, true, node)
	for tlx: float in [-0.85, 0.85]:
		for tlz: float in [-0.35, 0.35]:
			_box(name + "_Leg", Vector3(tlx, 0.36, tlz), Vector3(0.06, 0.72, 0.06), leg, true, node)

	# Two chairs either side, with legs so they no longer look floating
	_box(name + "_Chair1Seat", Vector3(-1.50, 0.44, 0.0), Vector3(0.80, 0.12, 0.70), chair_mat, true, node)
	_box(name + "_Chair1Back", Vector3(-1.50, 0.82, 0.34), Vector3(0.80, 0.65, 0.12), chair_mat, true, node)
	_box(name + "_Chair2Seat", Vector3( 1.50, 0.44, 0.0), Vector3(0.80, 0.12, 0.70), chair_mat, true, node)
	_box(name + "_Chair2Back", Vector3( 1.50, 0.82, 0.34), Vector3(0.80, 0.65, 0.12), chair_mat, true, node)
	for cx: float in [-1.50, 1.50]:
		for lx: float in [-0.30, 0.30]:
			for lz: float in [-0.24, 0.24]:
				_box(name + "_ChairLeg", Vector3(cx + lx, 0.22, lz), Vector3(0.06, 0.44, 0.06), leg, true, node)


func _make_desk_lamp(name: String, pos: Vector3) -> void:
	var node: Node3D = Node3D.new()
	node.name     = name
	node.position = pos
	add_child(node)

	var metal: Material = _mat("lamp_metal",  Color(0.12, 0.12, 0.10))
	var shade: Material = _mat("lamp_shade",  Color(0.58, 0.52, 0.28))
	var bulb:  Material = _mat("lamp_bulb",   Color(0.96, 0.90, 0.52))

	_box(name + "_Base",  Vector3(0.0, 0.04, 0.0), Vector3(0.22, 0.08, 0.22), metal, false, node)
	_box(name + "_Pole",  Vector3(0.0, 0.24, 0.0), Vector3(0.05, 0.48, 0.05), metal, false, node)
	_box(name + "_Arm",   Vector3(0.06, 0.46, 0.0), Vector3(0.18, 0.05, 0.05), metal, false, node)
	_box(name + "_Shade", Vector3(0.14, 0.44, 0.0), Vector3(0.22, 0.18, 0.18), shade, false, node)
	_box(name + "_Bulb",  Vector3(0.14, 0.38, 0.0), Vector3(0.08, 0.08, 0.08), bulb,  false, node)

	var lamp_light: OmniLight3D = OmniLight3D.new()
	lamp_light.name         = name + "_Omni"
	lamp_light.position     = node.global_position + Vector3(0.14, 0.35, 0.0)
	lamp_light.light_color  = Color(1.0, 0.88, 0.55)
	lamp_light.light_energy = 0.30
	lamp_light.omni_range   = 4.0
	add_child(lamp_light)


func _make_desk_phone(name: String, pos: Vector3) -> void:
	var node: Node3D = Node3D.new()
	node.name     = name
	node.position = pos
	add_child(node)

	var body:  Material = _mat("phone_body",   Color(0.08, 0.09, 0.09))
	var keys:  Material = _mat("phone_keys",   Color(0.14, 0.14, 0.12))
	var crd:   Material = _mat("phone_cord",   Color(0.06, 0.06, 0.06))

	_box(name + "_Body",     Vector3(0.0, 0.04, 0.0), Vector3(0.55, 0.08, 0.42), body,  false, node)
	_box(name + "_KeyPad",   Vector3(0.0, 0.08, 0.05), Vector3(0.36, 0.04, 0.28), keys, false, node)
	_box(name + "_Handset",  Vector3(0.10, 0.14, -0.10), Vector3(0.22, 0.07, 0.48), body, false, node)
	_box(name + "_Cord",     Vector3(-0.18, 0.05, 0.0), Vector3(0.04, 0.04, 0.04), crd,  false, node)

# ──────────────────────────────────────────────────────────────────────────────
#  PICKUPS  (unchanged positions — gameplay intact)
# ──────────────────────────────────────────────────────────────────────────────
func _build_pickups() -> void:
	_pickup_box("PickupNotebookHall",   Vector3(-12.0, 0.23, 1.8),  Vector3(0.65, 0.08, 0.45), _mat("book_blue",  Color(0.05, 0.10, 0.45)), 0.35)
	_pickup_box("PickupFolderHall",     Vector3( 18.0, 0.22, -1.7), Vector3(0.75, 0.06, 0.50), _mat("folder",     Color(0.74, 0.62, 0.20)), 0.25)
	_pickup_box("PickupBackpackClass",  Vector3(-24.0, 0.46, 28.0), Vector3(0.90, 0.55, 0.75), _mat("backpack",   Color(0.14, 0.06, 0.22)), 0.90)
	_pickup_cylinder("PickupBottleHall", Vector3(26.5, 0.34, 1.7), 0.18, 0.65, _mat("bottle", Color(0.40, 0.66, 0.76), 0.65), 0.25)
	_pickup_box("PickupClipboardOffice", Vector3(35.8, 1.12, 28.1), Vector3(0.75, 0.08, 0.50), _mat("clipboard",  Color(0.40, 0.24, 0.10)), 0.35)
	_pickup_box("PickupPoolKickboard",   Vector3( 8.0, 0.32, -13.2), Vector3(1.2, 0.12, 0.55), _mat("kickboard",  Color(0.72, 0.60, 0.10)), 0.50)
	_pickup_box("PickupEraserClass",     Vector3(CLASS_X0 + 0.42, 1.70, 20.5), Vector3(0.45, 0.12, 0.22), _mat("eraser", Color(0.12, 0.12, 0.10)), 0.25)
	_pickup_box("PickupBeakerLab",       Vector3(9.0, 1.08, 14.5), Vector3(0.34, 0.34, 0.34), _mat("beaker", Color(0.56, 0.78, 0.82), 0.55), 0.25)

# ──────────────────────────────────────────────────────────────────────────────
#  GLOBAL LIGHTS  (unchanged logic, tweaked color/energy for retro horror mood)
# ──────────────────────────────────────────────────────────────────────────────
func _build_lights() -> void:
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.name             = "SoftSun"
	sun.rotation_degrees = Vector3(-42.0, -38.0, 0.0)
	sun.light_energy     = 0.55
	sun.light_color      = Color(0.80, 0.84, 0.68)   # greenish-cool sun
	add_child(sun)

	var world_env: WorldEnvironment  = WorldEnvironment.new()
	world_env.name = "WorldEnvironment"

	var environment: Environment = Environment.new()
	environment.background_mode         = Environment.BG_COLOR
	environment.background_color        = Color(0.46, 0.54, 0.62)
	environment.ambient_light_source    = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color     = Color(0.52, 0.55, 0.44)   # cool shadow fill
	environment.ambient_light_energy    = 0.70
	environment.fog_enabled             = true
	environment.fog_density             = 0.016   # slightly thicker — creepy
	environment.fog_light_color         = Color(0.48, 0.52, 0.44)

	world_env.environment = environment
	add_child(world_env)

	# Room fill lights (lower energy — rely on fixture lights)
	var light_positions: Array[Vector3] = [
		Vector3(0.0,     WALL_H - 0.08, -20.0),   # pool (handled separately)
		Vector3(-36.0,   WALL_H - 0.08,  20.0),   # classroom
		Vector3(0.0,     WALL_H - 0.08,  20.0),   # lab
		Vector3(36.0,    WALL_H - 0.08,  20.0)    # office
	]

	for pos: Vector3 in light_positions:
		_make_light("RoomFill" + str(pos.x) + "_" + str(pos.z), pos)
