extends Line2D

enum Behavior {
	VISIBILITY,
	COLORTOGGLE
}

@export var color_highlight : Color
@export var color_normal : Color
@export var behavior : Behavior


func highlight():
	if behavior == Behavior.VISIBILITY:
		self.visible = true
	if behavior == Behavior.COLORTOGGLE:
		self.default_color = color_highlight
	

func unhighlight():
	if behavior == Behavior.VISIBILITY:
		self.visible = false
	if behavior == Behavior.COLORTOGGLE:
		self.default_color = color_normal


func _ready():
	self.unhighlight()
