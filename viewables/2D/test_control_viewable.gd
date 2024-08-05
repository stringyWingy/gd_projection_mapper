extends Control

@onready var vp = $CenterContainer
var scale_flux := 0.3
var start_size : Vector2i
var t : float = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	start_size = vp.size
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	t += delta
	vp.set_size(start_size * 0.5 + start_size * 0.25 * sin(t))
