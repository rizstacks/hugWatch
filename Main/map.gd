extends Node3D

@export var clear_old_scene_siblings: bool = false

const KEY_INTERACT := KEY_E
const INTERACT_DISTANCE := 4.0
const HOLD_DISTANCE := 2.15
const THROW_FORCE := 17.0
const EPS := 0.04

const BUILDING_W := 100.0
const BUILDING_D := 70.0
const HALF_W := 50.0
const HALF_D := 35.0

const WALL_H := 5.9
const WALL_T := 0.36
const HALL_Z0 := -7.0
const HALL_Z1 := 7.0
const NORTH_Z := -34.0
const SOUTH_Z := 34.0

const WALL := Color(0.70, 0.72, 0.64)
const WALL_BASE := Color(0.45, 0.53, 0.55)
const WALL_INNER := Color(0.55, 0.59, 0.53)
const FLOOR := Color(0.49, 0.56, 0.59)
const HALL_FLOOR := Color(0.56, 0.62, 0.64)
const CEILING := Color(0.74, 0.73, 0.66)
const TRIM := Color(0.10, 0.12, 0.13)
const GLASS := Color(0.50, 0.70, 0.84, 0.26)
const DOOR := Color(0.42, 0.24, 0.12)
const DOOR_DARK := Color(0.23, 0.12, 0.06)
const WOOD := Color(0.44, 0.25, 0.12)
const DARK_WOOD := Color(0.23, 0.12, 0.06)
const METAL := Color(0.55, 0.58, 0.58)
const BLUE := Color(0.09, 0.22, 0.52)
const GREEN := Color(0.15, 0.38, 0.24)
const RED := Color(0.58, 0.12, 0.10)
const BLACK := Color(0.035, 0.035, 0.04)
const WHITE := Color(0.86, 0.86, 0.80)
const WATER := Color(0.04, 0.46, 0.68, 0.72)

var doors: Array = []
var pickups: Array[RigidBody3D] = []
var held: RigidBody3D = null

func _ready() -> void:
	build_map()

func _process(_delta: float) -> void:
	if held != null and is_instance_valid(held):
		var camera: Camera3D = get_viewport().get_camera_3d()
		if camera != null:
			var target: Vector3 = camera.global_position + (-camera.global_transform.basis.z * HOLD_DISTANCE) + Vector3(0, -0.35, 0)
			held.global_position = held.global_position.lerp(target, 0.42)
			held.linear_velocity = Vector3.ZERO
			held.angular_velocity = Vector3.ZERO

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key: InputEventKey = event as InputEventKey
		if key.pressed and not key.echo and key.keycode == KEY_INTERACT:
			interact()

func build_map() -> void:
	for child in get_children():
		child.queue_free()

	doors.clear()
	pickups.clear()
	held = null

	build_architecture()
	build_hallway()
	build_room_101_pool()
	build_room_102_classroom()
	build_room_103_lab()
	build_room_104_office()
	build_pickups()
	add_lighting()

