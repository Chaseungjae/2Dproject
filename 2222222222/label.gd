extends Label

func _process(delta):
	if $".".position.y > -1000:
		$".".position.y -= 0.5
