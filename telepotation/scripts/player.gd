extends CharacterBody2D

const SPEED: float = 180.0
const JUMP_VELOCITY: float = -330.0


# --- 순간이동 시 중력 약화 관련 ---
@export var gravity_low_factor: float = 0.3
@export var gravity_recover_time: float = 2.0

# --- 순간이동 잔상/페이드 관련 ---
@export var total_fade_time: float = 0.5    # 잔상 페이드 지속 시간 (초)
@export var fade_scale: float = 1.08
@export var fade_tween_trans = Tween.TRANS_SINE
@export var fade_tween_ease = Tween.EASE_IN_OUT

# 이동 동작 옵션
@export var instant_stop: bool = true
@export var decel_rate: float = 600.0
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var gravity_normal: float = 0.0
var gravity_timer: float = 0.0
var is_teleporting: bool = false

#총알
@export var Bullet : PackedScene

	#총알	
func shoot():
	var b = Bullet.instantiate()
	get_parent().add_child(b)
	
	# 총알 위치를 총구 위치로 설정
	b.global_position = $Muzzle.global_position
	
	# 마우스 포인터 방향으로 총알 회전
	var mouse_pos = get_global_mouse_position()
	b.look_at(mouse_pos)
	
	
func _ready() -> void:
	gravity_normal = float(ProjectSettings.get_setting("physics/2d/default_gravity"))

func _physics_process(delta: float) -> void:
	# gravity 보간 (순간이동 직후 약화 -> 서서히 복구)
	var interpolated_gravity: float = gravity_normal
	if gravity_timer > 0.0:
		gravity_timer = max(gravity_timer - delta, 0.0)
		var t: float = clamp(1.0 - gravity_timer / gravity_recover_time, 0.0, 1.0)
		var low_val: float = gravity_normal * gravity_low_factor
		interpolated_gravity = lerp(low_val, gravity_normal, t)

	# 올라갈 때는 정상 중력, 내려올 때만 약화 중력 적용
	var current_gravity: float = gravity_normal
	if velocity.y < 0.0:
		current_gravity = gravity_normal
	else:
		current_gravity = interpolated_gravity

	# 중력 적용
	if not is_on_floor():
		velocity.y += current_gravity * delta
	else:
		if velocity.y > 0.0:
			velocity.y = 0.0

	# 점프
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# 좌우 이동 (원래 네 Input 이름 사용)
	var direction: float = Input.get_axis("move_left", "move_right")
	
	# 좌우 뒤집기
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true
		
		
	# 동작 재생
	if is_on_floor():
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")
	else:
		animated_sprite.play("jump")
	
		#총알
	if Input.is_action_just_pressed("shoot"):
		shoot()
	
	
	
	if direction != 0.0:
		velocity.x = direction * SPEED
	else:
		if instant_stop:
			velocity.x = 0.0
		else:
			var sign_val: float = float(sign(velocity.x))
			var new_speed: float = float(max(abs(velocity.x) - decel_rate * delta, 0.0))
			velocity.x = new_speed * sign_val

	move_and_slide()
	


	
	
func _unhandled_input(event):
	if is_teleporting:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		var target: Vector2 = get_global_mouse_position()
		if _is_safe_to_teleport(target):
			is_teleporting = true
			await _teleport_with_ghost(target)
			is_teleporting = false

# ---- 핵심: 순간이동 + 이전 위치에 정확한 잔상 생성 + 동시 페이드 ----
func _teleport_with_ghost(target: Vector2) -> void:
	# 시각 노드(주로 Sprite2D 같은 Node2D)를 찾아옴
	var visual := _get_visual_node()
	if visual == null:
		# 시각 노드가 없으면 안전하게 그냥 이동
		global_position = target
		gravity_timer = gravity_recover_time
		velocity = Vector2.ZERO
		return

	# 원래 컬러/스케일 보관
	var orig_mod: Color = visual.modulate
	var orig_alpha: float = float(orig_mod.a)
	var orig_scale: Vector2 = Vector2.ONE
	if visual is Node2D:
		orig_scale = (visual as Node2D).scale

	# 1) 순간이동 '직전' 현재 위치에 잔상 생성 (정확한 월드좌표)
	var ghost := visual.duplicate() as Node
	# duplicate()로 받은 노드는 'local' 상태일 수 있으므로 부모를 동일한 부모에 붙이고 글로벌 위치로 맞춤
	get_parent().add_child(ghost)
	# ghost가 Node2D이면 global_position 설정
	if ghost is Node2D:
		(ghost as Node2D).global_position = (visual as Node2D).global_position
	# 보정: 잔상 알파를 확실히 1으로 세팅
	if ghost is CanvasItem:
		(ghost as CanvasItem).modulate = Color(orig_mod.r, orig_mod.g, orig_mod.b, orig_alpha)

	# 2) 본체는 새 위치에서 '투명 상태'로 준비 후 즉시 이동
	#    (투명으로 만들어서 새 위치에서 서서히 나타나게 함)
	if visual is CanvasItem:
		visual.modulate = Color(orig_mod.r, orig_mod.g, orig_mod.b, 0.0)
	# 실제 순간이동(물리/중력 초기화)
	global_position = target
	gravity_timer = gravity_recover_time
	velocity = Vector2.ZERO

	# 3) 동시에 페이드: 본체는 0->orig_alpha, 잔상은 orig_alpha->0 (total_fade_time 동안)
	var tween := create_tween()
	# 본체 나타남
	tween.tween_property(visual, "modulate:a", orig_alpha, total_fade_time).set_trans(fade_tween_trans).set_ease(fade_tween_ease)
	# 잔상 사라짐
	if ghost is CanvasItem:
		tween.parallel().tween_property(ghost as CanvasItem, "modulate:a", 0.0, total_fade_time).set_trans(fade_tween_trans).set_ease(fade_tween_ease)
	if ghost is Node2D:
		tween.parallel().tween_property(ghost as Node2D, "scale", orig_scale * fade_scale, total_fade_time).set_trans(fade_tween_trans).set_ease(fade_tween_ease)

	await tween.finished
	# 잔상 제거
	if is_instance_valid(ghost):
		ghost.queue_free()

# 시각 노드 찾기: Sprite2D 우선, 없으면 첫번째 Node2D CanvasItem 반환
func _get_visual_node() -> Node2D:
	for child in get_children():
		if child is Sprite2D:
			return child as Node2D
	for child in get_children():
		if child is Node2D and child is CanvasItem:
			return child as Node2D
	return null

func _is_safe_to_teleport(pos: Vector2) -> bool:
	var params := PhysicsPointQueryParameters2D.new()
	params.position = pos
	params.collide_with_bodies = true
	params.collide_with_areas = true
	var results := get_world_2d().direct_space_state.intersect_point(params)
	return results.size() == 0
