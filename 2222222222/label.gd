extends Label
var time = GameState.elapsed_time
var hits = GameState.hit_count

func _ready() -> void:
	$"../Label2".text = "경과 시간: %.2f초\n 튕겨난 횟수: %d" % [time, hits]
func _process(delta):
	if $".".position.y > -1000:
		$".".position.y -= 0.5
		
	if $"../Label2".position.y > -1000:
		$"../Label2".position.y -= 0.005