func build_architecture() -> void:
	create_static_box("Main Floor", Vector3(BUILDING_W, 0.35, BUILDING_D), Vector3(0, -0.18, 0), FLOOR)
	create_static_box("Main Ceiling", Vector3(BUILDING_W, 0.22, BUILDING_D), Vector3(0, WALL_H + 0.38, 0), CEILING, false)

	var north_ext: Array = [
		opening(-36, 10.0, 1.20, 2.80),
		opening(-18, 10.0, 1.20, 2.80),
		opening(0, 10.0, 1.20, 2.80),
		opening(18, 10.0, 1.20, 2.80),
		opening(36, 10.0, 1.20, 2.80)
	]

	var south_ext: Array = [
		opening(-42, 7.5, 1.20, 2.80),
		opening(-30, 7.5, 1.20, 2.80),
		opening(-12, 7.5, 1.20, 2.80),
		opening(6, 7.5, 1.20, 2.80),
		opening(24, 7.5, 1.20, 2.80),
		opening(42, 7.5, 1.20, 2.80)
	]

	create_wall_x("North Exterior Wall", NORTH_Z, -HALF_W, HALF_W, north_ext)
	create_wall_x("South Exterior Wall", SOUTH_Z, -HALF_W, HALF_W, south_ext)
	create_wall_z("West Exterior Wall", -HALF_W, NORTH_Z, SOUTH_Z, [])
	create_wall_z("East Exterior Wall", HALF_W, NORTH_Z, SOUTH_Z, [])

	for o in north_ext:
		create_window_module(NORTH_Z + 0.23, o, true)
	for o in south_ext:
		create_window_module(SOUTH_Z - 0.23, o, false)

	var north_hall: Array = [
		opening(-13, 11.6, 1.15, 2.85),
		opening(0, 4.2, 0.0, 4.05),
		opening(13, 11.6, 1.15, 2.85)
	]

	var south_hall: Array = []
	for cx in [-36.0, 0.0, 36.0]:
		south_hall.append(opening(cx, 4.2, 0.0, 4.05))
		south_hall.append(opening(cx - 8.2, 5.6, 1.15, 2.85))
		south_hall.append(opening(cx + 8.2, 5.6, 1.15, 2.85))

	create_wall_x("Hall North Wall", HALL_Z0, -HALF_W, HALF_W, north_hall)
	create_wall_x("Hall South Wall", HALL_Z1, -HALF_W, HALF_W, south_hall)

	for o in north_hall:
		if float(o["bottom"]) > 0.0:
			create_window_module(HALL_Z0 + 0.23, o, false)
	for o in south_hall:
		if float(o["bottom"]) > 0.0:
			create_window_module(HALL_Z1 - 0.23, o, true)

	create_wall_z("Pool West Wall", -18.0, NORTH_Z, HALL_Z0, [])
	create_wall_z("Pool East Wall", 18.0, NORTH_Z, HALL_Z0, [])
	create_wall_z("Divider 102 103", -18.0, HALL_Z1, SOUTH_Z, [])
	create_wall_z("Divider 103 104", 18.0, HALL_Z1, SOUTH_Z, [])

	create_school_door(Vector3(0, 0, HALL_Z0 + 0.03), true)
	create_school_door(Vector3(-36, 0, HALL_Z1 - 0.03), false)
	create_school_door(Vector3(0, 0, HALL_Z1 - 0.03), false)
	create_school_door(Vector3(36, 0, HALL_Z1 - 0.03), false)

func opening(center: float, width: float, bottom: float, height: float) -> Dictionary:
	return {
		"center": center,
		"width": width,
		"bottom": bottom,
		"height": height
	}

func create_wall_x(n: String, z: float, x0: float, x1: float, openings: Array) -> void:
	var xs: Array = [x0, x1]
	var ys: Array = [0.0, WALL_H]

	for o in openings:
		xs.append(clamp(float(o["center"]) - float(o["width"]) * 0.5, x0, x1))
		xs.append(clamp(float(o["center"]) + float(o["width"]) * 0.5, x0, x1))
		ys.append(clamp(float(o["bottom"]), 0.0, WALL_H))
		ys.append(clamp(float(o["bottom"]) + float(o["height"]), 0.0, WALL_H))

	xs.sort()
	ys.sort()

	for xi in range(xs.size() - 1):
		for yi in range(ys.size() - 1):
			var a: float = float(xs[xi])
			var b: float = float(xs[xi + 1])
			var y0: float = float(ys[yi])
			var y1: float = float(ys[yi + 1])

			if b - a <= 0.01 or y1 - y0 <= 0.01:
				continue

			var cx: float = (a + b) * 0.5
			var cy: float = (y0 + y1) * 0.5
			if is_inside_opening(cx, cy, openings):
				continue

			var col: Color = WALL_BASE if cy < 1.08 else WALL
			create_static_box(n, Vector3((b - a) + EPS, (y1 - y0) + EPS, WALL_T), Vector3(cx, cy, z), col)

