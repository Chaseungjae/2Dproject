extends CharacterBody2D

@export var move_speed := 150.0 
@export var move_distance := 200.0 
@export var rotation_speed := 180.0 

var direction := 1
var start_position := Vector2.ZERO

func _ready():
	start_position = global_position

func _process(delta):

	global_position.y += direction * move_speed * delta

	rotation_degrees += rotation_speed * delta

	if abs(global_position.y - start_position.y) > move_distance:
		direction *= -1
