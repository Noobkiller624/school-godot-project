extends CharacterBody2D

const SPEED = 50.0
var direction = -1
var attacking = 0
var can_move = 1
var HP = 100
var die = 0

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_timer: Timer = $Attacking_Timer
@onready var visible_timer: Timer = $Visiable_Timer
@onready var attacking_timer_2: Timer = $"Attacking_Timer-2"

@export var magic_scene: PackedScene
var player: Node2D

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		
func _ready():
	# 씬 안에서 이름이 "Player"인 노드를 찾아서 연결
	player = get_tree().get_root().find_child("Player", true, false)

func _process(delta: float) -> void:
	var distance = abs(Global.player_x - global_position.x)
	var distance_y = abs(Global.player_y - global_position.y)

# ===== 좌우 반전 =====
	if can_move == 1 :
		if distance < 300 : #인식 범위
			if distance_y < 100 :
				if Global.player_x - global_position.x > 0:
					direction = 1
				else :
					direction = -1
		else :
			direction = 0
		move_and_slide()

	if can_move == 1 :
		if direction > 0:
			animated_sprite_2d.flip_h = false
		elif direction < 0:
			animated_sprite_2d.flip_h = true

	# ===== 애니메이션 =====
	if HP > 0:
		if attacking == 1 :
			animated_sprite_2d.play("attack-1")
		if attacking == 2 :
			animated_sprite_2d.play("attack-2")
		elif can_move == 1 :
			animated_sprite_2d.play("idle")
	else:
		if die == 0 :
			die = 1
			animated_sprite_2d.play("die")
			visible_timer.start()

	# ===== 공격 처리 =====
	if distance < 300 : #공격 인식 범위
		if distance_y < 100 : # y좌표가 너무 다른데 공격하면 이상하니까 y좌표 차이도 인식
			if attacking == 0 :
				$Attacking_Timer.start()
				attacking = 1
				can_move = 0


# ===== 공격 쿨타임 끝 =====
func _on_attacking_timer_timeout() -> void:
	shoot_magic()
	attacking = 2
	$"Attacking_Timer-2".start()


func _on_attacking_timer_2_timeout() -> void:
	var distance = abs(Global.player_x - global_position.x)
	var distance_y = abs(Global.player_y - global_position.y)
	if distance < 300 : #인식 범위
			if distance_y < 100 :
				if Global.player_x - global_position.x > 0:
					direction = 1
				else :
					direction = -1
			else :
				direction = 0
			move_and_slide()
	if direction > 0:
		animated_sprite_2d.flip_h = false
	elif direction < 0:
		animated_sprite_2d.flip_h = true
	if distance < 300 : #공격 인식 범위
		if distance_y < 100 : # y좌표가 너무 다른데 공격하면 이상하니까 y좌표 차이도 인식
			$Attacking_Timer.start()
			attacking = 1
			can_move = 0
		else :
			can_move = 1
			attacking = 0
	else :
			can_move = 1
			attacking = 0

# ===== 사망 처리 =====
func _on_visiable_timer_timeout() -> void:
	queue_free()

func shoot_magic():
	if not player or not magic_scene:
		return

	var magic = magic_scene.instantiate()
	get_parent().add_child(magic)

	# 플레이어를 바라보는 방향 계산
	var dir = (player.global_position - global_position).normalized()

	# 마법을 마법사 앞쪽에 생성
	magic.global_position = global_position + dir * 20
	magic.global_position.y -= 10
	magic.set_direction(dir)
