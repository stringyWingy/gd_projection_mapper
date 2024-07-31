class_name View
extends Resource

signal thumbnail_changed

var name : String
var viewable : Viewable
var uvs : PackedVector2Array #nw, ne, sw, se
var material : Material # might just use a common material and apply post process shaders or something
var thumbnail : Texture2D

func rename(_name : String):
	if _name != name:
		name = _name
		emit_changed()

func set_viewable(_viewable : Viewable):
	if viewable != _viewable:
		viewable = _viewable
		#for now we'll just set this thumbnail to whatever the viewables thumb is
		viewable.connect("thumbnail_changed", set_thumbnail)
		emit_changed()

func set_thumbnail(_thumbnail : Texture2D):
	thumbnail = _thumbnail
	thumbnail_changed.emit(thumbnail)


func set_uvs(_uvs : PackedVector2Array):
	uvs = _uvs
