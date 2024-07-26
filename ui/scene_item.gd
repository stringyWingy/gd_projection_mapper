extends PanelContainer

@onready var textureRect = $VBoxContainer/TextureRect
@onready var label = $VBoxContainer/Label

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func setTexture(texture : Texture):
	textureRect.texture = texture

func setLabel(str : String):
	label.text = str 

func setFromViewable(viewable : Viewable):
	if viewable.thumbnail != null:
		textureRect.set_texture(viewable.thumbnail)
	label.text = viewable.name
