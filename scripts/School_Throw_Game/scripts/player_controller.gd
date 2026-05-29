extends CharacterBody3D

@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.5
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.002
@export var throw_force: float = 16.0

var gravity: float = 9.8
var camera_holder: Node3D
var camera: Camera3D
var ray: RayCast3D
var hud: CanvasLayer
var held_object: RigidBody3D = null

func _ready() -> void:
	camera_holder = get_node("CameraHolder")
	camera = get_node("CameraHolder/Camera3D")
	ray = get_node("CameraHolder/Camera3D/InteractionRay")
	camera.current = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera_holder.rotate_x(-event.relative.y * mouse_sensitivity)
		camera_holder.rotation.x = clamp(camera_holder.rotation.x, deg_to_rad(-80), deg_to_rad(80))
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		_interact()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_throw_held()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	if Input.is_key_pressed(KEY_SPACE) and is_on_floor():
		velocity.y = jump_velocity

	var x := 0.0
	var z := 0.0
	if Input.is_key_pressed(KEY_A): x -= 1.0
	if Input.is_key_pressed(KEY_D): x += 1.0
	if Input.is_key_pressed(KEY_W): z -= 1.0
	if Input.is_key_pressed(KEY_S): z += 1.0

	var direction := (transform.basis * Vector3(x, 0, z)).normalized()
	var speed := sprint_speed if Input.is_key_pressed(KEY_SHIFT) else walk_speed
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	move_and_slide()

	_update_held_object()
	_update_prompt()

func _update_prompt() -> void:
	if not hud: return
	var obj := _get_object_in_front()
	if obj and obj.has_method("get_interaction_text"):
		hud.call("show_prompt", obj.call("get_interaction_text"))
	elif held_object:
		hud.call("show_prompt", "Left click: throw object")
	else:
		hud.call("hide_prompt")

func _interact() -> void:
	if held_object:
		_drop_held()
		return
	var obj := _get_object_in_front()
	if obj and obj.has_method("interact"):
		obj.call("interact", self)

func pickup(obj: RigidBody3D) -> void:
	held_object = obj
	held_object.freeze = true
	held_object.collision_layer = 0
	held_object.collision_mask = 0
	if hud:
		hud.call("show_message", "Picked up " + obj.name + ". Left click to throw.")

func _drop_held() -> void:
	if held_object == null: return
	held_object.freeze = false
	held_object.collision_layer = 1
	held_object.collision_mask = 1
	held_object = null

func _throw_held() -> void:
	if held_object == null: return
	var obj := held_object
	held_object = null
	obj.freeze = false
	obj.collision_layer = 1
	obj.collision_mask = 1
	obj.global_position = camera.global_position + -camera.global_transform.basis.z * 1.5
	obj.linear_velocity = -camera.global_transform.basis.z * throw_force
	if hud:
		hud.call("show_message", "Thrown.")

func _update_held_object() -> void:
	if held_object:
		held_object.global_position = camera.global_position + -camera.global_transform.basis.z * 1.4 + Vector3(0, -0.25, 0)
		held_object.global_rotation = camera.global_rotation

func _get_object_in_front() -> Object:
	ray.force_raycast_update()
	if ray.is_colliding():
		return ray.get_collider()
	return null
