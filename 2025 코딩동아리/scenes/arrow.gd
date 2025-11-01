extends Area2D

@export var speed = 300.0
var direction = 1

func _physics_process(delta):
	position.x += speed * direction * delta
	if speed == 0 or direction == 0 or delta == 0 :
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("player"):
		#body.take_damage(10)  # 예시용
		queue_free()
	queue_free()
