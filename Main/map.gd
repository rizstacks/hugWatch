extends Node3D

# ──────────────────────────────────────────────────────────────────────────────
#  MAP.GD — COMPLETE REPLACEMENT
#  Cleaned school map for Hall Monitor game.
#  Fixes: door gaps, wrong-facing lockers/benches, furniture blocking doors,
#  confusing office layout, window side offsets, unnecessary clutter.
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
#  MATERIALS / PRIMITIVES
# ──────────────────────────────────────────────────────────────────────────────
func _mat(id: String, color: Color, alpha: float = 1.0) -> StandardMaterial3D:
	var key: String = id + "_" + color.to_html(false) + "_" + str(alpha)
	if mats.has(key):
		return mats[key] as StandardMaterial3D

	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(color.r, color.g, color.b, alpha)
	material.roughness = 0.92
	material.metallic = 0.0

	if alpha < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.alpha_scissor_threshold = 0.02

	mats[key] = material
	return material


func _box(name: String, pos: Vector3, size: Vector3, material: Material,
		collision: bool = true, parent: Node = null) -> Node3D:
	var node: Node3D
	if collision:
		node = StaticBody3D.new()
	else:
		node = Node3D.new()

	node.name = name
	node.position = pos

	var target_parent: Node = self if parent == null else parent
	target_parent.add_child(node)

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


func _cylinder(name: String, pos: Vector3, radius: float, height: float,
		material: Material, collision: bool = true, parent: Node = null) -> Node3D:
	var node: Node3D
	if collision:
		node = StaticBody3D.new()
	else:
		node = Node3D.new()

	node.name = name
	node.position = pos

	var target_parent: Node = self if parent == null else parent
	target_parent.add_child(node)

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


func _pickup_box(name: String, pos: Vector3, size: Vector3, material: Material,
		mass_value: float = 0.45) -> RigidBody3D:
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


func _pickup_cylinder(name: String, pos: Vector3, radius: float, height: float,
		material: Material, mass_value: float = 0.35) -> RigidBody3D:
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


# ──────────────────────────────────────────────────────────────────────────────
#  WALL HELPERS
# ──────────────────────────────────────────────────────────────────────────────
func _opening(center: float, width: float, bottom: float, height: float) -> Dictionary:
	return {"center": center, "width": width, "bottom": bottom, "height": height}


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
		var width: float = float(d["width"])
		var bottom: float = float(d["bottom"])
		var height: float = float(d["height"])
		var left: float = maxf(x0, center - width * 0.5)
		var right: float = minf(x1, center + width * 0.5)
		var top: float = bottom + height

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
		var width: float = float(d["width"])
		var bottom: float = float(d["bottom"])
		var height: float = float(d["height"])
		var left: float = maxf(z0, center - width * 0.5)
		var right: float = minf(z1, center + width * 0.5)
		var top: float = bottom + height

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
#  STRUCTURE
# ──────────────────────────────────────────────────────────────────────────────
func _build_structure() -> void:
	_floor("HallFloor", HALL_X0, HALL_X1, HALL_Z0, HALL_Z1, _mat("hall_floor", Color(0.38, 0.48, 0.46)))
	_floor("PoolFloor", POOL_X0, POOL_X1, POOL_Z0, POOL_Z1, _mat("pool_floor", Color(0.36, 0.50, 0.53)))
	_floor("ClassroomFloor", CLASS_X0, CLASS_X1, ROOM_Z0, ROOM_Z1, _mat("class_floor", Color(0.46, 0.42, 0.32)))
	_floor("LabFloor", LAB_X0, LAB_X1, ROOM_Z0, ROOM_Z1, _mat("lab_floor", Color(0.28, 0.42, 0.38)))
	_floor("OfficeFloor", OFFICE_X0, OFFICE_X1, ROOM_Z0, ROOM_Z1, _mat("office_floor", Color(0.36, 0.24, 0.28)))

	# clean hall runner, not too many extra strips
	_box("HallRunner", Vector3(0.0, 0.05, 0.0), Vector3(106.0, 0.07, 1.7), _mat("runner", Color(0.58, 0.52, 0.28)), false)

	_ceiling("HallCeiling", HALL_X0, HALL_X1, HALL_Z0, HALL_Z1)
	_ceiling("PoolCeiling", POOL_X0, POOL_X1, POOL_Z0, POOL_Z1)
	_ceiling("ClassroomCeiling", CLASS_X0, CLASS_X1, ROOM_Z0, ROOM_Z1)
	_ceiling("LabCeiling", LAB_X0, LAB_X1, ROOM_Z0, ROOM_Z1)
	_ceiling("OfficeCeiling", OFFICE_X0, OFFICE_X1, ROOM_Z0, ROOM_Z1)

	# walls with door/window openings
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

	_make_all_windows()

	# Pool door fixed: opens toward the pool side, with visual details on the hall-facing side.
	_make_door_x("Door101Pool", HALL_Z0, 0.0, true, Color(0.10, 0.18, 0.24))
	_make_door_x("Door102Classroom", HALL_Z1, -35.5, false, Color(0.18, 0.10, 0.06))
	_make_door_x("Door103Lab", HALL_Z1, 0.0, false, Color(0.10, 0.18, 0.24))
	_make_door_x("Door104Office", HALL_Z1, 35.5, false, Color(0.20, 0.10, 0.06))

	_make_room_sign("SignPool", Vector3(0.0, 3.8, HALL_Z0 - 0.18), "101")
	_make_room_sign("SignClass", Vector3(-35.5, 3.8, HALL_Z1 + 0.18), "102")
	_make_room_sign("SignLab", Vector3(0.0, 3.8, HALL_Z1 + 0.18), "103")
	_make_room_sign("SignOffice", Vector3(35.5, 3.8, HALL_Z1 + 0.18), "104")


func _make_all_windows() -> void:
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


func _make_window_x(name: String, z: float, center_x: float, width: float, bottom: float, height: float) -> void:
	var frame: Material = _mat("window_frame", Color(0.08, 0.10, 0.10))
	var trim: Material = _mat("window_trim", Color(0.52, 0.55, 0.46))
	var glass: Material = _mat("glass", Color(0.50, 0.68, 0.74), 0.38)

	var y: float = bottom + height * 0.5
	var top: float = bottom + height

	# North wall faces +Z, south wall faces -Z.
	var side: float = 1.0 if z < 0.0 else -1.0
	var front_z: float = z + side * 0.045
	var t: float = 0.12

	_box(name + "_Glass", Vector3(center_x, y, front_z), Vector3(width - 0.38, height - 0.24, 0.04), glass, false)
	_box(name + "_DivH", Vector3(center_x, y, front_z + side * 0.01), Vector3(width - 0.38, t * 0.5, 0.05), frame, false)
	_box(name + "_DivV", Vector3(center_x, y, front_z + side * 0.01), Vector3(t * 0.5, height - 0.24, 0.05), frame, false)

	_box(name + "_FrameL", Vector3(center_x - width * 0.5, y, front_z), Vector3(t, height + 0.12, 0.14), frame)
	_box(name + "_FrameR", Vector3(center_x + width * 0.5, y, front_z), Vector3(t, height + 0.12, 0.14), frame)
	_box(name + "_FrameT", Vector3(center_x, top, front_z), Vector3(width + 0.12, t, 0.14), frame)
	_box(name + "_FrameB", Vector3(center_x, bottom, front_z), Vector3(width + 0.12, t, 0.14), frame)
	_box(name + "_Sill", Vector3(center_x, bottom - 0.22, front_z + side * 0.10), Vector3(width + 0.60, 0.10, 0.42), trim)


func _make_room_sign(name: String, pos: Vector3, label: String) -> void:
	var sign_mat: Material = _mat("sign_bg", Color(0.06, 0.06, 0.05))
	var sign_txt: Material = _mat("sign_txt", Color(0.78, 0.72, 0.48))
	_box(name, pos, Vector3(2.2, 0.30, 0.04), sign_mat, false)
	_box(name + "_Txt_" + label, pos + Vector3(0.0, 0.0, -0.03 if pos.z < 0.0 else 0.03),
		Vector3(1.55, 0.14, 0.03), sign_txt, false)


