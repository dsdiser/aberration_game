extends CharacterBody2D
class_name Bullet
var speed = 200
var num_bounces = 1


func initialize(_speed: float, _direction: float):
	speed = _speed
	var direction = Vector2.RIGHT.rotated(_direction)
	velocity = direction.normalized() * speed
	rotation = velocity.angle()

func _physics_process(delta):
	var collision = move_and_collide(velocity * delta) 
	if collision:
		handle_collision(collision)

func handle_collision(collision: KinematicCollision2D):
	if collision.get_collider().is_in_group("attackable"):
		collision.get_collider()
		body.kill()
	if num_bounces >= 1:
		num_bounces -= 1
		velocity = velocity.bounce(collision.get_normal())
		rotation = velocity.angle()
	elif num_bounces < 1:
		queue_free()
