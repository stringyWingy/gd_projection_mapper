extends PanelContainer

@onready var textureRect = $VBoxContainer/TextureRect
@onready var label = $VBoxContainer/Label
@onready var button = $Button

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func set_thumbnail_texture(texture : Texture):
	textureRect.texture = texture


func set_label_text(_label : String):
	label.text = _label


func set_from_viewable(viewable : Viewable):
	if viewable.thumbnail != null:
		textureRect.set_texture(viewable.thumbnail)
	label.text = viewable.name


func set_button_group(group: ButtonGroup):
	button.set_button_group(group)
