extends CharacterBody2D

const SPEED = 100.0
const ACCELERATE = 2.0
var direction = -1
var attacking = 0
var can_move = 1
var HP = 300 # 임의 체력. 언제든 수정 가능
var die = 0

@onready var enemy_1: CharacterBody2D = $"."
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _process(delta: float) -> void:
	# 플레이어와의 x 좌표 차이의 절댓값을 distance라는 변수로 정의
	var distance = abs(Global.player_x - global_position.x)
	# 플레이어와의 y 좌표 차이의 절댓값을 distance라는 변수로 정의
	var distance_y = abs(Global.player_y - global_position.y)
	
	#움직임
	if can_move == 1 :
		if distance < 200 : #인식 범위
			if distance_y < 30 :
				if distance < 80 : #인식 범위
					if Global.player_x - global_position.x > 0:
						direction = 1
						velocity.x = direction * SPEED * ACCELERATE
					else :
						direction = -1
						velocity.x = direction * SPEED * ACCELERATE
				else :
					if Global.player_x - global_position.x > 0:
						direction = 1
						velocity.x = direction * SPEED
					else :
						direction = -1
						velocity.x = direction * SPEED
		else :
			velocity.x = 0
			direction = 0
		move_and_slide()
	
	
	#좌우 뒤집기
	if direction > 0:
		animated_sprite_2d.flip_h = false
	elif direction < 0:
		animated_sprite_2d.flip_h = true
	
	
	#동작 재생
	if HP > 0 :
		if attacking == 1 :
			animated_sprite_2d.play("attack")
		elif direction == 0 :
			animated_sprite_2d.play("idle")
		else :
			if distance < 80 :
				animated_sprite_2d.play("run-lance")
			else :
				animated_sprite_2d.play("run")
	else :
		if die == 0 :
			die = 1
			animated_sprite_2d.play("die")
			$Visiable_Timer.start()
	
	
	#공격
	if distance < 20 : #공격 인식 범위
		if distance_y < 30 : # y좌표가 너무 다른데 공격하면 이상하니까 y좌표 차이도 인식
			if attacking == 0 :
				$Attacking_Timer.start()
				attacking = 1
				can_move = 0

#공격 다시 할 수 있게 함
func _on_attacking_timer_timeout() -> void:
	attacking = 0
	can_move = 1

#죽음. HP가 0 이하면 잘 작동하는거 확인함
func _on_visiable_timer_timeout() -> void:
	queue_free()
