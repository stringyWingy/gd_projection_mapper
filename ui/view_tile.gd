extends PanelContainer

@onready var textureRect = $VBoxContainer/TextureRect
@onready var label = $VBoxContainer/Label
@onready var button = $Button
var viewable : Viewable = null
var view : View = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


func set_thumbnail_texture(texture : Texture):
	textureRect.texture = texture


func set_label_text(_label : String):
	label.set_text(_label)


func set_from_viewable(_viewable : Viewable):
	if _viewable.thumbnail != null:
		textureRect.set_texture(_viewable.thumbnail)
	_viewable.connect("thumbnail_changed", set_thumbnail_texture)
	label.text = _viewable.name
	viewable = _viewable
	viewable.connect("changed", _on_viewable_changed)

func set_from_view(_view : View):
	if _view.viewable.thumbnail != null:
		textureRect.set_texture(_view.viewable.thumbnail)
	_view.viewable.connect("thumbnail_changed", set_thumbnail_texture)
	label.text = _view.name
	view = _view
	view.connect("changed", _on_view_changed)

func set_button_group(group: ButtonGroup):
	button.set_button_group(group)

func _gui_input(event):
	pass

func _on_viewable_changed():
	set_from_viewable(viewable)

func _on_view_changed():
	set_from_view(view)