func create_wall_z(n: String, x: float, z0: float, z1: float, openings: Array) -> void:
	var zs: Array = [z0, z1]
	var ys: Array = [0.0, WALL_H]

	for o in openings:
		zs.append(clamp(float(o["center"]) - float(o["width"]) * 0.5, z0, z1))
		zs.append(clamp(float(o["center"]) + float(o["width"]) * 0.5, z0, z1))
		ys.append(clamp(float(o["bottom"]), 0.0, WALL_H))
		ys.append(clamp(float(o["bottom"]) + float(o["height"]), 0.0, WALL_H))

	zs.sort()
	ys.sort()

	for zi in range(zs.size() - 1):
		for yi in range(ys.size() - 1):
			var a: float = float(zs[zi])
			var b: float = float(zs[zi + 1])
			var y0: float = float(ys[yi])
			var y1: float = float(ys[yi + 1])

			if b - a <= 0.01 or y1 - y0 <= 0.01:
				continue

			var cz: float = (a + b) * 0.5
			var cy: float = (y0 + y1) * 0.5
			if is_inside_opening(cz, cy, openings):
				continue

			var col: Color = WALL_BASE if cy < 1.08 else WALL
			create_static_box(n, Vector3(WALL_T, (y1 - y0) + EPS, (b - a) + EPS), Vector3(x, cy, cz), col)

func is_inside_opening(axis: float, y: float, openings: Array) -> bool:
	for o in openings:
		var left: float = float(o["center"]) - float(o["width"]) * 0.5
		var right: float = float(o["center"]) + float(o["width"]) * 0.5
		var bottom: float = float(o["bottom"])
		var top: float = bottom + float(o["height"])

		if axis >= left and axis <= right and y >= bottom and y <= top:
			return true

	return false

func create_window_module(z: float, o: Dictionary, north_side: bool) -> void:
	var center: float = float(o["center"])
	var width: float = float(o["width"])
	var bottom: float = float(o["bottom"])
	var height: float = float(o["height"])
	var y: float = bottom + height * 0.5
	var face_dir: float = -1.0 if north_side else 1.0
	var frame_z: float = z + face_dir * 0.06

	create_static_box("Window Glass", Vector3(width - 0.42, height - 0.34, 0.045), Vector3(center, y, z), GLASS, false)

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
		return

	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return

	var best_door: Dictionary = {}
	var best_door_dist: float = 99999.0

	for d in doors:
		var node: Node3D = d["node"]
		var dist: float = camera.global_position.distance_to(node.global_position)
		if dist < INTERACT_DISTANCE and dist < best_door_dist:
			best_door_dist = dist
			best_door = d

	var best_pickup: RigidBody3D = null
	var best_pickup_dist: float = 99999.0

	for p in pickups:
		if is_instance_valid(p):
			var dist: float = camera.global_position.distance_to(p.global_position)
			if dist < INTERACT_DISTANCE and dist < best_pickup_dist:
				best_pickup_dist = dist
				best_pickup = p

	if best_pickup != null and best_pickup_dist < best_door_dist:
		pick_up(best_pickup)
	elif not best_door.is_empty():
		toggle_door(best_door)

func toggle_door(d: Dictionary) -> void:
	var node: Node3D = d["node"]
	var open_now: bool = d["open"]
	d["open"] = not open_now

	var target: Vector3 = d["closed"] if open_now else d["opened"]
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "rotation_degrees", target, 0.30)

func pick_up(item: RigidBody3D) -> void:
	held = item
	held.freeze = true
	held.gravity_scale = 0.0
	held.linear_velocity = Vector3.ZERO
	held.angular_velocity = Vector3.ZERO

func throw_held() -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null or held == null:
		return

	held.freeze = false
	held.gravity_scale = 1.0
	held.linear_velocity = (-camera.global_transform.basis.z * THROW_FORCE) + Vector3(0, 3.0, 0)
	held.angular_velocity = Vector3(randf_range(-5.5, 5.5), randf_range(-6.0, 6.0), randf_range(-5.5, 5.5))
	held = null

