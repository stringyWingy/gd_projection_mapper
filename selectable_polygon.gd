extends Polygon2D

signal clicked

var alphaToggle = false
var maxAlpha = 0.4 
var minAlpha = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _input(event):
	if event.is_action_pressed("left_click"):
		var mpos = get_local_mouse_position()
		if Geometry2D.is_point_in_polygon(mpos, self.polygon):
			clicked.emit()	

func toggleAlpha() -> void:
	alphaToggle = !alphaToggle
	self.color.a = maxAlpha if alphaToggle else minAlpha
