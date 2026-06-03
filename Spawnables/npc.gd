extends CharacterBody3D

var gravity = 20.0
var speed = 5.0
var direction = Vector3.ZERO

enum State {WANDERING, SEEKING, BONDING, STUCK}
var currState = State.WANDERING

var break_impulse = 8.0

var bond_time = 1.5
var bond_timer = 0.0
var is_fully_bonded = false

var pair = null
var seek_range = 10

var last_position = Vector3.ZERO
var stuck_timer = 0.0
var stuck_check_interval = 1.0  # check every second
var stuck_threshold = 0.1  # how little movement counts as stuck


func _ready():
	add_to_group("npc")
	$walkTimer.wait_time = randf_range(1.0, 3.0)
	$walkTimer.connect("timeout", timerSignal)
	$walkTimer.start()
	
func timerSignal():
	if currState == State.WANDERING:
		var angle = randf() * 2 * PI
		direction = Vector3(cos(angle), 0, sin(angle))
	$walkTimer.wait_time = randf_range(1.0, 3.0)
	$walkTimer.start()
	
func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	match currState:
		State.WANDERING:
			_handle_wandering()
		State.SEEKING:
			_handle_seeking()
		State.BONDING:
			_handle_bonding(delta)
		State.STUCK:
			_handle_stuck()
	move_and_slide()
	
func _handle_wandering():	
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	
	stuck_timer += get_physics_process_delta_time()
	if stuck_timer >= stuck_check_interval:
		stuck_timer = 0.0
		if global_position.distance_to(last_position) < stuck_threshold:
			var angle = randf() * 2 * PI
			direction = Vector3(cos(angle), 0, sin(angle))
		last_position = global_position
	if pair != null:
		if get_tree().get_nodes_in_group("npc").size() <= 2:
			currState = State.SEEKING
			return
		var dist = global_position.distance_to(pair.global_position)
		if dist < seek_range:
			currState = State.SEEKING
	return
	
func _handle_seeking():
	if pair == null:
		currState = State.WANDERING
		return
		
	stuck_timer += get_physics_process_delta_time()
	if stuck_timer >= stuck_check_interval:
		stuck_timer = 0.0
		if global_position.distance_to(last_position) < stuck_threshold:
			var angle = randf() * 2 * PI
			direction = Vector3(cos(angle), 0, sin(angle))
			velocity.x = direction.x * speed * 2.0
			velocity.z = direction.z * speed * 2.0
		last_position = global_position		
		
	var dist = global_position.distance_to(pair.global_position)
	if dist < 1:
		currState = State.BONDING
		pair.currState = State.BONDING
		bond_timer = 0.0
		pair.bond_timer = 0.0
		velocity = Vector3.ZERO
		pair.velocity = Vector3.ZERO
		return
		
	var seekDirection = (pair.global_position - global_position).normalized()
	velocity.x = seekDirection.x * speed
	velocity.z = seekDirection.z * speed
	
func _handle_bonding(delta):
	if pair == null:
		currState = State.WANDERING
		return
	bond_timer += delta
	if bond_timer >= bond_time:
		currState = State.STUCK
		pair.currState = State.STUCK
		is_fully_bonded = true
		pair.is_fully_bonded = true

	velocity = Vector3.ZERO

func _handle_stuck():
	if pair == null:
		_break_apart()
		return
		
	velocity = Vector3.ZERO
	
func receive_hit(impulse_strength: float):
	if not is_fully_bonded:
		return
	if impulse_strength >= break_impulse:
		if pair:
			pair._break_apart()
		_break_apart()
		
func _break_apart():
	queue_free()
		
		
		
	
