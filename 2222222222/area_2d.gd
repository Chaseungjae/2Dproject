extends Area2D

func _on_EndTrigger_body_entered(body):
	if body.name == "CharacterBody2D":  # 또는 body.is_in_group("player")
		get_tree().change_scene_to_file("res://node_2d333.tscn")
