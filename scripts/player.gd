extends KinematicBody2D


onready var sprite = $Sprite
onready var animation = $AnimationPlayer
onready var floorDetector = $Sprite/floorDetector

export var friction: float 			= 0
export var floor_friction: float	= 0
export var air_friction: float 		= 0
export var vel_max: int 			= 0
export var acceleration: int 		= 0
export var jumpforce: int 			= 0
export var cut_height: float 		= 0

const UP: Vector2					= Vector2.UP
const MAX_SLOPE_ANGLE:int = 46

enum states {
	IDLE,
	WALKING,
	ATTACKING,
	JUMPING,
	DAMAGED,
	CUTSCENE
}

export var GRAVITY: int 			= 0
export var fallspd_max				= 0

var motion: Vector2					= Vector2.ZERO
var snap_vector: Vector2 = Vector2.ZERO
var on_slope: bool = false
var currentState = states.IDLE

func _ready():
	pass


func _physics_process(delta):
	var input_vector = check_input_vector()

	match currentState:
		states.IDLE:
			apply_gravity()
			apply_horizontal_force(input_vector)
			check_if_on_slope()
			update_snap_vector()
			check_jump()
			check_attack()
			movement(input_vector)
			update_animations(input_vector)
			pass
		states.WALKING:
			apply_gravity()
			apply_horizontal_force(input_vector)
			check_if_on_slope()
			update_snap_vector()
			check_jump()
			check_attack()
			movement(input_vector)
			update_animations(input_vector)
			pass
		states.ATTACKING:

			pass
		states.JUMPING:
			apply_gravity()
			apply_horizontal_force(input_vector)
			check_attack()
			movement(input_vector)
			update_animations(input_vector)
			pass
		states.DAMAGED:
			apply_gravity()
			movement(input_vector)
			pass
		states.CUTSCENE:

			pass


func check_input_vector():
	var input_vector = Vector2.ZERO
	input_vector = int( Input.get_action_strength( "k_right" ) ) - int( Input.get_action_strength( "k_left" ) )
	return input_vector


func check_attack() -> void:
	if Input.is_action_just_pressed("k_attack"):
		return		


func apply_horizontal_force(input_vector) -> void:
	if input_vector != 0:
		motion.x += input_vector * acceleration
		motion.x = clamp(motion.x, -vel_max, vel_max)


func apply_gravity() -> void:
	if not is_on_floor():
		motion.y += GRAVITY
		motion.y = min(motion.y, fallspd_max)

func movement(input_vector) -> void:
	var last_position = position
	
	# Check user input to get current direction
	# 0 = neutral
	# 1 = right
	# 3 = left
	if input_vector == 0:
		if not is_on_floor():
			friction = air_friction
		else:
			friction = floor_friction

		motion.x = lerp( motion.x, 0, friction )
	
	motion = move_and_slide_with_snap(motion, snap_vector*4, UP, true, 4, deg2rad(MAX_SLOPE_ANGLE))

#	SLOPE SLIDING FIX (hack)
	if is_on_floor() and get_floor_velocity().length() == 0 and abs(motion.x) < 1:
		position.x = last_position.x

func _input(event) -> void:
	if event.is_action_released("k_jump_action"):
		if motion.y < 0:
			motion.y *= cut_height


func check_jump() -> void:
	if is_on_floor():
		if Input.is_action_just_pressed("k_jump_action"):
			motion.y = 0
			jump(jumpforce)


func jump(force:float) -> void:
	motion.y -= force
	snap_vector = Vector2.ZERO


func check_if_on_slope() -> void:
	if floorDetector.get_collision_normal().y < -0.99:
		on_slope = true
	else:
		on_slope = false


func update_snap_vector() -> void:
	if is_on_floor():
		snap_vector = Vector2.DOWN


func update_animations(input_vector) -> void:
	if input_vector != 0:
		sprite.scale.x = input_vector
		if is_on_floor():
			animation.play("walk")
	else:
		if is_on_floor():
			animation.play("idle")
	if not is_on_floor():
		if motion.y > 70:
			animation.play("fall")
		else:
			animation.play("jump")


func _on_Hurtbox_hit(damage_amount):
	print("Damage received:", damage_amount)
	Global.camera.shake(0.2,1)
