extends Node3D

# ArmView_final.gd
# Attach this script to ArmsRoot under Camera3D.
#
# Final direction:
# - Left arm stays mostly fixed and clean.
# - Right arm does all action: punch / pickup / hold / throw.
# - No visible robot elbow.
# - Keeps the better v3 view style.
#
# Test controls:
# E = punch / push
# Q = pickup then hold
# Left Mouse = throw
# R = idle

enum ArmState {
	IDLE,
	PUNCH,
	PICKUP,
	HOLD,
	THROW
}

var state: ArmState = ArmState.IDLE
var state_time: float = 0.0

var left_arm: Node3D
var right_arm: Node3D

var left_current_pos: Vector3
var right_current_pos: Vector3
var left_current_rot: Vector3
var right_current_rot: Vector3

var left_idle_pos: Vector3 = Vector3(-0.44, -0.64, -0.92)
var right_idle_pos: Vector3 = Vector3(0.42, -0.60, -0.86)

var left_idle_rot: Vector3 = Vector3(28.0, 10.0, -14.0)
var right_idle_rot: Vector3 = Vector3(28.0, -10.0, 14.0)

var mat_sleeve: StandardMaterial3D
var mat_skin: StandardMaterial3D
var mat_shadow: StandardMaterial3D


func _ready() -> void:
	position = Vector3.ZERO
	rotation = Vector3.ZERO

	mat_sleeve = StandardMaterial3D.new()
	mat_sleeve.albedo_color = Color(0.055, 0.095, 0.20)
	mat_sleeve.roughness = 0.92

	mat_skin = StandardMaterial3D.new()
	mat_skin.albedo_color = Color(0.82, 0.67, 0.52)
	mat_skin.roughness = 0.9

	mat_shadow = StandardMaterial3D.new()
	mat_shadow.albedo_color = Color(0.07, 0.045, 0.035)
	mat_shadow.roughness = 1.0

	left_arm = _build_arm("LeftArm", -1.0)
	right_arm = _build_arm("RightArm", 1.0)

	left_current_pos = left_idle_pos
	right_current_pos = right_idle_pos
	left_current_rot = left_idle_rot
	right_current_rot = right_idle_rot

	_apply_pose(left_current_pos, right_current_pos, left_current_rot, right_current_rot)


func _process(delta: float) -> void:
	state_time += delta

	match state:
		ArmState.IDLE:
			_update_idle()
		ArmState.PUNCH:
			_update_punch()
		ArmState.PICKUP:
			_update_pickup()
		ArmState.HOLD:
			_update_hold()
		ArmState.THROW:
			_update_throw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.pressed and not key_event.echo:
			if key_event.keycode == KEY_E:
				punch()
			elif key_event.keycode == KEY_Q:
				pickup_item()
			elif key_event.keycode == KEY_R:
				return_idle()

	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			throw_item()


func punch() -> void:
	state = ArmState.PUNCH
	state_time = 0.0


func pickup_item() -> void:
	state = ArmState.PICKUP
	state_time = 0.0


func hold_item() -> void:
	state = ArmState.HOLD
	state_time = 0.0


func throw_item() -> void:
	state = ArmState.THROW
	state_time = 0.0


func return_idle() -> void:
	state = ArmState.IDLE
	state_time = 0.0


func _build_arm(name_value: String, side: float) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = name_value
	add_child(root)

	# Clean connected block style.
	# Looks like sleeve + arm without exposing ugly mechanical joints.
	_make_box(name_value + "_Shoulder", root, Vector3(side * 0.03, 0.16, 0.18), Vector3(0.26, 0.24, 0.28), mat_sleeve)
	_make_box(name_value + "_Sleeve", root, Vector3(0.0, 0.00, -0.10), Vector3(0.22, 0.22, 0.48), mat_sleeve)
	_make_box(name_value + "_Forearm", root, Vector3(side * -0.025, 0.00, -0.46), Vector3(0.19, 0.18, 0.42), mat_skin)
	_make_box(name_value + "_Wrist", root, Vector3(side * -0.025, -0.055, -0.70), Vector3(0.20, 0.04, 0.08), mat_shadow)
	_make_box(name_value + "_Hand", root, Vector3(side * -0.03, 0.0, -0.80), Vector3(0.23, 0.13, 0.20), mat_skin)
	_make_box(name_value + "_Thumb", root, Vector3(side * -0.15, 0.02, -0.76), Vector3(0.075, 0.08, 0.14), mat_skin)

	return root


