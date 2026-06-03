extends CharacterBody3D
var sensitivity = 0.003
var speed = 5.0
var gravity = 20.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * sensitivity)
		$Camera3D.rotate_x(-event.relative.y * sensitivity)
		$Camera3D.rotation.x = clamp($Camera3D.rotation.x, -1.5, 1.5)
	
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	

func _physics_process(delta: float):
	var direction = Vector3.ZERO
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	if Input.is_key_pressed(KEY_SPACE) and is_on_floor():
		velocity.y = 5.0
	
	if Input.is_key_pressed(KEY_W):
		direction -= transform.basis.z
	if Input.is_key_pressed(KEY_S):
		direction += transform.basis.z
	if Input.is_key_pressed(KEY_A):
		direction -= transform.basis.x
	if Input.is_key_pressed(KEY_D):
		direction += transform.basis.x
	
	if Input.is_action_just_pressed("interact"):
		for npc in get_tree().get_nodes_in_group("npc"):
			if npc.currState == npc.State.STUCK:
				var dist = global_position.distance_to(npc.global_position)
				if dist < 2.0:  # interact range
					npc.receive_hit(999)  # force break regardless of impulse
					break
	
	if direction != Vector3.ZERO:
		velocity.x = direction.normalized().x * speed
		velocity.z = direction.normalized().z * speed
	else:
		velocity.x = 0
		velocity.z = 0
		
	move_and_slide()
