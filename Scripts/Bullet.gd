extends CharacterBody2D
class_name Bullet

@onready var AnimatedSprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var AreaLight: PointLight2D = $AreaLight

var speed = 150
var num_bounces = 1
var is_active = true
var traveling_tween: Tween = null
var collision_enabled: bool = true

func initialize(_speed: float, _direction: float):
	speed = _speed
	var direction = Vector2.RIGHT.rotated(_direction)
	velocity = direction.normalized() * speed
	rotation = velocity.angle()

func _ready():
	traveling_tween = create_tween().set_loops()
	traveling_tween.tween_property(AreaLight, "texture_scale", AreaLight.texture_scale, .5).set_ease(Tween.EASE_IN)
	traveling_tween.tween_property(AreaLight, "texture_scale", AreaLight.texture_scale / 1.10, .5).set_ease(Tween.EASE_OUT)
	

func _physics_process(delta):
	if not is_active:
		return
	var collision = move_and_collide(velocity * delta) 
	if collision_enabled and collision:
		handle_collision(collision)

		
func hit():
	is_active = false
	AnimatedSprite.play('explode')
	traveling_tween.stop()
	var tween = create_tween()
	tween.tween_property(AreaLight, "texture_scale", AreaLight.texture_scale * 3, 1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	await AnimatedSprite.animation_finished
	await tween.finished
	traveling_tween.stop()
	queue_free()

func handle_collision(collision: KinematicCollision2D):
	var collider = collision.get_collider()
	# Drop duplicate colliders from bouncing off walls
	if (collider is Player or collider is Enemy or collider is Bullet):
		collider.hit()
		hit()
	elif num_bounces >= 1:
		num_bounces -= 1
		velocity = velocity.bounce(collision.get_normal())
		rotation = velocity.angle()
		disable_collision()
	elif num_bounces < 1:
		hit()


func disable_collision():
	# dirty hack to avoid wall collision getting triggered twice when the bullet bounces
	collision_enabled = false
	await get_tree().create_timer(.25).timeout
	collision_enabled = true


	
