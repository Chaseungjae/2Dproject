extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D
@onready var camera = $Camera2D

@export var randomStrength:= 30.0
@export var shakeFade:= 5.0

var rng = RandomNumberGenerator.new()

var shake_strength:=0.0

# 이동 및 점프 상수
const SPEED = 180.0
const GRAVITY = 35.0
const JUMP_FORCE = -500.0
const MAX_JUMP_FORCE = -1500.0
const MAX_HOLD_TIME = 0.6
const JUMP_ANGLE = 1.0
const MAX_X_SPEED = 500.0

var SLIDE_POWER = 1.3
var SLIDE_SPEED_POWER_X = -400.0

# 슬라이딩 관련
var SLIDE_TIME = SLIDE_POWER
var SLIDE_SPEED_X = SLIDE_SPEED_POWER_X
var SLIDE_Y = 2.5
#크리티컬
var randomNum = RandomNumberGenerator.new()
var CTK = 50.0
var CTKbool = false


# 점프 상태
var jump_hold_time = 0.0
var is_jumping = false
var jump_direction = Vector2.RIGHT
var can_jump = false
var applied_jump_force = JUMP_FORCE
var is_sliding = false
var slide_timer = 0.0


var CTK_Num = 50
# 카메라 이동 관련
var default_camera_offset := Vector2.ZERO
var jump_camera_offset := Vector2(0, 100)
var fall_camera_offset := Vector2(0, -30)
var camera_lerp_speed := 5.0
var camera_target_offset := Vector2.ZERO

func _ready():
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
	# 슬라이딩 처리
	if shake_strength > 0:
		shake_strength = lerpf(shake_strength,0,shakeFade*delta)
		camera.offset = randomOffset()
	
	if is_sliding:
		slide_timer -= delta
		if slide_timer <= 0.0:
			is_sliding = false
			# 슬라이딩 종료 시 "Waiting" 애니메이션 재생
			animated_sprite.play("Waiting")
			#print("슬라이딩 종료")
		else:
			velocity.x = SLIDE_SPEED_X
			velocity.y += GRAVITY
			# 슬라이딩 애니메이션 유지
			animated_sprite.play("xxx")
			CTKbool = false
			SLIDE_SPEED_POWER_X = -400.0
			CTK = 50
			SLIDE_Y = 2.5
			#print("부딪")
			#print("슬라이딩 중")

	# 슬라이딩 아닐 때 이동 처리
	if not is_sliding:
		# 바닥에서 입력 처리
		if is_on_floor():
			if not is_jumping and not Input.is_action_pressed("jump"):
				var direction = 0
				if Input.is_action_pressed("오른쪽"):
					animated_sprite.scale.x = 1
					direction = 0.5
					jump_direction = Vector2.RIGHT
				elif Input.is_action_pressed("왼쪽"):
					animated_sprite.scale.x = -1
					direction = -0.5
					jump_direction = Vector2.LEFT
				velocity.x = direction * SPEED

		# 중력 적용
		velocity.y += GRAVITY

	# 착지 시 처리
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
		velocity.y = applied_jump_force
		var jump_multiplier = abs(applied_jump_force) / abs(JUMP_FORCE)
		velocity.x = jump_direction.x * SPEED * JUMP_ANGLE * jump_multiplier
		velocity.x = clamp(velocity.x, -MAX_X_SPEED, MAX_X_SPEED)
		is_jumping = true
		can_jump = false
		camera_target_offset = jump_camera_offset

	# 낙하 중일 때 카메라 아래로
	if not is_on_floor() and velocity.y > 200 and not is_jumping:
		camera_target_offset = fall_camera_offset

	# 카메라 이동
	if Input.is_action_pressed("ui_up"):
		camera.position.y -= 10
	if Input.is_action_pressed("ui_down"):
		camera.position.y += 10
		
		
	
	# 이동 처리 (여기서 반드시 move_and_slide 호출)
	var prev_velocity = velocity
	move_and_slide()

	# 충돌 처리 - 이제 안전하게 실행됨
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if (collider and collider.name == "TileMapLayer2") or (collider.is_in_group("danger")):
			#var bounce_strength = 3.5 #속도비율
			#velocity.x = -600 * bounce_strength
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
			is_jumping = true
			can_jump = false
			is_sliding = true
			slide_timer = SLIDE_TIME
			# 슬라이딩 애니메이션 시작
			#animated_sprite.play("xxx")
			
			#print(SLIDE_SPEED_POWER_X)
			#print(SLIDE_Y)
			#print(CTK)

	# 벽 반사 처리 (TileMapLayer2에서만 반사 처리)
	if is_jumping:
		for i in range(get_slide_collision_count()):
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			
			# TileMapLayer 충돌만 반사 처리
			if collider and collider.name == "TileMapLayer":
				var normal = collision.get_normal()
				if abs(normal.x) > 0.8:  # 벽 반사 조건
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

	# 애니메이션 처리
	if velocity.y < 0:
		if velocity.y > -50:
			animated_sprite.play("Jump2")
		else:
			animated_sprite.play("Jump1")
	elif velocity.y > 0:
		animated_sprite.play("Jump4")

	if is_on_floor() and velocity.x != 0:
		velocity.x = lerp(velocity.x, 0.0, 0.2)

# 에어리어 충돌 시
func _on_area_2d_2_area_entered(area: Area2D) -> void:
	pass
