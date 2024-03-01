extends CharacterBody2D

@export var speed = 400  # move speed in pixels/sec
@export var reverse_speed = 200
@export var rotation_speed = 1.5  # turning speed in radians/sec

@onready var Bullet : PackedScene = preload("res://Scenes/Bullet.tscn")
@onready var collision_size = $CollisionShape2D.shape.get_rect().size
@onready var WeaponTimer: Timer = $WeaponTimer


var collision

func _ready():
	pass

func _physics_process(delta):
	var move_input = Input.get_axis("move_down", "move_up")
	var rotation_direction = Input.get_axis("move_left", "move_right")
	if move_input < 0:
		velocity = transform.x * move_input * reverse_speed
	else:
		velocity = transform.x * move_input * speed
	rotation += rotation_direction * rotation_speed * delta
	move_and_slide()

func _process(delta):
	if Input.is_action_just_pressed("shoot") and WeaponTimer.is_stopped():
		shoot()

func shoot():
	# create bullet
	WeaponTimer.start()
	var b: Bullet = Bullet.instantiate()
	b.initialize(speed + 100, rotation)
	owner.add_child(b)
	b.transform = $Muzzle.global_transform