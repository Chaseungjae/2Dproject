extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D
@onready var camera = $Camera2D

@export var randomStrength:= 20.0
@export var shakeFade:= 5.0

var rng = RandomNumberGenerator.new()

var shake_strength:=0.0


const SPEED = 180.0
const GRAVITY = 35.0
const JUMP_FORCE = -500.0
const MAX_JUMP_FORCE = -1500.0
const MAX_HOLD_TIME = 0.6
const JUMP_ANGLE = 1.0
const MAX_X_SPEED = 500.0

var SLIDE_POWER = 1.3
var SLIDE_SPEED_POWER_X = -400.0


var SLIDE_TIME = SLIDE_POWER
var SLIDE_SPEED_X = SLIDE_SPEED_POWER_X
var SLIDE_Y = 2.5

var randomNum = RandomNumberGenerator.new()
var CTK = 50.0
var CTKbool = false


var jump_hold_time = 0.0
var is_jumping = false
var jump_direction = Vector2.RIGHT
var can_jump = false
var applied_jump_force = JUMP_FORCE
var is_sliding = false
var slide_timer = 0.0


var CTK_Num = 50

var default_camera_offset := Vector2.ZERO
var jump_camera_offset := Vector2(0, 100)
var fall_camera_offset := Vector2(0, -30)
var camera_lerp_speed := 5.0
var camera_target_offset := Vector2.ZERO
var maxcamera = 20
var mincamera = -40
var cacamemerara = 0

func _ready():
	default_camera_offset = camera.position
	camera_target_offset = default_camera_offset
	GameState.start_time = Time.get_ticks_msec() / 1000.0  # 시작 시간(초)로 저장
	default_camera_offset = camera.position
	camera_target_offset = default_camera_offset

func _CTK():
	
	if !CTKbool:
		CTK_Num = randomNum.randf_range(0, 100)
		if CTK_Num > CTK:
			CTKbool = true
		else:
			CTK = CTK - 10
		
func apply_shake():
	shake_strength = randomStrength
   
func randomOffset() -> Vector2:
	return Vector2(rng.randf_range(-shake_strength,shake_strength),rng.randf_range(-shake_strength,shake_strength))
		
		
func _physics_process(delta):
	if shake_strength > 0:
		shake_strength = lerpf(shake_strength,0,shakeFade*delta)
		camera.offset = randomOffset()
	
	if is_sliding:
		slide_timer -= delta
		if slide_timer <= 0.0:
			is_sliding = false
			animated_sprite.play("Waiting")
		else:
			velocity.x = SLIDE_SPEED_X
			velocity.y += GRAVITY
			animated_sprite.play("xxx")
			CTKbool = false
			SLIDE_SPEED_POWER_X = -400.0
			CTK = 50
			SLIDE_Y = 2.5
			#print("부딛")

	if not is_sliding:
		if is_on_floor():
			if not is_jumping and not Input.is_action_pressed("jump"):
				var direction = 0
				if Input.is_action_pressed("오른쪽"):
					animated_sprite.flip_h = false
					direction = 0.5
					jump_direction = Vector2.RIGHT
				elif Input.is_action_pressed("왼쪽"):
					animated_sprite.flip_h = true
					direction = -0.5
					jump_direction = Vector2.LEFT
				velocity.x = direction * SPEED
		velocity.y += GRAVITY

	if is_on_floor():
		if is_jumping:
			is_jumping = false
			can_jump = false
			animated_sprite.play("Jump3")
			await get_tree().create_timer(0.2).timeout
			if is_sliding == false:
				animated_sprite.play("Waiting")

		if Input.is_action_just_pressed("jump"):
			animated_sprite.play("Jump")
			jump_hold_time = 0.0
			can_jump = true
			applied_jump_force = JUMP_FORCE

	# 점프 유지
	if Input.is_action_pressed("jump") and can_jump:
		jump_hold_time += delta
		jump_hold_time = clamp(jump_hold_time , 0.0, MAX_HOLD_TIME)
		applied_jump_force = JUMP_FORCE + (MAX_JUMP_FORCE - JUMP_FORCE) * (jump_hold_time / MAX_HOLD_TIME)

	# 점프 해제 시 점프 시작
	if Input.is_action_just_released("jump") and can_jump:
		if not $AudioStreamPlayer2D2.playing:
				$AudioStreamPlayer2D2.play()
		velocity.y = applied_jump_force
		var jump_multiplier = abs(applied_jump_force) / abs(JUMP_FORCE)
		velocity.x = jump_direction.x * SPEED * JUMP_ANGLE * jump_multiplier
		velocity.x = clamp(velocity.x, -MAX_X_SPEED, MAX_X_SPEED)
		is_jumping = true
		can_jump = false
		camera_target_offset = jump_camera_offset

	if not is_on_floor() and velocity.y > 200 and not is_jumping:
		camera_target_offset = fall_camera_offset

	# 카메라 이동
	if Input.is_action_pressed("ui_up"):
		if cacamemerara < maxcamera:
			camera.position.y -= 10
			cacamemerara+= 1
	if Input.is_action_pressed("ui_down"):
		if cacamemerara > mincamera:
			camera.position.y += 10
			cacamemerara-= 1
		
		
	
	var prev_velocity = velocity
	move_and_slide()

	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if (collider and collider.name == "TileMapLayer2") or (collider.is_in_group("danger")):
			GameState.hit_count += 1
			_CTK()
			if CTKbool:
				SLIDE_SPEED_POWER_X = -600
				SLIDE_Y = 3.75
				velocity.y = JUMP_FORCE* 1.0
			else:
				SLIDE_SPEED_POWER_X = -400
				SLIDE_Y = 2.5
			apply_shake()
			velocity.y = (JUMP_FORCE * 0.5) * SLIDE_Y
			if not $AudioStreamPlayer2D.playing:
				$AudioStreamPlayer2D.play()
			is_jumping = true
			can_jump = false
			is_sliding = true
			slide_timer = SLIDE_TIME

	if is_jumping:
		for i in range(get_slide_collision_count()):
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			
			# TileMapLayer 충돌만 반사 처리
			if collider and collider.name == "TileMapLayer":
				var normal = collision.get_normal()
				if abs(normal.x) > 0.8:
					var jump_power_ratio = clamp(jump_hold_time / MAX_HOLD_TIME, 0.0, 1.0)
					var bounce_velocity = prev_velocity.bounce(normal)
					bounce_velocity *= lerp(0.4, 1.0, jump_power_ratio)
					bounce_velocity.x = clamp(bounce_velocity.x, -MAX_X_SPEED, MAX_X_SPEED)
					var extra_bounce_y = lerp(-300.0, -10.0, jump_power_ratio)
					bounce_velocity.y = min(bounce_velocity.y, extra_bounce_y)
					velocity = bounce_velocity
					animated_sprite.play("Jump1")
					#print("벽 반사됨! → 벡터:", bounce_velocity)
					break

	if velocity.y < 0:
		if velocity.y > -50:
			animated_sprite.play("Jump2")
		else:
			animated_sprite.play("Jump1")
	elif velocity.y > 0:
		animated_sprite.play("Jump4")

	if is_on_floor() and velocity.x != 0:
		velocity.x = lerp(velocity.x, 0.0, 0.2)


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "CharacterBody2D":
		GameState.elapsed_time = Time.get_ticks_msec() / 1000.0 - GameState.start_time
		get_tree().change_scene_to_file("res://node_2d333.tscn")
		
		#게임 종료 구현하면 끝 + 앞쪽에 조작법이랑 게임 시작 버튼
