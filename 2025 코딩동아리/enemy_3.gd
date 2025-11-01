extends CharacterBody2D

const SPEED = 50.0
var direction = -1
var attacking = 0
var can_move = 1
var HP = 100
var die = 0

# 투사체 속도 (화살)
const ARROW_SPEED = 300.0

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_timer: Timer = $Attacking_Timer
@onready var visible_timer: Timer = $Visiable_Timer


@export var ArrowScene: PackedScene

func _process(delta: float) -> void:
	var distance = abs(Global.player_x - global_position.x)
	var distance_y = abs(Global.player_y - global_position.y)

	# ===== 이동 =====
	if can_move == 1 and animated_sprite_2d.animation == "run" or can_move == 1 and animated_sprite_2d.animation == "idle" :
		if distance < 250: #인식 범위
			if distance_y < 30 :
				if distance < 180 : #인식범위
					if distance > 100 :
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
		elif direction == 0 or can_move == 0 :
			animated_sprite_2d.play("idle")
		else:
			animated_sprite_2d.play("run")
	else:
		if die == 0 :
			die = 1
			animated_sprite_2d.play("die")
			visible_timer.start()

	# ===== 공격 처리 =====
	if attacking == 0 and HP > 0 :
		if 100 < distance and distance < 180 and distance_y < 30 : # 공격범위
			attacking = 1
			can_move = 0


# ===== 화살 발사 함수 =====
func _shoot_arrow() -> void:
	if ArrowScene == null:
		print("ArrowScene not assigned!")
		return

	var arrow = ArrowScene.instantiate()
	get_parent().add_child(arrow)

	# 적 위치에서 화살 생성
	arrow.global_position = global_position + Vector2(direction * 10, 11)
	arrow.direction = direction
	arrow.speed = ARROW_SPEED


# ===== 공격 쿨타임 끝 =====
func _on_attacking_timer_timeout() -> void:
	can_move = 1


# ===== 사망 처리 =====
func _on_visiable_timer_timeout() -> void:
	queue_free()


func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation == "attack-1" :
		attacking = 0
		_shoot_arrow()
		attack_timer.start()
		if Global.player_x - global_position.x > 0:
			direction = 1
		else :
			direction = -1
		if direction > 0:
			animated_sprite_2d.flip_h = false
		elif direction < 0:
			animated_sprite_2d.flip_h = true