func _make_box(name_value: String, parent: Node, local_pos: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size

	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = name_value
	mi.mesh = mesh
	mi.material_override = material
	mi.position = local_pos
	parent.add_child(mi)

	return mi


func _apply_pose(l_pos: Vector3, r_pos: Vector3, l_rot: Vector3, r_rot: Vector3) -> void:
	left_arm.position = l_pos
	right_arm.position = r_pos
	left_arm.rotation_degrees = l_rot
	right_arm.rotation_degrees = r_rot


func _move_to(l_pos: Vector3, r_pos: Vector3, l_rot: Vector3, r_rot: Vector3, speed: float) -> void:
	left_current_pos = left_current_pos.lerp(l_pos, speed)
	right_current_pos = right_current_pos.lerp(r_pos, speed)
	left_current_rot = left_current_rot.lerp(l_rot, speed)
	right_current_rot = right_current_rot.lerp(r_rot, speed)
	_apply_pose(left_current_pos, right_current_pos, left_current_rot, right_current_rot)


func _smooth(x: float) -> float:
	return x * x * (3.0 - 2.0 * x)


func _ease_out_back(x: float) -> float:
	var c1: float = 1.70158
	var c3: float = c1 + 1.0
	return 1.0 + c3 * pow(x - 1.0, 3.0) + c1 * pow(x - 1.0, 2.0)


func _update_idle() -> void:
	var t: float = Time.get_ticks_msec() / 1000.0

	# Left hand barely moves. It is just presence, not action.
	var left_bob: float = sin(t * 1.7) * 0.003
	var right_bob: float = sin(t * 2.3) * 0.006
	var right_sway: float = sin(t * 1.9) * 0.006

	var lp: Vector3 = left_idle_pos + Vector3(0.0, left_bob, 0.0)
	var rp: Vector3 = right_idle_pos + Vector3(right_sway, right_bob, 0.0)

	var lr: Vector3 = left_idle_rot + Vector3(0.0, 0.0, sin(t * 1.5) * 0.25)
	var rr: Vector3 = right_idle_rot + Vector3(sin(t * 2.0) * 0.55, 0.0, sin(t * 2.2) * 0.55)

	_move_to(lp, rp, lr, rr, 0.16)


func _update_punch() -> void:
	var a: float = clamp(state_time / 0.34, 0.0, 1.0)

	# Left hand stays stable and slightly tucks in, like bracing.
	var lp: Vector3 = left_idle_pos.lerp(Vector3(-0.46, -0.60, -0.90), 0.35)
	var lr: Vector3 = left_idle_rot.lerp(Vector3(24.0, 9.0, -10.0), 0.35)

	var rp: Vector3 = right_idle_pos
	var rr: Vector3 = right_idle_rot

	# Right punch: pull back -> hit forward -> recover.
	if a < 0.30:
		var pull: float = _smooth(a / 0.30)
		rp = right_idle_pos.lerp(Vector3(0.52, -0.58, -0.78), pull)
		rr = right_idle_rot.lerp(Vector3(36.0, -15.0, 20.0), pull)

	elif a < 0.68:
		var drive: float = _ease_out_back((a - 0.30) / 0.38)
		rp = Vector3(0.52, -0.58, -0.78).lerp(Vector3(0.12, -0.34, -0.36), drive)
		rr = Vector3(36.0, -15.0, 20.0).lerp(Vector3(-16.0, -4.0, -3.0), drive)

	else:
		var back: float = _smooth((a - 0.68) / 0.32)
		rp = Vector3(0.12, -0.34, -0.36).lerp(right_idle_pos, back)
		rr = Vector3(-16.0, -4.0, -3.0).lerp(right_idle_rot, back)

	_move_to(lp, rp, lr, rr, 0.62)

	if state_time >= 0.34:
		return_idle()


func _update_pickup() -> void:
	var a: float = clamp(state_time / 0.46, 0.0, 1.0)

	# Right hand reaches down and forward, then comes into hold pose.
	var reach: float = sin(a * PI)

	var lp: Vector3 = left_idle_pos.lerp(Vector3(-0.38, -0.56, -0.84), reach * 0.15)
	var lr: Vector3 = left_idle_rot

	var rp: Vector3 = right_idle_pos.lerp(Vector3(0.18, -0.30, -0.46), reach)
	var rr: Vector3 = right_idle_rot.lerp(Vector3(-18.0, -6.0, 0.0), reach)

	_move_to(lp, rp, lr, rr, 0.42)

	if state_time >= 0.46:
		hold_item()


func _update_hold() -> void:
	var t: float = Time.get_ticks_msec() / 1000.0
	var bob: float = sin(t * 2.1) * 0.006

	# Hold pose: both hands come in, but right still leads.
	var lp: Vector3 = Vector3(-0.26, -0.28 + bob, -0.72)
	var rp: Vector3 = Vector3(0.28, -0.28 - bob * 0.7, -0.70)

	var lr: Vector3 = Vector3(-18.0, 8.0, -5.0)
	var rr: Vector3 = Vector3(-18.0, -8.0, 5.0)

	_move_to(lp, rp, lr, rr, 0.18)


func _update_throw() -> void:
	var a: float = clamp(state_time / 0.40, 0.0, 1.0)

	var release: float = 0.0
	if a >= 0.16:
		release = sin(clamp((a - 0.16) / 0.84, 0.0, 1.0) * PI)

	var pull: float = 0.0
	if a < 0.28:
		pull = sin((a / 0.28) * PI) * 0.12

	var lp: Vector3 = Vector3(-0.26, -0.28, -0.72) + Vector3(-0.05 * release, -0.02 * release, pull - release * 0.22)
	var rp: Vector3 = Vector3(0.28, -0.28, -0.70) + Vector3(0.08 * release, -0.03 * release, pull - release * 0.42)

	var lr: Vector3 = Vector3(-18.0, 8.0, -5.0) + Vector3(-30.0 * release, 4.0, -8.0 * release)
	var rr: Vector3 = Vector3(-18.0, -8.0, 5.0) + Vector3(-58.0 * release, -4.0, 12.0 * release)

	_move_to(lp, rp, lr, rr, 0.55)

	if state_time >= 0.40:
		return_idle()
