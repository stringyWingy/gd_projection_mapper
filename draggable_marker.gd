extends ColorRect

@export var vert_index : int
var dragging = false

signal dragged
var clickable_polygon = PackedVector2Array()

# Called when the node enters the scene tree for the first time.
func _ready():
	#build a quick quad of vectors to check against the mouse
	clickable_polygon.append_array([
		Vector2(0,0),
		Vector2(0, size.x),
		Vector2(size.y, 0),
		size
	])


func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if Geometry2D.is_point_in_polygon(get_local_mouse_position(), clickable_polygon):
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
