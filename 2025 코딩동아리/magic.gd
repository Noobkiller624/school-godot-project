extends Area2D

var speed = 300
var direction = Vector2.ZERO

func set_direction(dir: Vector2):
	direction = dir.normalized()
	rotation = dir.angle()

func _physics_process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	Global.HP -= 25
	print(Global.HP)
	queue_free()