func create_bench(pos: Vector3, rot_y: float) -> void:
	var base: Node3D = Node3D.new()
	base.name = "Bench"
	base.position = pos
	base.rotation_degrees.y = rot_y
	add_child(base)

	create_child_box(base, "Seat", Vector3(3.9, 0.18, 0.95), Vector3(0, 0.53, 0), WOOD)
	create_child_box(base, "Back", Vector3(3.9, 0.95, 0.16), Vector3(0, 1.05, -0.48), DARK_WOOD)
	create_child_box(base, "Leg L", Vector3(0.14, 0.52, 0.14), Vector3(-1.5, 0.27, -0.30), DARK_WOOD)
	create_child_box(base, "Leg R", Vector3(0.14, 0.52, 0.14), Vector3(1.5, 0.27, -0.30), DARK_WOOD)
	create_child_box(base, "Leg L2", Vector3(0.14, 0.52, 0.14), Vector3(-1.5, 0.27, 0.30), DARK_WOOD)
	create_child_box(base, "Leg R2", Vector3(0.14, 0.52, 0.14), Vector3(1.5, 0.27, 0.30), DARK_WOOD)

func create_water_fountain(pos: Vector3, rot_y: float) -> void:
	var base: Node3D = Node3D.new()
	base.name = "Water Fountain"
	base.position = pos
	base.rotation_degrees.y = rot_y
	add_child(base)

	create_child_box(base, "Back", Vector3(0.20, 1.55, 0.95), Vector3(0, 0.78, 0), METAL)
	create_child_box(base, "Basin", Vector3(0.75, 0.22, 0.78), Vector3(0.38, 0.98, 0), Color(0.78, 0.80, 0.80))
	create_child_box(base, "Button", Vector3(0.06, 0.09, 0.09), Vector3(0.80, 1.08, 0.28), BLACK)
	create_child_box(base, "Spout", Vector3(0.10, 0.14, 0.10), Vector3(0.68, 1.16, -0.16), WHITE)

func create_bulletin_board(pos: Vector3, south: bool) -> void:
	var off: float = 0.08 if south else -0.08
	create_static_box("Bulletin Frame", Vector3(5.2, 1.9, 0.10), pos, DARK_WOOD)
	create_static_box("Bulletin Cork", Vector3(4.75, 1.45, 0.06), Vector3(pos.x, pos.y, pos.z + off), Color(0.75, 0.48, 0.22))

func create_trash_can(pos: Vector3) -> void:
	create_static_box("Trash Can", Vector3(0.78, 0.95, 0.78), pos + Vector3(0, 0.47, 0), Color(0.14, 0.16, 0.17))
	create_static_box("Trash Can Rim", Vector3(0.88, 0.10, 0.88), pos + Vector3(0, 1.0, 0), Color(0.07, 0.08, 0.09))

func create_teacher_desk(pos: Vector3, rot_y: float) -> void:
	var base: Node3D = Node3D.new()
	base.name = "Teacher Desk"
	base.position = pos
	base.rotation_degrees.y = rot_y
	add_child(base)

	create_child_box(base, "Top", Vector3(5.5, 0.18, 2.1), Vector3(0, 1.0, 0), WOOD)
	create_child_box(base, "Front", Vector3(5.5, 0.95, 0.26), Vector3(0, 0.53, 0.96), DARK_WOOD)
	create_child_box(base, "Left Pedestal", Vector3(1.05, 0.86, 1.6), Vector3(-1.95, 0.48, 0), DARK_WOOD)
	create_child_box(base, "Right Pedestal", Vector3(1.05, 0.86, 1.6), Vector3(1.95, 0.48, 0), DARK_WOOD)

func create_student_desk(pos: Vector3, rot_y: float) -> void:
	var base: Node3D = Node3D.new()
	base.name = "Student Desk"
	base.position = pos
	base.rotation_degrees.y = rot_y
	add_child(base)

	create_child_box(base, "Desk Top", Vector3(2.1, 0.13, 1.45), Vector3(0, 0.80, 0), WOOD)
	create_child_box(base, "Desk Box", Vector3(1.7, 0.22, 1.05), Vector3(0, 0.64, 0), DARK_WOOD)
	create_child_box(base, "Chair Seat", Vector3(1.05, 0.14, 1.05), Vector3(0, 0.47, 1.18), BLUE)
	create_child_box(base, "Chair Back", Vector3(1.05, 0.85, 0.14), Vector3(0, 0.92, 1.68), BLUE.darkened(0.18))

