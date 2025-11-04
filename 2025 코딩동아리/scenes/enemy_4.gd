extends CharacterBody2D

const SPEED = 50.0
var direction = -1
var attacking = 0
var can_move = 1
var HP = 100
var die = 0
var growing = 0
var casting = 0


@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_timer: Timer = $Attacking_Timer
@onready var visible_timer: Timer = $Visiable_Timer


func _process(delta: float) -> void:
	var distance = abs(Global.player_x - global_position.x)
	var distance_y = abs(Global.player_y - global_position.y)

	# ===== 이동 =====
	if can_move == 1 and casting == 0 :
		if distance < 300: #인식 범위
			if distance_y < 80 :
				if distance < 180 : #인식범위
					if Global.player_x - global_position.x > 0:
						direction = 1
						velocity.x = direction * SPEED
					else :
						direction = -1
						velocity.x = direction * SPEED
				else :
					if Global.player_x - global_position.x > 0:
						direction = -1
						velocity.x = direction * SPEED
					else :
						direction = 1
						velocity.x = direction * SPEED
		else :
			velocity.x = 0
			direction = 0
		move_and_slide()

	# ===== 좌우 반전 =====
	if can_move == 1 :
		if direction > 0:
			animated_sprite_2d.flip_h = false
		elif direction < 0:
			animated_sprite_2d.flip_h = true

	# ===== 애니메이션 =====
	if HP > 0:
		if attacking == 1 :
			animated_sprite_2d.play("attack-1")
		elif direction == 0 :
			animated_sprite_2d.play("idle")
		elif casting == 1 :
			animated_sprite_2d.play("casting")
		else:
			animated_sprite_2d.play("run")
	else:
		if die == 0 :
			die = 1
			animated_sprite_2d.play("die")
			visible_timer.start()

	# ===== 공격 처리 =====
	if attacking == 0 and HP > 0 :
		if distance < 80 and distance_y < 80 : # 공격범위
			attacking = 1
			can_move = 0
			attack_timer.start()


#거대화
	if growing == 0 :
		if distance < 180 and casting == 0 :
			grow()
	else :
		if distance > 180 and casting == 0 :
			ungrow()


# ===== 공격 쿨타임 끝 =====
func _on_attacking_timer_timeout() -> void:
	attacking = 0
	can_move = 1


# ===== 사망 처리 =====
func _on_visiable_timer_timeout() -> void:
	queue_free()

func grow():
	casting = 1
	can_move = 0
	growing = 1
	var tween = get_tree().create_tween()
	tween.tween_property(self, "scale", Vector2(5, 5), 2.0)  # 2초 동안 5배로 커짐
	
	
func ungrow():
	casting = 1
	can_move = 0
	growing = 0
	var tween = get_tree().create_tween()
	tween.tween_property(self, "scale", Vector2(1, 1), 2.0)  # 2초 동안 원래 크기로 돌아감
	
	
func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation == "casting" :
		casting = 0
		can_move = 1
