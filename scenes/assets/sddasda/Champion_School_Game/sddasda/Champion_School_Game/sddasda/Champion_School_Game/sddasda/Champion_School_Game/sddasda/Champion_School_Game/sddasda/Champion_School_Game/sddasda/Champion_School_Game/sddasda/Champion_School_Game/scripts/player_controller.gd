extends CharacterBody3D

@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.5
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.0022

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var camera_holder: Node3D
var camera: Camera3D
var ray: RayCast3D
var hud: CanvasLayer

func _ready() -> void:
	camera_holder = get_node("CameraHolder")
	camera = get_node("CameraHolder/Camera3D")
	ray = get_node("CameraHolder/Camera3D/InteractionRay")
	hud = get_tree().get_first_node_in_group("hud")
	camera.current = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera_holder.rotate_x(-event.relative.y * mouse_sensitivity)
		camera_holder.rotation.x = clamp(camera_holder.rotation.x, deg_to_rad(-85), deg_to_rad(85))

	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if event.is_action_pressed("interact"):
		_try_interact()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed

	if direction != Vector3.ZERO:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()
	_update_interaction_prompt()

func _update_interaction_prompt() -> void:
	if hud == null:
		return
	var obj := _get_interactable()
	if obj != null and obj.has_method("get_interaction_text"):
		hud.call("show_prompt", obj.call("get_interaction_text"))
	else:
		hud.call("hide_prompt")

func _try_interact() -> void:
	var obj := _get_interactable()
	if obj != null and obj.has_method("interact"):
		obj.call("interact", self)

func _get_interactable() -> Object:
	if ray == null:
		return null
	ray.force_raycast_update()
	if ray.is_colliding():
		var collider := ray.get_collider()
		if collider != null and collider.has_method("interact"):
			return collider
	return null
