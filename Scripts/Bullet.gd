extends CharacterBody2D
class_name Bullet

@onready var AnimatedSprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var AreaLight: PointLight2D = $AreaLight

var speed = 150
var num_bounces = 1
var is_active = true
var prev_collision_id: int = -1
var traveling_tween: Tween = null

func initialize(_speed: float, _direction: float):
	speed = _speed
	var direction = Vector2.RIGHT.rotated(_direction)
	velocity = direction.normalized() * speed
	rotation = velocity.angle()

func _ready():
	traveling_tween = get_tree().create_tween().set_loops()
	traveling_tween.tween_property(AreaLight, "texture_scale", AreaLight.texture_scale, .5).set_ease(Tween.EASE_IN)
	traveling_tween.tween_property(AreaLight, "texture_scale", AreaLight.texture_scale / 1.10, .5).set_ease(Tween.EASE_OUT)
	

func _physics_process(delta):
	if not is_active:
		return
	var collision = move_and_collide(velocity * delta) 
	if collision:
		handle_collision(collision)

		
func hit():
	is_active = false
	AnimatedSprite.play('explode')
	traveling_tween.stop()
	var tween = get_tree().create_tween()
	tween.tween_property(AreaLight, "texture_scale", AreaLight.texture_scale * 3, 1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	await AnimatedSprite.animation_finished
	await tween.finished
	queue_free()

func handle_collision(collision: KinematicCollision2D):
	var collider = collision.get_collider()
	if (collider is Player or collider is Enemy or collider is Bullet) and prev_collision_id != collision.get_collider_id():
		prev_collision_id = collision.get_collider_id()
		collider.hit()
		hit()
	elif num_bounces >= 1 :
		num_bounces -= 1
		velocity = velocity.bounce(collision.get_normal())
		rotation = velocity.angle()
	elif num_bounces < 1:
		hit()
