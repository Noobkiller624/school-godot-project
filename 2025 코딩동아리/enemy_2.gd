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
@onready var player_detecter: Area2D = $PlayerDetecter
@onready var collision_shape_2d: CollisionShape2D = $PlayerDetecter/CollisionShape2D

func _ready() -> void:
	# 애니메이션 프레임 변경 시점을 감지
	animated_sprite_2d.connect("frame_changed", Callable(self, "_on_frame_changed"))
	
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		
		
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
				attack()
				attacking = 1
				can_move = 0

#공격 다시 할 수 있게 함
func _on_attacking_timer_timeout() -> void:
	attacking = 0
	can_move = 1

#죽음. HP가 0 이하면 잘 작동하는거 확인함
func _on_visiable_timer_timeout() -> void:
	queue_free()

# 이제 attack()는 프레임 이벤트에서 데미지를 처리하므로 비워둠(필요하면 다른 처리 추가)
func attack():
	pass

# AnimatedSprite2D의 프레임이 바뀔 때 호출됨
func _on_frame_changed() -> void:
	# attack 애니메이션의 3번째 프레임일 때만 히트 판정 실행
	# (에디터에서 보는 3번째가 실제 인덱스와 다르면 숫자를 조정)
	if animated_sprite_2d.animation == "attack" and animated_sprite_2d.frame == 3:
		_apply_attack_hit()

# 실제로 감지된 영역들을 확인하고 Global.HP를 깎음
func _apply_attack_hit() -> void:
	var hit_parents: Array = []
	# Area2D로 감지된 영역들 (플레이어가 Area2D라면)
	var areas = player_detecter.get_overlapping_areas()
	for area in areas:
		var parent = area.get_parent()
		if parent and not hit_parents.has(parent) and _is_player_node(parent):
			hit_parents.append(parent)

	# PhysicsBody2D(플레이어가 PhysicsBody라면)도 확인
	var bodies = player_detecter.get_overlapping_bodies()
	for body in bodies:
		if body and not hit_parents.has(body) and _is_player_node(body):
			hit_parents.append(body)

	if hit_parents.size() == 0:
		return

	# 각 플레이어에 대해 Global.HP를 -5씩
	for p in hit_parents:
		# Global 오토로드가 있다고 가정. 없으면 경고 출력
		if Engine.is_editor_hint(): # 에디터에서 실행 중이면 그냥 디버그 메시지
			# (엔진 함수 호출을 피하려면 이 줄 지워도 됨)
			pass
		# 실제로 Global이 프로젝트에 있으면 감소시킴
		# (Global이 없다면 아래 줄에서 에러가 날 수 있으니, 필요한 경우 try/catch로 감싸도 됨)
		if typeof(Global) != TYPE_NIL:
			Global.HP -= 5
			print(Global.HP)
		else:
			push_warning("Global 오토로드가 설정되어 있지 않습니다. Global.HP를 감소시킬 수 없습니다.")

# 플레이어 판별 (이름 또는 그룹 기준으로)
func _is_player_node(n: Node) -> bool:
	if n == null:
		return false
	if n.name == "Player":
		return true
	if n.is_in_group("player"):
		return true
	return false
