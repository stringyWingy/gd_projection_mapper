extends PanelContainer

@onready var label = $HFlowContainer/Label
@onready var button_replace = $HFlowContainer/ButtonReplace
@onready var button_new = $HFlowContainer/ButtonNew
@onready var camera_select = %CameraSelect

var cameras = []

# Called when the node enters the scene tree for the first time.
func _ready():
	set_label_text("dangus")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func set_label_text(text : String):
	label.set_text(text)


func set_replace_valid(valid : bool):
	button_replace.visible = valid


func set_cameras(c : Array):
	camera_select.clear()
	if c.size() > 1:
		cameras = c
		camera_select.visible = true
		#populate dropdown button list
		for cc in cameras:
			camera_select.add_item(cc.name)
	else:
		camera_select.visible = false

func get_selected_camera_idx() -> int:
	return camera_select.selected
