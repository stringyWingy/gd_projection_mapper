extends Polygon2D

signal clicked

enum Behavior {
	VISIBILITY,
	COLORTOGGLE
}

@export var color_highlight : Color
@export var color_normal : Color
@export var behavior : Behavior

var clickable = true

# Called when the node enters the scene tree for the first time.
func _ready():
	unhighlight()


func _input(event):
	if !clickable:
		return
	if event.is_action_pressed("left_click"):
		var mpos = get_local_mouse_position()
		if Geometry2D.is_point_in_polygon(mpos, self.polygon):
			clicked.emit(self)	


func set_clickable(value : bool):
	clickable = value

func highlight():
	if behavior == Behavior.VISIBILITY:
		self.visible = true
	if behavior == Behavior.COLORTOGGLE:
		self.color = color_highlight
	

func unhighlight():
	if behavior == Behavior.VISIBILITY:
		self.visible = false
	if behavior == Behavior.COLORTOGGLE:
		self.color = color_normal
