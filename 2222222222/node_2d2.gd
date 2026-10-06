extends CharacterBody2D

@export var move_speed := 200.0  
@export var move_distance := 300.0  
@export var rotation_speed := 180.0  

var direction := -1
var start_position := Vector2.ZERO

func _ready():
	start_position = global_position

func _process(delta):

	global_position.x += direction * move_speed * delta

	rotation_degrees += rotation_speed * delta

	if abs(global_position.x - start_position.x) > move_distance:
		direction *= -1
