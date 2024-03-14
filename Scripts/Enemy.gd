extends CharacterBody2D
class_name Enemy

@export var speed = 50  # move speed in pixels/sec
@export var reverse_speed = 25
@export var rotation_speed = .75  # turning speed in radians/sec
@export var alert_distance = 500 # distance from which the enemy should start moving
@export var engagement_distance = 300 # distance from which the enemy should start shooting
@export var projectile_speed = 200
@export var max_consecutive_shots = 2
@export var bullet_scene : PackedScene

@onready var WeaponTimer: Timer = $WeaponTimer
@onready var ActionTimer: Timer = $ActionTimer
@onready var Ray: RayCast2D = $RayCast2D
@onready var NavAgent: NavigationAgent2D = $NavigationAgent2D
@onready var AnimatedSprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var MuzzleAim: Marker2D = $MuzzleAim
@onready var AimingLine: Line2D = $AimingLine
@onready var AimingRay: RayCast2D = $AimingRay
@onready var ShootEffect: AudioStreamPlayer = $ShootEffect
@onready var ReloadEffect: AudioStreamPlayer = $ReloadEffect

enum EnemyState {STATE_WAIT, STATE_MOVE, STATE_AIM}
var current_state = EnemyState.STATE_WAIT
var player: Player = null
var is_activated = false
var num_shots = 0
var is_alive = true

func _ready():
	player = get_tree().get_nodes_in_group("player")[0]
	# Make sure to not await during _ready.
	call_deferred("actor_setup")

func actor_setup():
	# Wait for the first physics frame so the NavigationServer can sync.
	await get_tree().physics_frame
	
func ai_process(delta):
	if current_state == EnemyState.STATE_WAIT:
		# Check for player within radius
		if (ActionTimer.is_stopped() and (is_activated or global_position.distance_to(player.global_position) < alert_distance)):
			if AimingLine.hidden:
				AimingLine.show()
				await get_tree().create_timer(.75).timeout
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

func nav_to_player(delta):
	if (global_position.distance_to(player.global_position) > engagement_distance):
		NavAgent.target_position = player.global_position
	var next_path_position: Vector2 = NavAgent.get_next_path_position()
	var needed_rotation_direction = global_position.angle_to_point(next_path_position)
	var rotation_ratio = clampf(abs(needed_rotation_direction) / abs(rotation), 0, 1)
	rotation = rotate_toward(rotation, needed_rotation_direction, rotation_speed * delta)
	velocity = transform.x * rotation_ratio * speed
	move_and_slide()


func _physics_process(delta):
	if not is_alive:
		return
	if not player or player.is_queued_for_deletion():
		is_activated = false
	else:
		ai_process(delta)
		
func _process(_delta):
	if is_alive:
		update_trajectory()


func hit():
	# Add hit effect
	if (AnimatedSprite.animation != 'explode'):
		AnimatedSprite.play('explode')
		is_alive = false
		AimingLine.hide()
		await AnimatedSprite.animation_finished
		queue_free()


func shoot():
	# create bullet
	ReloadEffect.stop()
	WeaponTimer.start()
	var b: Bullet = bullet_scene.instantiate()
	b.initialize(projectile_speed, rotation)
	owner.add_child(b)
	b.transform = $Muzzle.global_transform
	ShootEffect.play()
	await ShootEffect.finished
	ReloadEffect.play()


func update_trajectory():
	AimingLine.clear_points()
	AimingLine.add_point(MuzzleAim.position)
	# raycast until we hit a collider, that is our final point
	if AimingRay.is_colliding():
		var collision_point = to_local(AimingRay.get_collision_point())
		var difference_ratio = (MuzzleAim.position.distance_to(collision_point) - AimingLine.width) / MuzzleAim.position.distance_to(collision_point)
		var point = (1 - difference_ratio) * MuzzleAim.position + difference_ratio * collision_point
		AimingLine.add_point(point)
	else:
		AimingLine.add_point(Vector2(transform.x.x + 10000, transform.x.y))
	


func _on_bullet_detector_body_entered(_body):
	# if a bullet is shot near the enemy, they should activate and look for the player
	await get_tree().create_timer(2.0).timeout
	is_activated = true
