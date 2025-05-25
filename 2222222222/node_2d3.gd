extends CharacterBody2D

@export var move_speed := 150.0  # 이동 속도 (픽셀/초)
@export var move_distance := 200.0  # 총 이동 거리
@export var rotation_speed := 180.0  # 회전 속도 (도/초)

var direction := -1
var start_position := Vector2.ZERO

func _ready():
	start_position = global_position

func _process(delta):
	# 위치 업데이트
	global_position.y += direction * move_speed * delta

	# 회전
	rotation_degrees += rotation_speed * delta

	# 끝에 도달하면 방향 반전
	if abs(global_position.y - start_position.y) > move_distance:
		direction *= -1
