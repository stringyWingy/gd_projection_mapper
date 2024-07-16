extends ColorRect

@export var vert_index : int
var dragging = false

signal dragged

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if (get_local_mouse_position() - size/2).length() < size.length()/2:
			if not dragging and event.pressed:
				dragging = true

		if dragging && !event.pressed:
			dragging = false

	if event is InputEventMouseMotion:
		if dragging:
			position += size/2
			position = position + get_local_mouse_position()
			dragged.emit(vert_index, position)
			position -= size/2

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