# ──────────────────────────────────────────────────────────────────────────────
#  DOORS
# ──────────────────────────────────────────────────────────────────────────────
func _make_door_x(name: String, z: float, center_x: float, opens_north: bool, door_color: Color) -> void:
	var frame: Material = _mat("door_frame", Color(0.035, 0.045, 0.045))
	var door: Material = _mat(name + "_mat", door_color)
	var inset: Material = _mat(name + "_ins", door_color.darkened(0.30))
	var glass: Material = _mat("door_glass", Color(0.50, 0.64, 0.70), 0.45)
	var metal: Material = _mat("metal_handle", Color(0.56, 0.54, 0.40))
	var frame_w: float = 2.86
	var frame_h: float = 3.34
	var door_w: float = 2.34
	var door_h: float = 3.08
	var side: float = -1.0 if opens_north else 1.0
	var z_panel: float = z + side * 0.04
	var detail_z: float = -side * 0.08
	var handle_z: float = -side * 0.13

	# bigger frame directly covers the wall gap. No extra ugly board behind the door.
	_box(name + "_JambL", Vector3(center_x - frame_w * 0.5, frame_h * 0.5, z), Vector3(0.26, frame_h, WALL_T + 0.20), frame)
	_box(name + "_JambR", Vector3(center_x + frame_w * 0.5, frame_h * 0.5, z), Vector3(0.26, frame_h, WALL_T + 0.20), frame)
	_box(name + "_Header", Vector3(center_x, frame_h + 0.08, z), Vector3(frame_w + 0.26, 0.24, WALL_T + 0.20), frame)
	_box(name + "_Threshold", Vector3(center_x, 0.04, z + side * 0.04), Vector3(frame_w, 0.08, 0.42), frame)

	var pivot: Node3D = Node3D.new()
	pivot.name = name + "_Hinge"
	pivot.position = Vector3(center_x - door_w * 0.5, 0.0, z_panel)
	add_child(pivot)

	var open_angle: float = deg_to_rad(-82.0) if opens_north else deg_to_rad(82.0)
	pivot.rotation.y = 0.0

	_box(name + "_Panel", Vector3(door_w * 0.5, door_h * 0.5, 0.0), Vector3(door_w, door_h, 0.14), door, false, pivot)
	_box(name + "_LowerInset", Vector3(door_w * 0.5, 1.05, detail_z), Vector3(door_w - 0.42, 1.25, 0.035), inset, false, pivot)
	_box(name + "_Window", Vector3(door_w * 0.5, 2.48, detail_z), Vector3(0.70, 0.46, 0.035), glass, false, pivot)
	_box(name + "_KickPlate", Vector3(door_w * 0.5, 0.28, detail_z), Vector3(door_w - 0.34, 0.28, 0.035), metal, false, pivot)
	_box(name + "_Handle", Vector3(door_w - 0.25, 1.46, handle_z), Vector3(0.08, 0.30, 0.08), metal, false, pivot)

	doors.append({
		"pivot": pivot,
		"closed": 0.0,
		"open": open_angle,
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
#  HALLWAY — corrected placement
# ──────────────────────────────────────────────────────────────────────────────
func _build_hallway() -> void:
	var blue: Material = _mat("locker_blue", Color(0.04, 0.10, 0.28))
	var wood: Material = _mat("wood", Color(0.22, 0.11, 0.06))

	# fixed: lockers face into the hall and stay away from doors
	_make_locker_bank("HallLockersA", Vector3(-47.0, 0.0, HALL_Z0 + WALL_T * 0.5 + 0.34), PI, 4, blue)
	_make_locker_bank("HallLockersB", Vector3(44.0, 0.0, HALL_Z1 - WALL_T * 0.5 - 0.34), 0.0, 4, blue)
	_make_locker_bank("HallLockersC", Vector3(-20.0, 0.0, HALL_Z0 + WALL_T * 0.5 + 0.34), PI, 3, blue)
	_make_locker_bank("HallLockersD", Vector3(14.0, 0.0, HALL_Z1 - WALL_T * 0.5 - 0.34), 0.0, 3, blue)

	# fixed: benches no longer block door paths
	_make_bench("BenchA", Vector3(-46.0, 0.0, HALL_Z1 - 1.1), 0.0, wood)
	_make_bench("BenchB", Vector3(46.0, 0.0, HALL_Z0 + 1.1), PI, wood)

	_make_trash_can("TrashHallA", Vector3(-25.0, 0.0, HALL_Z1 - 0.75))
	_make_trash_can("TrashHallB", Vector3(25.0, 0.0, HALL_Z0 + 0.75))
	_make_trash_can("TrashHallC", Vector3(8.0, 0.0, HALL_Z0 + 0.75))

	_make_water_fountain("WaterFountain", Vector3(HALL_X0 + 0.42, 0.0, -2.2), -PI * 0.5)

	# fixed: boards face the hallway
	# Replace the old crowded bulletin board with the Hall Monitor rule board.
	_make_rule_board("HallMonitorRuleBoard", Vector3(-43.0, 2.25, HALL_Z0 + 0.13), true)
	_make_bulletin_board("BulletinB", Vector3(45.0, 2.2, HALL_Z1 - 0.12), false)

	var light_xs: Array[float] = [-48.0, -32.0, -16.0, 0.0, 16.0, 32.0, 48.0]
	for x_value: float in light_xs:
		_make_light("HallLight" + str(x_value), Vector3(x_value, WALL_H - 0.08, 0.0))


func _make_locker_bank(name: String, pos: Vector3, rot_y: float, count: int, mat: Material) -> void:
	var node: Node3D = Node3D.new()
	node.name = name
	node.position = pos
	node.rotation.y = rot_y
	add_child(node)

	var shadow: Material = _mat("locker_shadow", Color(0.01, 0.02, 0.08))
	var metal: Material = _mat("lck_metal", Color(0.55, 0.52, 0.38))
	var plate: Material = _mat("lck_plate", Color(0.62, 0.60, 0.44))

	for i: int in range(count):
		var x: float = float(i) * 0.80
		_box(name + "_Body" + str(i), Vector3(x, 1.18, 0.0), Vector3(0.70, 2.36, 0.50), mat, true, node)
		_box(name + "_Inset" + str(i), Vector3(x, 1.20, -0.26), Vector3(0.52, 1.90, 0.02), shadow, false, node)
		_box(name + "_Handle" + str(i), Vector3(x + 0.22, 1.18, -0.30), Vector3(0.055, 0.32, 0.04), metal, false, node)
		_box(name + "_Num" + str(i), Vector3(x - 0.14, 2.10, -0.28), Vector3(0.18, 0.14, 0.02), plate, false, node)
		for sv: int in range(3):
			_box(name + "_Vent" + str(i) + "_" + str(sv), Vector3(x, 2.18 - float(sv) * 0.08, -0.29),
				Vector3(0.36, 0.025, 0.025), metal, false, node)


func _make_bench(name: String, pos: Vector3, rot_y: float, mat: Material) -> void:
	var node: Node3D = Node3D.new()
	node.name = name
	node.position = pos
	node.rotation.y = rot_y
	add_child(node)

	var dark: Material = _mat("bench_dark", Color(0.10, 0.06, 0.03))

	# Seat slats
	for si: int in range(3):
		_box(name + "_Slat" + str(si), Vector3(0.0, 0.52, -0.14 + float(si) * 0.14),
			Vector3(3.5, 0.07, 0.10), mat, true, node)

	# Real backrest, not a flat bed board
	for bi: int in range(2):
		_box(name + "_Back" + str(bi), Vector3(0.0, 0.92 + float(bi) * 0.26, 0.34),
			Vector3(3.5, 0.08, 0.12), mat, true, node)

	# Under-seat support
	_box(name + "_SeatFill", Vector3(0.0, 0.35, 0.0), Vector3(3.5, 0.32, 0.44), dark, true, node)

	# Legs and back posts
	for lx: float in [-1.45, 1.45]:
		_box(name + "_LegF" + str(lx), Vector3(lx, 0.22, -0.18), Vector3(0.12, 0.44, 0.12), dark, true, node)
		_box(name + "_LegR" + str(lx), Vector3(lx, 0.22, 0.22), Vector3(0.12, 0.44, 0.12), dark, true, node)
		_box(name + "_BackPost" + str(lx), Vector3(lx, 0.82, 0.34), Vector3(0.12, 0.88, 0.12), dark, true, node)
		_box(name + "_Brace" + str(lx), Vector3(lx, 0.18, 0.02), Vector3(0.12, 0.10, 0.42), dark, true, node)


func _make_trash_can(name: String, pos: Vector3) -> void:
	var node: Node3D = Node3D.new()
	node.name = name
	node.position = pos
	add_child(node)

	var body: Material = _mat("trash_body", Color(0.06, 0.07, 0.07))
	var lid: Material = _mat("trash_lid", Color(0.10, 0.11, 0.10))

	_box(name + "_Lower", Vector3(0.0, 0.30, 0.0), Vector3(0.52, 0.60, 0.52), body, true, node)
	_box(name + "_Upper", Vector3(0.0, 0.72, 0.0), Vector3(0.56, 0.24, 0.56), body, true, node)
	_box(name + "_Rim", Vector3(0.0, 0.86, 0.0), Vector3(0.60, 0.06, 0.60), lid, false, node)


func _make_bulletin_board(name: String, pos: Vector3, flip: bool = false) -> void:
	var node: Node3D = Node3D.new()
	node.name = name
	node.position = pos
	node.rotation.y = PI if flip else 0.0
	add_child(node)

	var board: Material = _mat("board", Color(0.22, 0.10, 0.05))
	var frame: Material = _mat("bb_frame", Color(0.08, 0.08, 0.07))
	var paper: Material = _mat("paper", Color(0.80, 0.76, 0.58))
	var red_p: Material = _mat("redpaper", Color(0.50, 0.08, 0.06))
	var blu_p: Material = _mat("bluepaper", Color(0.08, 0.14, 0.44))

	_box(name + "_Surf", Vector3(0.0, 0.0, 0.0), Vector3(7.0, 1.40, 0.06), board, false, node)
	_box(name + "_FrmT", Vector3(0.0, 0.72, 0.0), Vector3(7.20, 0.10, 0.09), frame, false, node)
	_box(name + "_FrmB", Vector3(0.0, -0.72, 0.0), Vector3(7.20, 0.10, 0.09), frame, false, node)
	_box(name + "_FrmL", Vector3(-3.55, 0.0, 0.0), Vector3(0.10, 1.60, 0.09), frame, false, node)
	_box(name + "_FrmR", Vector3(3.55, 0.0, 0.0), Vector3(0.10, 1.60, 0.09), frame, false, node)

	_box(name + "_P1", Vector3(-2.6, 0.20, -0.05), Vector3(1.0, 0.60, 0.03), paper, false, node)
	_box(name + "_P2", Vector3(-1.2, -0.10, -0.05), Vector3(0.80, 0.48, 0.03), red_p, false, node)
	_box(name + "_P3", Vector3(0.2, 0.25, -0.05), Vector3(1.1, 0.58, 0.03), paper, false, node)
	_box(name + "_P4", Vector3(1.8, -0.05, -0.05), Vector3(0.90, 0.50, 0.03), blu_p, false, node)


func _make_water_fountain(name: String, pos: Vector3, rot_y: float) -> void:
	var node: Node3D = Node3D.new()
	node.name = name
	node.position = pos
	node.rotation.y = rot_y
	add_child(node)

	var metal: Material = _mat("fountain", Color(0.40, 0.46, 0.44))
	var dark: Material = _mat("fountain_drk", Color(0.06, 0.07, 0.07))

	_box(name + "_Ped", Vector3(0.0, 0.45, 0.0), Vector3(0.60, 0.90, 0.20), metal, true, node)
	_box(name + "_Basin", Vector3(0.0, 0.76, -0.18), Vector3(0.68, 0.20, 0.40), metal, true, node)
	_box(name + "_BsnIn", Vector3(0.0, 0.82, -0.20), Vector3(0.52, 0.08, 0.32), dark, false, node)
	_box(name + "_Spout", Vector3(0.0, 0.98, -0.40), Vector3(0.08, 0.08, 0.18), dark, false, node)


func _make_rule_board(name: String, pos: Vector3, flip: bool = false) -> void:
	var node: Node3D = Node3D.new()
	node.name = name
	node.position = pos
	node.rotation.y = PI if flip else 0.0
	add_child(node)

	var bg: Material = _mat("rule_bg", Color(0.05, 0.05, 0.04))
	var frame: Material = _mat("rule_frame", Color(0.62, 0.52, 0.18))
	var red: Material = _mat("rule_red", Color(0.72, 0.08, 0.05))
	var cream: Material = _mat("rule_text_mat", Color(0.90, 0.84, 0.55))

	_box(name + "_Board", Vector3(0.0, 0.0, 0.0), Vector3(4.8, 1.75, 0.06), bg, false, node)
	_box(name + "_FrameT", Vector3(0.0, 0.91, 0.0), Vector3(5.0, 0.10, 0.09), frame, false, node)
	_box(name + "_FrameB", Vector3(0.0, -0.91, 0.0), Vector3(5.0, 0.10, 0.09), frame, false, node)
	_box(name + "_FrameL", Vector3(-2.45, 0.0, 0.0), Vector3(0.10, 1.85, 0.09), frame, false, node)
	_box(name + "_FrameR", Vector3(2.45, 0.0, 0.0), Vector3(0.10, 1.85, 0.09), frame, false, node)

	# Big real text, attached to the board surface.
	_make_board_text(name + "_Title", "HALL MONITOR", Vector3(0.0, 0.55, -0.055), 0.20, cream, node)
	_make_board_text(name + "_Rule1", "NO RUNNING", Vector3(0.0, 0.15, -0.055), 0.17, cream, node)
	_make_board_text(name + "_Rule2", "NO HUGGING", Vector3(0.0, -0.20, -0.055), 0.18, red, node)
	_make_board_text(name + "_Rule3", "NO FUN", Vector3(0.0, -0.55, -0.055), 0.17, cream, node)


func _make_board_text(name: String, text_value: String, local_pos: Vector3, size_value: float,
		material: Material, parent: Node) -> void:
	var text_mesh: TextMesh = TextMesh.new()
	text_mesh.text = text_value
	text_mesh.font_size = 32
	text_mesh.depth = 0.01
	text_mesh.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_mesh.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.name = name
	mesh_instance.mesh = text_mesh
	mesh_instance.material_override = material
	mesh_instance.position = local_pos
	mesh_instance.scale = Vector3(size_value, size_value, size_value)
	parent.add_child(mesh_instance)




# ──────────────────────────────────────────────────────────────────────────────
#  POOL ROOM
# ──────────────────────────────────────────────────────────────────────────────
func _build_pool() -> void:
	var water: Material = _mat("water", Color(0.16, 0.50, 0.64), 0.60)
	var tile: Material = _mat("pool_tile", Color(0.64, 0.66, 0.56))
	var red: Material = _mat("lane", Color(0.52, 0.06, 0.04))
	var bench_mat: Material = _mat("pool_bench", Color(0.28, 0.34, 0.32))

	# Water surface: transparent base plus simple wave strips/highlights
	_box("PoolWater", Vector3(0.0, -0.06, -20.0), Vector3(22.0, 0.08, 13.4), water, false)
	var water_hi: Material = _mat("water_highlight", Color(0.72, 0.92, 0.95), 0.36)
	var water_dark: Material = _mat("water_dark", Color(0.05, 0.28, 0.40), 0.32)
	for wz: float in [-25.0, -22.5, -20.0, -17.5, -15.0]:
		_box("PoolWaveA" + str(wz), Vector3(-3.5, 0.01, wz), Vector3(4.5, 0.018, 0.055), water_hi, false)
		_box("PoolWaveB" + str(wz), Vector3(4.5, 0.012, wz + 0.55), Vector3(5.5, 0.018, 0.05), water_hi, false)
	for wx: float in [-9.0, 9.0]:
		_box("PoolWaterEdge" + str(wx), Vector3(wx, 0.0, -20.0), Vector3(0.12, 0.018, 13.0), water_dark, false)

	_box("PoolBorderN", Vector3(0.0, 0.16, -26.9), Vector3(23.5, 0.16, 0.55), tile)
	_box("PoolBorderS", Vector3(0.0, 0.16, -13.1), Vector3(23.5, 0.16, 0.55), tile)
	_box("PoolBorderW", Vector3(-11.9, 0.16, -20.0), Vector3(0.55, 0.16, 14.2), tile)
	_box("PoolBorderE", Vector3(11.9, 0.16, -20.0), Vector3(0.55, 0.16, 14.2), tile)

	for x_value: float in [-7.0, 0.0, 7.0]:
		_box("PoolLane" + str(x_value), Vector3(x_value, 0.005, -20.0), Vector3(0.10, 0.025, 13.4), red, false)

	# Benches face the pool, not the wall
	_make_bench("PoolBenchA", Vector3(-24.0, 0.0, -15.2), -PI * 0.5, bench_mat)
	_make_bench("PoolBenchB", Vector3(24.0, 0.0, -24.8), PI * 0.5, bench_mat)

	_make_locker_bank("PoolLockers", Vector3(POOL_X0 + 0.50, 0.0, -28.5), PI * 0.5, 5,
		_mat("pool_locker", Color(0.06, 0.16, 0.20)))

	_make_lifeguard_chair(Vector3(15.0, 0.0, -11.8))
	_make_equipment_bin("PoolEquipBin", Vector3(-21.5, 0.0, -28.5))

	for px: float in [-10.0, 10.0]:
		_make_light("PoolLight" + str(px), Vector3(px, WALL_H - 0.08, -20.0))


func _make_equipment_bin(name: String, pos: Vector3) -> void:
	var node: Node3D = Node3D.new()
	node.name = name
	node.position = pos
	add_child(node)

	var bin: Material = _mat("equip_bin", Color(0.58, 0.52, 0.20))
	var rim: Material = _mat("equip_rim", Color(0.26, 0.24, 0.10))

	_box(name + "_Body", Vector3(0.0, 0.40, 0.0), Vector3(2.0, 0.80, 0.80), bin, true, node)
	_box(name + "_Rim", Vector3(0.0, 0.82, 0.0), Vector3(2.10, 0.08, 0.90), rim, false, node)
	_box(name + "_Board1", Vector3(-0.20, 1.00, 0.0), Vector3(0.55, 0.12, 0.72), _mat("kb_y", Color(0.78, 0.65, 0.12)), false, node)
	_box(name + "_Board2", Vector3(0.35, 1.04, 0.0), Vector3(0.55, 0.12, 0.68), _mat("kb_r", Color(0.72, 0.22, 0.12)), false, node)


func _make_lifeguard_chair(pos: Vector3) -> void:
	var node: Node3D = Node3D.new()
	node.name = "LifeguardChair"
	node.position = pos
	add_child(node)

	var mat: Material = _mat("lifeguard", Color(0.80, 0.70, 0.42))
	var metal: Material = _mat("lg_metal", Color(0.52, 0.50, 0.36))
	var red: Material = _mat("lg_red", Color(0.60, 0.08, 0.06))

	_box("LGSeat", Vector3(0.0, 2.16, 0.0), Vector3(1.15, 0.18, 0.88), mat, true, node)
	_box("LGBack", Vector3(0.0, 2.62, 0.44), Vector3(1.15, 0.70, 0.16), mat, true, node)
	for lx: float in [-0.42, 0.42]:
		for lz: float in [-0.30, 0.30]:
			_box("LGLeg", Vector3(lx, 1.08, lz), Vector3(0.10, 2.16, 0.10), metal, true, node)
	_box("LGStep1", Vector3(0.0, 0.82, -0.72), Vector3(1.15, 0.08, 0.14), metal, true, node)
	_box("LGStep2", Vector3(0.0, 1.28, -0.72), Vector3(1.15, 0.08, 0.14), metal, true, node)
	_cylinder("LGTube", Vector3(0.68, 2.20, 0.0), 0.12, 0.90, red, false, node)


# ──────────────────────────────────────────────────────────────────────────────
#  CLASSROOM
# ──────────────────────────────────────────────────────────────────────────────
func _build_classroom() -> void:
	var desk_top: Material = _mat("desk_top", Color(0.28, 0.15, 0.08))
	var desk_body: Material = _mat("desk_body", Color(0.18, 0.09, 0.04))
	var chair_mat: Material = _mat("chair", Color(0.05, 0.10, 0.30))
	var metal: Material = _mat("cls_metal", Color(0.08, 0.09, 0.09))
	var board: Material = _mat("blackboard", Color(0.02, 0.10, 0.06))
	var chalk: Material = _mat("chalk", Color(0.64, 0.66, 0.58))

	# board is on west wall, clear and flush
	_box("ClassBoard", Vector3(CLASS_X0 + 0.15, 2.40, 20.0), Vector3(0.08, 1.50, 9.2), board, false)
	_box("ClassBoardTray", Vector3(CLASS_X0 + 0.22, 1.56, 20.0), Vector3(0.16, 0.09, 9.5), chalk)

	_make_teacher_station("TeacherStation", Vector3(CLASS_X0 + 4.5, 0.0, 18.5), desk_top, desk_body)

	# desks keep a clear line from door to room
	var xs: Array[float] = [-45.5, -38.0, -30.5, -23.2]
	var zs: Array[float] = [15.0, 21.0, 27.0]
	var idx: int = 0
	for z_value: float in zs:
		for x_value: float in xs:
			_make_student_desk("SD" + str(idx), Vector3(x_value, 0.0, z_value), 0.0, desk_top, desk_body, chair_mat, metal)
			idx += 1

	# Bookshelves: flush against the east wall, turned so the shelves face into the classroom.
	_make_bookshelf("ClassShelfA", Vector3(CLASS_X1 - 0.55, 0.0, 12.5), PI * 0.5)
	_make_bookshelf("ClassShelfB", Vector3(CLASS_X1 - 0.55, 0.0, 19.0), PI * 0.5)

	for cx: float in [-44.0, -36.0, -28.0]:
		for cz: float in [14.0, 22.0, 30.0]:
			_make_light("ClassLight" + str(cx) + "_" + str(cz), Vector3(cx, WALL_H - 0.08, cz))


func _make_teacher_station(name: String, pos: Vector3, top_mat: Material, body_mat: Material) -> void:
	var node: Node3D = Node3D.new()
	node.name = name
	node.position = pos
	add_child(node)

	var metal: Material = _mat("ts_metal", Color(0.10, 0.10, 0.10))
	var paper: Material = _mat("paper", Color(0.80, 0.76, 0.58))

	_box(name + "_Top", Vector3(0.0, 0.88, 0.0), Vector3(3.4, 0.16, 1.20), top_mat, true, node)
	_box(name + "_Front", Vector3(0.0, 0.48, 0.52), Vector3(3.4, 0.72, 0.14), body_mat, true, node)
	_box(name + "_PedL", Vector3(-1.52, 0.44, 0.0), Vector3(0.30, 0.88, 1.05), body_mat, true, node)
	_box(name + "_PedR", Vector3(1.52, 0.44, 0.0), Vector3(0.30, 0.88, 1.05), body_mat, true, node)
	_box(name + "_PaperA", Vector3(-0.3, 0.97, 0.0), Vector3(0.75, 0.04, 0.55), paper, false, node)
	_box(name + "_NamePl", Vector3(0.0, 0.94, -0.45), Vector3(1.10, 0.12, 0.04), metal, false, node)


func _make_student_desk(name: String, pos: Vector3, rot_y: float,
		top_mat: Material, body_mat: Material, chair_mat: Material, metal_mat: Material) -> void:
	var node: Node3D = Node3D.new()
	node.name = name
	node.position = pos
	node.rotation.y = rot_y
	add_child(node)

	_box(name + "_Top", Vector3(0.0, 0.74, 0.0), Vector3(1.95, 0.12, 1.05), top_mat, true, node)
	_box(name + "_Bin", Vector3(0.0, 0.46, 0.20), Vector3(1.55, 0.22, 0.60), body_mat, true, node)

	for lx: float in [-0.80, 0.80]:
		for lz: float in [-0.38, 0.38]:
			_box(name + "_Leg", Vector3(lx, 0.32, lz), Vector3(0.07, 0.64, 0.07), metal_mat, true, node)

	_box(name + "_CSeat", Vector3(0.0, 0.44, 1.10), Vector3(0.98, 0.12, 0.78), chair_mat, true, node)
	_box(name + "_CBack", Vector3(0.0, 0.88, 1.48), Vector3(0.98, 0.70, 0.12), chair_mat, true, node)

	# Chair legs so the chair does not float
	for clx: float in [-0.42, 0.42]:
		for clz: float in [0.80, 1.40]:
			_box(name + "_CLeg", Vector3(clx, 0.20, clz), Vector3(0.06, 0.40, 0.06), metal_mat, true, node)


func _make_bookshelf(name: String, pos: Vector3, rot_y: float) -> void:
	var node: Node3D = Node3D.new()
	node.name = name
	node.position = pos
	node.rotation.y = rot_y
	add_child(node)

	var wood: Material = _mat("shelf_wood", Color(0.16, 0.08, 0.04))
	var red: Material = _mat("book_red", Color(0.48, 0.07, 0.06))
	var blue: Material = _mat("book_blue", Color(0.05, 0.08, 0.42))
	var green: Material = _mat("book_green", Color(0.08, 0.28, 0.12))
	var dark: Material = _mat("book_dark", Color(0.10, 0.06, 0.04))

	_box(name + "_Back", Vector3(0.0, 1.30, 0.02), Vector3(3.10, 2.60, 0.28), wood, true, node)
	for sy: float in [0.10, 0.80, 1.50, 2.20, 2.60]:
		_box(name + "_Shelf" + str(sy), Vector3(0.0, sy, -0.22), Vector3(3.10, 0.07, 0.50), wood, true, node)

	var book_mats: Array[Material] = [red, blue, green, dark, red, blue, green, dark, red, blue, green, dark, red, blue]
	for bi: int in range(14):
		var bx: float = -1.30 + float(bi % 7) * 0.40
		var by: float = 0.46 + float(bi / 7) * 0.70
		var bh: float = 0.38 + float(bi % 3) * 0.07
		_box(name + "_Book" + str(bi), Vector3(bx, by, -0.46), Vector3(0.12, bh, 0.20), book_mats[bi], false, node)


# ──────────────────────────────────────────────────────────────────────────────
#  LAB
# ──────────────────────────────────────────────────────────────────────────────
func _build_lab() -> void:
	var table: Material = _mat("lab_table", Color(0.04, 0.14, 0.12))
	var cabinet: Material = _mat("lab_cabinet", Color(0.10, 0.22, 0.14))
	var black: Material = _mat("black", Color(0.02, 0.02, 0.02))

	# tables leave central walking path and door area clear
	for zt: float in [14.5, 23.5]:
		_make_lab_table("LabTableA" + str(zt), Vector3(-9.0, 0.0, zt), table)
		_make_lab_table("LabTableB" + str(zt), Vector3(9.0, 0.0, zt), table)

	_make_lab_wall_cabinet("LabCabL", Vector3(LAB_X0 + 1.4, 0.0, ROOM_Z1 - 0.42), cabinet)
	_make_lab_wall_cabinet("LabCabR", Vector3(LAB_X1 - 1.4, 0.0, ROOM_Z1 - 0.42), cabinet)
	_make_lab_counter("LabCounter", Vector3(0.0, 0.0, ROOM_Z1 - 0.42), cabinet)

	_box("LabBoard", Vector3(LAB_X0 + 0.14, 2.30, 19.0), Vector3(0.07, 1.35, 7.5), _mat("lab_board", Color(0.02, 0.10, 0.06)), false)

	for mx: float in [-9.0, 9.0]:
		for mz: float in [14.5, 23.5]:
			_make_microscope("Micro" + str(mx) + "_" + str(mz), Vector3(mx, 0.98, mz), black)

	for bi: int in range(8):
		var bx: float = -2.2 + float(bi) * 0.58
		_cylinder("Bottle" + str(bi), Vector3(bx, 1.08, ROOM_Z1 - 0.78), 0.10, 0.46, _mat("chem" + str(bi), Color(0.60, 0.08 + float(bi % 4) * 0.08, 0.08)), false)
		_cylinder("BottleCap" + str(bi), Vector3(bx, 1.34, ROOM_Z1 - 0.78), 0.06, 0.06, black, false)

	_make_eyewash("LabEyewash", Vector3(LAB_X1 - 0.85, 1.20, 10.0))

	for lx: float in [-9.0, 0.0, 9.0]:
		for lz: float in [13.0, 21.0, 29.5]:
			_make_light("LabLight_" + str(lx) + "_" + str(lz), Vector3(lx, WALL_H - 0.08, lz))


func _make_lab_table(name: String, pos: Vector3, mat: Material) -> void:
	var node: Node3D = Node3D.new()
	node.name = name
	node.position = pos
	add_child(node)

	var base_mat: Material = _mat("lab_base", Color(0.03, 0.08, 0.06))
	var sink_mat: Material = _mat("sink", Color(0.46, 0.50, 0.50))
	var metal: Material = _mat("lab_metal", Color(0.32, 0.32, 0.28))

	_box(name + "_Top", Vector3(0.0, 0.88, 0.0), Vector3(5.2, 0.18, 1.75), mat, true, node)
	_box(name + "_Base", Vector3(0.0, 0.46, 0.0), Vector3(5.0, 0.70, 1.55), base_mat, true, node)

	for lx: float in [-2.40, 2.40]:
		for lz: float in [-0.70, 0.70]:
			_box(name + "_Leg", Vector3(lx, 0.44, lz), Vector3(0.08, 0.88, 0.08), metal, true, node)

	_box(name + "_SinkTop", Vector3(1.6, 0.95, 0.0), Vector3(0.80, 0.06, 0.58), sink_mat, false, node)
	_box(name + "_Tap", Vector3(1.6, 1.04, -0.25), Vector3(0.06, 0.20, 0.06), metal, false, node)


func _make_lab_wall_cabinet(name: String, pos: Vector3, mat: Material) -> void:
	var node: Node3D = Node3D.new()
	node.name = name
	node.position = pos
	add_child(node)

	var metal: Material = _mat("lab_cab_met", Color(0.52, 0.50, 0.36))
	var dark: Material = _mat("lab_cab_drk", Color(0.04, 0.06, 0.04))

	_box(name + "_Body", Vector3(0.0, 1.08, 0.0), Vector3(2.0, 2.16, 0.75), mat, true, node)
	_box(name + "_DoorL", Vector3(-0.52, 1.08, -0.39), Vector3(0.85, 1.90, 0.04), mat, false, node)
	_box(name + "_DoorR", Vector3(0.52, 1.08, -0.39), Vector3(0.85, 1.90, 0.04), mat, false, node)
	_box(name + "_Gap", Vector3(0.0, 1.08, -0.39), Vector3(0.04, 1.90, 0.04), dark, false, node)
	_box(name + "_HndL", Vector3(-0.10, 1.08, -0.44), Vector3(0.06, 0.28, 0.04), metal, false, node)
	_box(name + "_HndR", Vector3(0.10, 1.08, -0.44), Vector3(0.06, 0.28, 0.04), metal, false, node)


func _make_lab_counter(name: String, pos: Vector3, mat: Material) -> void:
	var node: Node3D = Node3D.new()
	node.name = name
	node.position = pos
	add_child(node)

	var top: Material = _mat("counter_top", Color(0.06, 0.18, 0.14))
	_box(name + "_Top", Vector3(0.0, 0.92, 0.0), Vector3(5.0, 0.10, 0.75), top, true, node)
	_box(name + "_Body", Vector3(0.0, 0.46, 0.0), Vector3(5.0, 0.84, 0.72), mat, true, node)


func _make_microscope(name: String, pos: Vector3, mat: Material) -> void:
	var node: Node3D = Node3D.new()
	node.name = name
	node.position = pos
	add_child(node)

	_box(name + "_Base", Vector3(0.0, 0.04, 0.0), Vector3(0.58, 0.08, 0.42), mat, false, node)
	_box(name + "_Arm", Vector3(0.06, 0.32, 0.0), Vector3(0.09, 0.54, 0.09), mat, false, node)
	_box(name + "_Head", Vector3(0.20, 0.60, -0.05), Vector3(0.38, 0.14, 0.18), mat, false, node)
	_box(name + "_Eye", Vector3(0.28, 0.70, -0.05), Vector3(0.07, 0.18, 0.07), mat, false, node)


func _make_eyewash(name: String, pos: Vector3) -> void:
	var node: Node3D = Node3D.new()
	node.name = name
	node.position = pos
	add_child(node)

	var metal: Material = _mat("eyewash_met", Color(0.46, 0.50, 0.48))
	var green: Material = _mat("eyewash_grn", Color(0.12, 0.50, 0.18))

	_box(name + "_Mount", Vector3(0.0, 0.0, 0.0), Vector3(0.14, 0.30, 0.14), metal, false, node)
	_box(name + "_Bowl", Vector3(0.0, 0.16, -0.10), Vector3(0.30, 0.12, 0.28), metal, false, node)
	_box(name + "_Sign", Vector3(0.0, 0.35, -0.05), Vector3(0.22, 0.12, 0.04), green, false, node)


# ──────────────────────────────────────────────────────────────────────────────
#  OFFICE — cleaned layout
# ──────────────────────────────────────────────────────────────────────────────
func _build_office() -> void:
	var desk_top: Material = _mat("off_desk_top", Color(0.22, 0.10, 0.06))
	var desk_body: Material = _mat("off_desk_body", Color(0.14, 0.06, 0.03))
	var chair_mat: Material = _mat("off_chair", Color(0.04, 0.04, 0.07))
	var couch_mat: Material = _mat("couch", Color(0.04, 0.08, 0.28))
	var file_mat: Material = _mat("file_cabinet", Color(0.20, 0.24, 0.26))

	# clear office door path. Desk is inside, not blocking entry.
	_make_principal_desk("PrincipalDesk", Vector3(32.5, 0.0, 27.8), PI, desk_top, desk_body)
	# Chair fixed: faces the desk/visitor direction instead of being backwards.
	_make_office_chair("PrincipalChair", Vector3(32.5, 0.0, 30.4), 0.0, chair_mat)

	# couch against east wall, facing into room
	_make_couch("OfficeCouch", Vector3(OFFICE_X1 - 2.75, 0.0, 18.5), PI * 0.5, couch_mat)

	_make_filing("FilingA", Vector3(21.0, 0.0, ROOM_Z1 - 0.75), 0.0, file_mat)
	_make_filing("FilingB", Vector3(23.5, 0.0, ROOM_Z1 - 0.75), 0.0, file_mat)
	_make_bookshelf("OfficeShelf", Vector3(48.0, 0.0, ROOM_Z1 - 1.35), 0.0)

	# side table moved away from door and center path
	_make_side_table("OfficeSideTable", Vector3(44.0, 0.0, 14.5), chair_mat)

	# Removed the old front-wall picture/blackboard because it visually overlaps the office door area.
	# Keep this wall cleaner so the entrance reads clearly.

	var paper: Material = _mat("paper", Color(0.80, 0.76, 0.58))
	_box("OfficePaperA", Vector3(32.0, 1.02, 27.2), Vector3(0.75, 0.04, 0.52), paper, false)
	_box("OfficePaperB", Vector3(33.2, 1.03, 27.0), Vector3(0.65, 0.04, 0.44), _mat("paper_b", Color(0.62, 0.68, 0.80)), false)

	_make_desk_lamp("OfficeLamp", Vector3(31.5, 0.96, 27.4))
	_make_desk_phone("OfficePhone", Vector3(34.2, 0.96, 27.8))

	var plaque: Material = _mat("plaque", Color(0.55, 0.46, 0.22))
	_box("PlaqueA", Vector3(OFFICE_X1 - 0.14, 2.60, 20.8), Vector3(0.05, 0.60, 1.20), plaque, false)
	_box("PlaqueB", Vector3(OFFICE_X1 - 0.14, 2.60, 25.6), Vector3(0.05, 0.60, 1.20), plaque, false)

	for ox: float in [26.0, 36.0, 46.0]:
		for oz: float in [13.0, 21.0, 29.5]:
			_make_light("OfficeLight_" + str(ox) + "_" + str(oz), Vector3(ox, WALL_H - 0.08, oz))


func _make_principal_desk(name: String, pos: Vector3, rot_y: float, top_mat: Material, body_mat: Material) -> void:
	var node: Node3D = Node3D.new()
	node.name = name
	node.position = pos
	node.rotation.y = rot_y
	add_child(node)

	var metal: Material = _mat("desk_metal", Color(0.10, 0.10, 0.10))

	_box(name + "_MainTop", Vector3(0.0, 0.90, 0.0), Vector3(3.4, 0.14, 1.25), top_mat, true, node)
	_box(name + "_RetTop", Vector3(-1.20, 0.90, -1.05), Vector3(1.0, 0.14, 2.10), top_mat, true, node)
	_box(name + "_FrontPnl", Vector3(0.0, 0.50, 0.55), Vector3(3.3, 0.76, 0.12), body_mat, true, node)
	_box(name + "_PedL", Vector3(-1.55, 0.44, 0.0), Vector3(0.28, 0.88, 1.12), body_mat, true, node)
	_box(name + "_PedR", Vector3(1.55, 0.44, 0.0), Vector3(0.28, 0.88, 1.12), body_mat, true, node)
	for di: int in range(3):
		_box(name + "_Drw" + str(di), Vector3(1.55, 0.28 + float(di) * 0.28, -0.58), Vector3(0.24, 0.20, 0.06), metal, false, node)


func _make_office_chair(name: String, pos: Vector3, rot_y: float, mat: Material) -> void:
	var node: Node3D = Node3D.new()
	node.name = name
	node.position = pos
	node.rotation.y = rot_y
	add_child(node)

	var metal: Material = _mat("off_ch_met", Color(0.10, 0.10, 0.10))

	_box(name + "_Seat", Vector3(0.0, 0.62, 0.0), Vector3(1.12, 0.16, 1.02), mat, true, node)
	_box(name + "_Back", Vector3(0.0, 1.25, 0.46), Vector3(1.12, 1.15, 0.16), mat, true, node)
	_box(name + "_ArmL", Vector3(-0.55, 0.90, 0.0), Vector3(0.08, 0.12, 0.90), metal, true, node)
	_box(name + "_ArmR", Vector3(0.55, 0.90, 0.0), Vector3(0.08, 0.12, 0.90), metal, true, node)
	_box(name + "_Post", Vector3(0.0, 0.30, 0.0), Vector3(0.14, 0.60, 0.14), metal, true, node)
	_box(name + "_Base", Vector3(0.0, 0.08, 0.0), Vector3(0.90, 0.08, 0.90), metal, true, node)
	for ci: int in range(5):
		var ang: float = float(ci) * TAU / 5.0
		_box(name + "_Caster" + str(ci), Vector3(cos(ang) * 0.42, 0.04, sin(ang) * 0.42), Vector3(0.08, 0.08, 0.08), metal, false, node)


func _make_couch(name: String, pos: Vector3, rot_y: float, mat: Material) -> void:
	var node: Node3D = Node3D.new()
	node.name = name
	node.position = pos
	node.rotation.y = rot_y
	add_child(node)

	var dark_mat: Material = _mat("couch_dark", Color(0.02, 0.04, 0.16))
	for ci: int in range(3):
		_box(name + "_Cush" + str(ci), Vector3(-1.22 + float(ci) * 1.22, 0.58, 0.0), Vector3(1.14, 0.38, 1.16), mat, true, node)
		_box(name + "_BCush" + str(ci), Vector3(-1.22 + float(ci) * 1.22, 1.12, 0.54), Vector3(1.14, 1.04, 0.36), mat, true, node)
	_box(name + "_Base", Vector3(0.0, 0.35, 0.0), Vector3(4.25, 0.30, 1.22), dark_mat, true, node)
	_box(name + "_ArmL", Vector3(-2.26, 0.88, 0.0), Vector3(0.32, 1.00, 1.28), mat, true, node)
	_box(name + "_ArmR", Vector3(2.26, 0.88, 0.0), Vector3(0.32, 1.00, 1.28), mat, true, node)


func _make_filing(name: String, pos: Vector3, rot_y: float, mat: Material) -> void:
	var node: Node3D = Node3D.new()
	node.name = name
	node.position = pos
	node.rotation.y = rot_y
	add_child(node)

	var metal: Material = _mat("file_metal", Color(0.52, 0.50, 0.36))
	var drw_mat: Material = _mat("file_drawer", Color(0.16, 0.19, 0.21))

	_box(name + "_Body", Vector3(0.0, 1.08, 0.0), Vector3(1.25, 2.16, 0.88), mat, true, node)
	for dy: float in [0.40, 0.90, 1.40, 1.90]:
		_box(name + "_Drw" + str(dy), Vector3(0.0, dy, -0.46), Vector3(1.05, 0.40, 0.04), drw_mat, false, node)
		_box(name + "_Pull" + str(dy), Vector3(0.0, dy, -0.51), Vector3(0.45, 0.06, 0.04), metal, false, node)


func _make_side_table(name: String, pos: Vector3, chair_mat: Material) -> void:
	var node: Node3D = Node3D.new()
	node.name = name
	node.position = pos
	add_child(node)

	var top: Material = _mat("side_top", Color(0.20, 0.10, 0.06))
	var leg: Material = _mat("side_leg", Color(0.08, 0.08, 0.08))

	_box(name + "_Top", Vector3(0.0, 0.76, 0.0), Vector3(2.0, 0.10, 0.90), top, true, node)
	for tlx: float in [-0.85, 0.85]:
		for tlz: float in [-0.35, 0.35]:
			_box(name + "_Leg", Vector3(tlx, 0.36, tlz), Vector3(0.06, 0.72, 0.06), leg, true, node)

	_box(name + "_Chair1Seat", Vector3(-1.50, 0.44, 0.0), Vector3(0.80, 0.12, 0.70), chair_mat, true, node)
	_box(name + "_Chair1Back", Vector3(-1.50, 0.82, 0.34), Vector3(0.80, 0.65, 0.12), chair_mat, true, node)
	_box(name + "_Chair2Seat", Vector3(1.50, 0.44, 0.0), Vector3(0.80, 0.12, 0.70), chair_mat, true, node)
	_box(name + "_Chair2Back", Vector3(1.50, 0.82, 0.34), Vector3(0.80, 0.65, 0.12), chair_mat, true, node)

	# Chair legs restored
	for cx: float in [-1.50, 1.50]:
		for lx: float in [-0.30, 0.30]:
			for lz: float in [-0.24, 0.24]:
				_box(name + "_ChairLeg", Vector3(cx + lx, 0.22, lz), Vector3(0.06, 0.44, 0.06), leg, true, node)


func _make_desk_lamp(name: String, pos: Vector3) -> void:
	var node: Node3D = Node3D.new()
	node.name = name
	node.position = pos
	add_child(node)

	var metal: Material = _mat("lamp_metal", Color(0.12, 0.12, 0.10))
	var shade: Material = _mat("lamp_shade", Color(0.58, 0.52, 0.28))
	var bulb: Material = _mat("lamp_bulb", Color(0.96, 0.90, 0.52))

	_box(name + "_Base", Vector3(0.0, 0.04, 0.0), Vector3(0.22, 0.08, 0.22), metal, false, node)
	_box(name + "_Pole", Vector3(0.0, 0.24, 0.0), Vector3(0.05, 0.48, 0.05), metal, false, node)
	_box(name + "_Shade", Vector3(0.14, 0.44, 0.0), Vector3(0.22, 0.18, 0.18), shade, false, node)
	_box(name + "_Bulb", Vector3(0.14, 0.38, 0.0), Vector3(0.08, 0.08, 0.08), bulb, false, node)

	var lamp_light: OmniLight3D = OmniLight3D.new()
	lamp_light.name = name + "_Omni"
	lamp_light.position = node.global_position + Vector3(0.14, 0.35, 0.0)
	lamp_light.light_color = Color(1.0, 0.88, 0.55)
	lamp_light.light_energy = 0.30
	lamp_light.omni_range = 4.0
	add_child(lamp_light)


func _make_desk_phone(name: String, pos: Vector3) -> void:
	var node: Node3D = Node3D.new()
	node.name = name
	node.position = pos
	add_child(node)

	var body: Material = _mat("phone_body", Color(0.08, 0.09, 0.09))
	var keys: Material = _mat("phone_keys", Color(0.14, 0.14, 0.12))

	_box(name + "_Body", Vector3(0.0, 0.04, 0.0), Vector3(0.55, 0.08, 0.42), body, false, node)
	_box(name + "_KeyPad", Vector3(0.0, 0.08, 0.05), Vector3(0.36, 0.04, 0.28), keys, false, node)
	_box(name + "_Handset", Vector3(0.10, 0.14, -0.10), Vector3(0.22, 0.07, 0.48), body, false, node)


func _pickup_ball(name: String, pos: Vector3, radius: float, material: Material,
		mass_value: float = 0.40) -> RigidBody3D:
	var body: RigidBody3D = RigidBody3D.new()
	body.name = name
	body.position = pos
	body.mass = mass_value
	body.gravity_scale = 1.0
	body.linear_damp = 0.15
	body.angular_damp = 0.10
	body.add_to_group("pickup")
	add_child(body)

	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 6

	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	body.add_child(mesh_instance)

	var shape: SphereShape3D = SphereShape3D.new()
	shape.radius = radius

	var collision_shape: CollisionShape3D = CollisionShape3D.new()
	collision_shape.shape = shape
	body.add_child(collision_shape)

	return body


func _pickup_detailed_cylinder(name: String, pos: Vector3, radius: float, height: float,
		body_mat: Material, cap_mat: Material, mass_value: float = 0.35) -> RigidBody3D:
	var body: RigidBody3D = _pickup_cylinder(name, pos, radius, height, body_mat, mass_value)
	_cylinder(name + "_CapTop", Vector3(0.0, height * 0.5 + 0.04, 0.0), radius * 0.78, 0.08, cap_mat, false, body)
	_cylinder(name + "_CapBottom", Vector3(0.0, -height * 0.5 - 0.02, 0.0), radius * 0.82, 0.04, cap_mat, false, body)
	_box(name + "_Label", Vector3(0.0, 0.0, -radius - 0.012), Vector3(radius * 1.35, height * 0.38, 0.025), _mat(name + "_label", Color(0.86, 0.82, 0.62)), false, body)
	return body


func _pickup_clipboard(name: String, pos: Vector3) -> RigidBody3D:
	var board: RigidBody3D = _pickup_box(name, pos, Vector3(0.75, 0.08, 0.50), _mat(name + "_wood", Color(0.40, 0.24, 0.10)), 0.35)
	_box(name + "_Paper", Vector3(0.0, 0.055, 0.0), Vector3(0.62, 0.025, 0.40), _mat(name + "_paper", Color(0.82, 0.78, 0.62)), false, board)
	_box(name + "_Clip", Vector3(0.0, 0.085, -0.20), Vector3(0.28, 0.035, 0.06), _mat(name + "_clip", Color(0.58, 0.56, 0.42)), false, board)
	return board


# ──────────────────────────────────────────────────────────────────────────────
#  PICKUPS
# ──────────────────────────────────────────────────────────────────────────────
func _build_pickups() -> void:
	# Hallway throwables
	_pickup_box("PickupNotebookHall", Vector3(-12.0, 0.23, 1.8), Vector3(0.65, 0.08, 0.45), _mat("book_blue", Color(0.05, 0.10, 0.45)), 0.35)
	_pickup_box("PickupFolderHall", Vector3(18.0, 0.22, -1.7), Vector3(0.75, 0.06, 0.50), _mat("folder", Color(0.74, 0.62, 0.20)), 0.25)
	_pickup_detailed_cylinder("PickupBottleHall", Vector3(26.5, 0.34, 1.7), 0.18, 0.65, _mat("bottle", Color(0.40, 0.66, 0.76), 0.65), _mat("bottle_cap", Color(0.08, 0.10, 0.10)), 0.25)
	_pickup_ball("PickupBasketballHall", Vector3(-41.0, 0.42, 1.8), 0.34, _mat("basketball", Color(0.78, 0.30, 0.08)), 0.55)
	_pickup_ball("PickupSoccerBallHall", Vector3(-39.9, 0.38, 2.6), 0.32, _mat("soccer_ball", Color(0.86, 0.84, 0.74)), 0.45)
	_pickup_box("PickupLooseBinderHall", Vector3(39.0, 0.24, -1.6), Vector3(0.82, 0.12, 0.55), _mat("binder_red", Color(0.50, 0.08, 0.08)), 0.32)
	_pickup_box("PickupWetFloorSign", Vector3(6.4, 0.55, 2.2), Vector3(0.55, 0.90, 0.12), _mat("wet_floor", Color(0.88, 0.70, 0.08)), 0.45)

	# Classroom throwables
	_pickup_box("PickupBackpackClass", Vector3(-24.0, 0.46, 28.0), Vector3(0.90, 0.55, 0.75), _mat("backpack", Color(0.14, 0.06, 0.22)), 0.90)
	_pickup_box("PickupEraserClass", Vector3(CLASS_X0 + 0.42, 1.70, 20.5), Vector3(0.45, 0.12, 0.22), _mat("eraser", Color(0.12, 0.12, 0.10)), 0.25)
	_pickup_box("PickupLooseBookClass", Vector3(-39.0, 0.90, 15.0), Vector3(0.55, 0.12, 0.42), _mat("book_green_pick", Color(0.08, 0.28, 0.12)), 0.30)
	_pickup_box("PickupPencilBoxClass", Vector3(-31.0, 0.88, 21.2), Vector3(0.45, 0.15, 0.25), _mat("pencil_box", Color(0.70, 0.50, 0.12)), 0.22)
	_pickup_ball("PickupDodgeballClass", Vector3(-47.5, 0.36, 30.0), 0.30, _mat("dodgeball", Color(0.55, 0.08, 0.08)), 0.45)
	_pickup_clipboard("PickupDetentionSlipBoardClass", Vector3(-50.0, 0.90, 14.0))

	# Lab throwables: more interactive small science objects, with cylinder details
	_pickup_box("PickupBeakerLab", Vector3(9.0, 1.08, 14.5), Vector3(0.34, 0.34, 0.34), _mat("beaker", Color(0.56, 0.78, 0.82), 0.55), 0.25)
	_pickup_box("PickupLabTray", Vector3(-9.0, 1.05, 23.5), Vector3(0.90, 0.10, 0.55), _mat("lab_tray", Color(0.18, 0.18, 0.16)), 0.35)
	_pickup_detailed_cylinder("PickupChemicalJarA", Vector3(-7.9, 1.18, 14.0), 0.16, 0.42, _mat("chem_jar_a", Color(0.56, 0.14, 0.10), 0.72), _mat("jar_cap_a", Color(0.10, 0.10, 0.10)), 0.24)
	_pickup_detailed_cylinder("PickupChemicalJarB", Vector3(7.6, 1.18, 23.0), 0.16, 0.42, _mat("chem_jar_b", Color(0.10, 0.38, 0.55), 0.72), _mat("jar_cap_b", Color(0.10, 0.10, 0.10)), 0.24)
	_pickup_detailed_cylinder("PickupTestTubeRack", Vector3(0.5, 1.08, ROOM_Z1 - 0.90), 0.18, 0.45, _mat("tube_rack", Color(0.36, 0.36, 0.30)), _mat("tube_cap", Color(0.70, 0.70, 0.62)), 0.28)
	_pickup_ball("PickupFoamBallLab", Vector3(13.5, 0.34, 28.8), 0.28, _mat("foam_ball", Color(0.20, 0.55, 0.42)), 0.35)
	_pickup_box("PickupSafetyGogglesLab", Vector3(-4.5, 1.05, 23.5), Vector3(0.55, 0.12, 0.22), _mat("goggles", Color(0.18, 0.28, 0.32), 0.65), 0.18)

	# Office throwables: more Hall Monitor / principal office flavor
	_pickup_clipboard("PickupClipboardOffice", Vector3(35.8, 1.12, 28.1))
	_pickup_box("PickupDeskLampOffice", Vector3(31.5, 1.22, 27.9), Vector3(0.28, 0.42, 0.28), _mat("lamp_pickup", Color(0.58, 0.52, 0.28)), 0.45)
	_pickup_box("PickupOfficeFolder", Vector3(44.0, 0.92, 14.5), Vector3(0.72, 0.08, 0.46), _mat("office_folder", Color(0.12, 0.16, 0.48)), 0.25)
	_pickup_ball("PickupStressBallOffice", Vector3(47.8, 0.32, 16.8), 0.22, _mat("stress_ball", Color(0.80, 0.55, 0.10)), 0.20)
	_pickup_detailed_cylinder("PickupCoffeeCupOffice", Vector3(33.8, 1.15, 27.1), 0.16, 0.28, _mat("coffee_cup", Color(0.72, 0.68, 0.52)), _mat("coffee_lid", Color(0.08, 0.08, 0.07)), 0.20)
	_pickup_box("PickupStaplerOffice", Vector3(32.8, 1.12, 27.4), Vector3(0.42, 0.12, 0.18), _mat("stapler", Color(0.10, 0.10, 0.12)), 0.22)
	_pickup_box("PickupDetentionStackOffice", Vector3(31.8, 1.14, 28.1), Vector3(0.62, 0.10, 0.42), _mat("detention_stack", Color(0.86, 0.80, 0.58)), 0.25)

	# Pool room throwables
	_pickup_box("PickupPoolKickboard", Vector3(8.0, 0.32, -13.2), Vector3(1.2, 0.12, 0.55), _mat("kickboard", Color(0.72, 0.60, 0.10)), 0.50)
	_pickup_box("PickupPoolFloatA", Vector3(-7.5, 0.34, -12.5), Vector3(1.10, 0.16, 0.52), _mat("pool_float_a", Color(0.12, 0.35, 0.72)), 0.45)
	_pickup_box("PickupPoolFloatB", Vector3(-22.0, 0.42, -16.8), Vector3(0.90, 0.28, 0.55), _mat("pool_float_b", Color(0.70, 0.18, 0.10)), 0.55)
	_pickup_ball("PickupBeachBallPool", Vector3(20.5, 0.50, -18.5), 0.42, _mat("beach_ball", Color(0.85, 0.78, 0.18)), 0.40)
	_pickup_ball("PickupWaterPoloBall", Vector3(-18.0, 0.42, -25.5), 0.34, _mat("water_polo_ball", Color(0.88, 0.86, 0.72)), 0.38)
	_pickup_detailed_cylinder("PickupWaterBottlePool", Vector3(23.0, 0.42, -23.0), 0.16, 0.55, _mat("pool_bottle", Color(0.42, 0.78, 0.82), 0.65), _mat("pool_bottle_cap", Color(0.06, 0.12, 0.18)), 0.22)


# ──────────────────────────────────────────────────────────────────────────────
#  LIGHTS
# ──────────────────────────────────────────────────────────────────────────────
func _make_light(name: String, pos: Vector3) -> void:
	var frame: Material = _mat("light_frame", Color(0.06, 0.06, 0.05))
	var glow: Material = _mat("light_glow", Color(0.96, 0.90, 0.52))

	_box(name + "_Frame", pos, Vector3(1.65, 0.07, 0.46), frame, false)
	_box(name + "_Panel", pos + Vector3(0.0, -0.045, 0.0), Vector3(1.30, 0.03, 0.32), glow, false)

	var light: OmniLight3D = OmniLight3D.new()
	light.name = name + "_Omni"
	light.position = pos + Vector3(0.0, -0.30, 0.0)
	light.light_color = Color(1.0, 0.90, 0.60)
	light.light_energy = 0.55
	light.omni_range = 11.0
	add_child(light)


func _build_lights() -> void:
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.name = "SoftSun"
	sun.rotation_degrees = Vector3(-42.0, -38.0, 0.0)
	sun.light_energy = 0.55
	sun.light_color = Color(0.80, 0.84, 0.68)
	add_child(sun)

	var world_env: WorldEnvironment = WorldEnvironment.new()
	world_env.name = "WorldEnvironment"

	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.46, 0.54, 0.62)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.52, 0.55, 0.44)
	environment.ambient_light_energy = 0.70
	environment.fog_enabled = true
	environment.fog_density = 0.014
	environment.fog_light_color = Color(0.48, 0.52, 0.44)

	world_env.environment = environment
	add_child(world_env)

	for pos: Vector3 in [
		Vector3(0.0, WALL_H - 0.08, -20.0),
		Vector3(-36.0, WALL_H - 0.08, 20.0),
		Vector3(0.0, WALL_H - 0.08, 20.0),
		Vector3(36.0, WALL_H - 0.08, 20.0)
	]:
		_make_light("RoomFill" + str(pos.x) + "_" + str(pos.z), pos)
