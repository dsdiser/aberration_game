extends CharacterBody2D
class_name Player

@export var speed = 200  # move speed in pixels/sec
@export var reverse_speed = 100
@export var rotation_speed = 1.5  # turning speed in radians/sec
@export var projectile_speed = 400

@onready var Bullet : PackedScene = preload("res://Scenes/Bullet.tscn")
@onready var collision_size = $CollisionShape2D.shape.get_rect().size
@onready var WeaponTimer: Timer = $WeaponTimer
@onready var AnimatedSprite: AnimatedSprite2D = $AnimatedSprite2D

var is_alive = true

func _ready():
	pass

func _physics_process(delta):
	if not is_alive:
		return
	var move_input = Input.get_axis("move_down", "move_up")
	var rotation_direction = Input.get_axis("move_left", "move_right")
	if move_input < 0:
		velocity = transform.x * move_input * reverse_speed
	else:
		velocity = transform.x * move_input * speed
	rotation += rotation_direction * rotation_speed * delta
	move_and_slide()

func _process(delta):
	if not is_alive:
		return
	if Input.is_action_just_pressed("shoot") and WeaponTimer.is_stopped():
		shoot()

func hit():
	# Add hit effect
	if (AnimatedSprite.animation != 'explode'):
		AnimatedSprite.play('explode')
		is_alive = false
		await AnimatedSprite.animation_finished
		queue_free()

func shoot():
	# create bullet
	WeaponTimer.start()
	var b: Bullet = Bullet.instantiate()
	b.initialize(projectile_speed, rotation)
	owner.add_child(b)
	b.transform = $Muzzle.global_transform
