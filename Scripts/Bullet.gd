extends CharacterBody2D
class_name Bullet

@onready var AnimatedSprite: AnimatedSprite2D = $AnimatedSprite2D

var speed = 200
var num_bounces = 1
var is_active = true

func initialize(_speed: float, _direction: float):
	speed = _speed
	var direction = Vector2.RIGHT.rotated(_direction)
	velocity = direction.normalized() * speed
	rotation = velocity.angle()

func _physics_process(delta):
	if not is_active:
		return
	var collision = move_and_collide(velocity * delta) 
	if collision:
		handle_collision(collision)
		
func hit():
	is_active = false
	AnimatedSprite.play('explode')
	await AnimatedSprite.animation_finished
	queue_free()

func handle_collision(collision: KinematicCollision2D):
	var collider = collision.get_collider()
	if collider is Player or collider is Enemy or collider is Bullet:
		collider.hit()
		hit()
	elif num_bounces >= 1:
		num_bounces -= 1
		velocity = velocity.bounce(collision.get_normal())
		rotation = velocity.angle()
	elif num_bounces < 1:
		hit()
