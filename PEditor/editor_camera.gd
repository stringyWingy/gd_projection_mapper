extends Camera2D

var panning := false
var pan_start := Vector2(0,0)
var mouse_pan_start := Vector2(0,0)
const zoom_increment := Vector2(0.1,0.1)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _input(event):
	if event.is_action_pressed("view_zoom_in"):
		self.zoom += zoom_increment
	if event.is_action_pressed("view_zoom_out"):
		self.zoom -= zoom_increment
	if event.is_action_pressed("view_pan"):
		panning = true
		pan_start = self.position
		mouse_pan_start = get_local_mouse_position()
	if event.is_action_released("view_pan"):
		panning = false;

	if event is InputEventMouseMotion:
		if panning:
			self.position = pan_start + mouse_pan_start - get_local_mouse_position() 
