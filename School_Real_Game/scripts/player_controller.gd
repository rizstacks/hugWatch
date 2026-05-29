extends CharacterBody3D

@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.5
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.002
@export var throw_force: float = 14.0

var gravity: float = 9.8
var camera_holder: Node3D
var camera: Camera3D
var ray: RayCast3D
var hold_point: Node3D
var hud: Node = null
var held_object: RigidBody3D = null

func _ready() -> void:
	camera_holder = get_node_or_null("CameraHolder")
	camera = get_node_or_null("CameraHolder/Camera3D")
	ray = get_node_or_null("CameraHolder/Camera3D/InteractionRay")
	hold_point = get_node_or_null("CameraHolder/Camera3D/HoldPoint")
	hud = get_tree().get_first_node_in_group("hud")
	if camera:
		camera.current = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and camera_holder:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera_holder.rotate_x(-event.relative.y * mouse_sensitivity)
		camera_holder.rotation.x = clamp(camera_holder.rotation.x, deg_to_rad(-80), deg_to_rad(80))
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		throw_held_object()
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		try_interact()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	if Input.is_key_pressed(KEY_SPACE) and is_on_floor():
		velocity.y = jump_velocity

	var input_x := 0.0
	var input_z := 0.0
	if Input.is_key_pressed(KEY_A): input_x -= 1.0
	if Input.is_key_pressed(KEY_D): input_x += 1.0
	if Input.is_key_pressed(KEY_W): input_z -= 1.0
	if Input.is_key_pressed(KEY_S): input_z += 1.0

	var direction := (transform.basis * Vector3(input_x, 0, input_z)).normalized()
	var speed := sprint_speed if Input.is_key_pressed(KEY_SHIFT) else walk_speed
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	move_and_slide()

	if held_object and hold_point:
		held_object.global_position = hold_point.global_position
		held_object.global_rotation = camera.global_rotation

	_update_prompt()

func _update_prompt() -> void:
	if not hud or not ray:
		return
	if held_object:
		hud.call("show_prompt", "Left click: throw | E: drop")
		return
	var obj := _get_interactable()
	if obj:
		if obj.has_method("get_interaction_text"):
			hud.call("show_prompt", obj.call("get_interaction_text"))
		else:
			hud.call("show_prompt", "Press E")
	else:
		hud.call("hide_prompt")

func try_interact() -> void:
	if held_object:
		drop_held_object()
		return
	var obj := _get_interactable()
	if obj and obj.has_method("interact"):
		obj.call("interact", self)

func _get_interactable() -> Object:
	if ray == null:
		return null
	ray.force_raycast_update()
	if ray.is_colliding():
		var obj := ray.get_collider()
		if obj and obj.has_method("interact"):
			return obj
	return null

func pick_up(obj: RigidBody3D) -> void:
	held_object = obj
	held_object.freeze = true
	held_object.collision_layer = 0
	held_object.collision_mask = 0
	if hud:
		hud.call("show_message", "Picked up: " + obj.name, 2.0)

func drop_held_object() -> void:
	if held_object == null:
		return
	held_object.freeze = false
	held_object.collision_layer = 1
	held_object.collision_mask = 1
	held_object = null

func throw_held_object() -> void:
	if held_object == null or camera == null:
		return
	var obj := held_object
	drop_held_object()
	obj.linear_velocity = -camera.global_transform.basis.z * throw_force + Vector3(0, 1.5, 0)
	if hud:
		hud.call("show_message", "Thrown.", 1.2)
