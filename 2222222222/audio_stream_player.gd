extends AudioStreamPlayer

func _ready():
	if stream is AudioStream:
		stream.loop = true
