extends Window


# Called when the node enters the scene tree for the first time.
func _ready():
	$SubViewportContainer.size = get_viewport().size


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_close_requested():
	self.queue_free()
