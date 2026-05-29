extends CharacterBody3D

var gravity = 20.0
var speed = 2.0
var direction = Vector3.ZERO

enum State {WANDERING, SEEKING}
var currState = State.WANDERING

var pair = null
var seek_range = 1.0

func _ready():
	$walkTimer.wait_time = 2.0
	$walkTimer.connect("timeout", timerSignal)
	$walkTimer.start()
	
func timerSignal():
	var angle = randf() * 2 * PI
	direction = Vector3(cos(angle), 0, sin(angle))
	
func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	var distance
	if pair == null:
		distance = 100.0
	else:
		distance = global_position.distance_to(pair.global_position)
	
	if distance < seek_range:
		currState = State.SEEKING
	else:
		currState = State.WANDERING
	if currState == State.WANDERING:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		var seekDirection = (pair.global_position - global_position).normalized()
		velocity.x = seekDirection.x * speed
		velocity.z = seekDirection.z * speed
			
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	
	move_and_slide()
