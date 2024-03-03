extends CharacterBody2D
class_name Enemy

@export var speed = 150  # move speed in pixels/sec
@export var reverse_speed = 100
@export var rotation_speed = 1.5  # turning speed in radians/sec
@export var alert_distance = 1000 # distance from which the enemy should start moving
@export var engagement_distance = 750 # distance from which the enemy should start moving
@export var projectile_speed = 400
@export var max_consecutive_shots = 2

@onready var Bullet : PackedScene = preload("res://Scenes/Bullet.tscn")
@onready var collision_size = $CollisionShape2D.shape.get_rect().size
@onready var WeaponTimer: Timer = $WeaponTimer
@onready var ActionTimer: Timer = $ActionTimer
@onready var Ray: RayCast2D = $RayCast2D
@onready var NavAgent: NavigationAgent2D = $NavigationAgent2D
@onready var AnimatedSprite: AnimatedSprite2D = $AnimatedSprite2D

enum EnemyState {STATE_WAIT, STATE_MOVE, STATE_AIM}
var current_state = EnemyState.STATE_WAIT
var player: Player = null
var is_activated = false
var num_shots = 0
var is_alive = true

func _ready():
	player = get_tree().get_nodes_in_group("player")[0]
	# These values need to be adjusted for the actor's speed
	# and the navigation layout.
	NavAgent.path_desired_distance = 4.0
	NavAgent.target_desired_distance = 4.0
	# Make sure to not await during _ready.
	call_deferred("actor_setup")

func actor_setup():
	# Wait for the first physics frame so the NavigationServer can sync.
	await get_tree().physics_frame
	
func ai_process(delta):
	if current_state == EnemyState.STATE_WAIT:
		# Check for player within radius
		if (ActionTimer.is_stopped() and (is_activated or global_position.distance_to(player.global_position) < alert_distance)):
			current_state = EnemyState.STATE_MOVE
			nav_to_player(delta)

	elif current_state == EnemyState.STATE_MOVE:
		# If player within radius, move until they are within sightlines
		if (
			NavAgent.is_navigation_finished() or 
			(global_position.distance_to(player.global_position) < engagement_distance and Ray.get_collider() is Player)
		):
			current_state = EnemyState.STATE_AIM
		else:
			nav_to_player(delta)

	elif current_state == EnemyState.STATE_AIM:
		# check if we can fire at the player
		if Ray.get_collider() is Player and WeaponTimer.is_stopped():
			shoot()
			num_shots += 1
			if num_shots == max_consecutive_shots:
				ActionTimer.start()
				current_state = EnemyState.STATE_WAIT
				num_shots = 0
		else:
			# Rotate to face player
			var needed_rotation_direction = global_position.angle_to_point(player.global_position)
			rotation = rotate_toward(rotation, needed_rotation_direction, rotation_speed * delta)
		# check if player has gone further away and we need to disengage

func nav_to_player(delta):
	if (global_position.distance_to(player.global_position) > engagement_distance):
		NavAgent.target_position = player.global_position
	var next_path_position: Vector2 = NavAgent.get_next_path_position()
	var needed_rotation_direction = global_position.angle_to_point(next_path_position)
	rotation = rotate_toward(rotation, needed_rotation_direction, rotation_speed * delta)
	velocity = transform.x * speed
	move_and_slide()

func _physics_process(delta):
	if not is_alive:
		return
	if not player or player.is_queued_for_deletion():
		is_activated = false
	else:
		ai_process(delta)

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


func _on_bullet_detector_body_entered(body):
	# if a bullet is shot near the enemy, they should activate and look for the player
	is_activated = true
