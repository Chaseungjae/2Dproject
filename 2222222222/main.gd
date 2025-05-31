# GameState.gd
extends Node

var start_time := 0.0
var hit_count := 0
var elapsed_time := 0.0

func reset():
	start_time = 0.0
	hit_count = 0
	elapsed_time = 0.0