func create_lab_table(pos: Vector3) -> void:
	create_static_box("Lab Table Top", Vector3(9.2, 0.18, 2.1), Vector3(pos.x, 1.05, pos.z), Color(0.14, 0.36, 0.30))
	create_static_box("Lab Table Base", Vector3(8.8, 0.86, 1.7), Vector3(pos.x, 0.50, pos.z), Color(0.11, 0.26, 0.21))
	create_static_box("Lab Sink", Vector3(1.0, 0.10, 0.68), Vector3(pos.x - 2.9, 1.17, pos.z), Color(0.76, 0.78, 0.78))
	create_static_box("Lab Faucet", Vector3(0.07, 0.34, 0.07), Vector3(pos.x - 2.9, 1.40, pos.z - 0.20), METAL)

func create_microscope(pos: Vector3) -> void:
	create_static_box("Microscope Base", Vector3(0.58, 0.10, 0.42), Vector3(pos.x, 1.22, pos.z), BLACK)
	create_static_box("Microscope Arm", Vector3(0.12, 0.62, 0.12), Vector3(pos.x - 0.08, 1.54, pos.z), BLACK)
	create_static_box("Microscope Head", Vector3(0.26, 0.18, 0.24), Vector3(pos.x + 0.14, 1.80, pos.z - 0.14), BLACK)

func create_cabinet(pos: Vector3, rot_y: float, col: Color) -> void:
	var base: Node3D = Node3D.new()
	base.name = "Cabinet"
	base.position = pos
	base.rotation_degrees.y = rot_y
	add_child(base)

	create_child_box(base, "Body", Vector3(3.6, 3.0, 0.68), Vector3(0, 1.5, 0), col)
	create_child_box(base, "Top Lip", Vector3(3.8, 0.10, 0.78), Vector3(0, 3.05, 0), col.darkened(0.12), false)
	create_child_box(base, "Handle", Vector3(1.2, 0.06, 0.06), Vector3(0, 1.65, -0.40), METAL, false)

func create_bookshelf(pos: Vector3, rot_y: float) -> void:
	var base: Node3D = Node3D.new()
	base.name = "Bookshelf"
	base.position = pos
	base.rotation_degrees.y = rot_y
	add_child(base)

	create_child_box(base, "Back", Vector3(3.6, 3.1, 0.30), Vector3(0, 1.55, 0), WOOD)
	for y in [0.48, 1.10, 1.72, 2.34, 2.96]:
		create_child_box(base, "Shelf", Vector3(3.7, 0.09, 0.66), Vector3(0, y, -0.07), DARK_WOOD)

func create_principal_desk(pos: Vector3, rot_y: float) -> void:
	var base: Node3D = Node3D.new()
	base.name = "Principal Desk"
	base.position = pos
	base.rotation_degrees.y = rot_y
	add_child(base)

	create_child_box(base, "Top", Vector3(6.8, 0.20, 2.8), Vector3(0, 1.0, 0), WOOD)
	create_child_box(base, "Front", Vector3(6.8, 1.1, 0.30), Vector3(0, 0.55, 1.25), DARK_WOOD)
	create_child_box(base, "Left Pedestal", Vector3(1.1, 1.0, 2.2), Vector3(-2.45, 0.52, 0), DARK_WOOD)
	create_child_box(base, "Right Pedestal", Vector3(1.1, 1.0, 2.2), Vector3(2.45, 0.52, 0), DARK_WOOD)

func create_office_chair(pos: Vector3, rot_y: float) -> void:
	var base: Node3D = Node3D.new()
	base.name = "Office Chair"
	base.position = pos
	base.rotation_degrees.y = rot_y
	add_child(base)

	create_child_box(base, "Seat", Vector3(1.45, 0.16, 1.45), Vector3(0, 0.82, 0), BLACK)
	create_child_box(base, "Back", Vector3(1.45, 1.45, 0.16), Vector3(0, 1.55, 0.65), BLACK)
	create_child_box(base, "Stem", Vector3(0.20, 0.75, 0.20), Vector3(0, 0.42, 0), METAL)

