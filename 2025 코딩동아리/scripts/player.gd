extends CharacterBody2D


const SPEED = 180.0
const JUMP_VELOCITY = -330.0

const ROLL_SPEED = 300.0
var rolling = false
var can_rolling = true
var double_jump = 0

@onready var player: CharacterBody2D = $"."
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	add_to_group("player")

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	elif is_on_floor() and double_jump == 1 :
		double_jump = 0

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor() and double_jump == 0 :
		velocity.y = JUMP_VELOCITY
		double_jump = 1
	elif Input.is_action_just_pressed("jump") and not is_on_floor() and double_jump == 1 :
		velocity.y = JUMP_VELOCITY
		double_jump = 0
		
	#플레이어 x 좌표를 계속 전역 변수에 업로드
	Global.player_x = global_position.x
	Global.player_y = global_position.y

	#구르기
	if Input.is_action_just_pressed("roll") and can_rolling:
		rolling = true
		can_rolling = false
		$Rolling_Timer.start()
		$Rolling_Again_Timer.start()
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		if rolling:
			velocity.x = direction * ROLL_SPEED
		else:
			velocity.x = direction * SPEED
		
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	# 좌우 뒤집기
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true
		
		
	# 동작 재생
	if rolling == false:
		if is_on_floor():
			if direction == 0:
				animated_sprite.play("idle")
			else:
				animated_sprite.play("run")
		else:
			animated_sprite.play("jump")
	else:
		animated_sprite.play("roll")

	move_and_slide()

# 구르기 멈추게 함
func _on_rolling_timer_timeout() -> void:
	rolling = false

#다시 구를 수 있게 함
func _on_rolling_again_timer_timeout() -> void:
	can_rolling = true