func create_office_couch(pos: Vector3, rot_y: float) -> void:
	var base: Node3D = Node3D.new()
	base.name = "Office Couch"
	base.position = pos
	base.rotation_degrees.y = rot_y
	add_child(base)

	create_child_box(base, "Seat", Vector3(5.7, 0.42, 1.7), Vector3(0, 0.53, 0), BLUE)
	create_child_box(base, "Back", Vector3(5.7, 1.25, 0.30), Vector3(0, 1.15, -0.75), BLUE.darkened(0.22))
	create_child_box(base, "Arm L", Vector3(0.40, 0.9, 1.7), Vector3(-3.0, 0.78, 0), BLUE.darkened(0.22))
	create_child_box(base, "Arm R", Vector3(0.40, 0.9, 1.7), Vector3(3.0, 0.78, 0), BLUE.darkened(0.22))

func create_light_fixture(pos: Vector3) -> void:
	create_static_box("Ceiling Light", Vector3(2.8, 0.08, 0.36), pos + Vector3(0, 0.10, 0), Color(1.0, 0.95, 0.68), false)
	create_static_box("Ceiling Light Trim", Vector3(3.1, 0.05, 0.46), pos + Vector3(0, 0.13, 0), TRIM, false)

func add_lighting() -> void:
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.name = "Soft Daylight"
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.light_energy = 0.95
	sun.shadow_enabled = true
	add_child(sun)

	for x in range(-40, 41, 8):
		omni(Vector3(float(x), WALL_H + 0.12, 0), 11.0, 1.35, Color(1.0, 0.96, 0.80))

	omni(Vector3(0, WALL_H + 0.12, -21), 17.0, 1.25, Color(0.76, 0.92, 1.0))
	omni(Vector3(-36, WALL_H + 0.12, 21), 14.0, 1.18, Color(1.0, 0.94, 0.82))
	omni(Vector3(0, WALL_H + 0.12, 21), 15.0, 1.18, Color(0.86, 1.0, 0.86))
	omni(Vector3(36, WALL_H + 0.12, 21), 14.0, 1.18, Color(1.0, 0.86, 0.88))

func omni(pos: Vector3, range_value: float, energy: float, col: Color) -> void:
	var light: OmniLight3D = OmniLight3D.new()
	light.name = "Ceiling Light"
	light.position = pos
	light.omni_range = range_value
	light.light_energy = energy
	light.light_color = col
	light.shadow_enabled = false
	add_child(light)

func create_static_box(n: String, size: Vector3, pos: Vector3, col: Color, collision_enabled: bool = true) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = n
	body.position = pos

	var mesh_inst: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	mesh_inst.mesh = mesh
	mesh_inst.material_override = material(col)
	body.add_child(mesh_inst)

	if collision_enabled:
		var col_shape: CollisionShape3D = CollisionShape3D.new()
		var shape: BoxShape3D = BoxShape3D.new()
		shape.size = size
		col_shape.shape = shape
		body.add_child(col_shape)

	add_child(body)
	return body

func create_child_box(parent: Node3D, n: String, size: Vector3, pos: Vector3, col: Color, collision_enabled: bool = true) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = n
	body.position = pos

	var mesh_inst: MeshInstance3D = MeshInstance3D.new()
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	mesh_inst.mesh = mesh
	mesh_inst.material_override = material(col)
	body.add_child(mesh_inst)

	if collision_enabled:
		var col_shape: CollisionShape3D = CollisionShape3D.new()
		var shape: BoxShape3D = BoxShape3D.new()
		shape.size = size
		col_shape.shape = shape
		body.add_child(col_shape)

	parent.add_child(body)
	return body

func material(col: Color) -> StandardMaterial3D:
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.86
	mat.metallic = 0.0

	if col.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.alpha_scissor_threshold = 0.02

	return mat
