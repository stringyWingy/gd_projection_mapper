class_name View
extends Resource

signal thumbnail_changed
signal uv_changed

static var DEFAULT_UVS = PackedVector2Array(
	[Vector2(0,0),
	Vector2(1,0),
	Vector2(0,1),
	Vector2(1,1)])

static var DEFAULT_VIEW : View = null

static func get_default_view() -> View:
	if !DEFAULT_VIEW:
		DEFAULT_VIEW = View.new()
		DEFAULT_VIEW.name = "DEFAULT VIEW"
		DEFAULT_VIEW.set_viewable(preload("res://viewables/vb_uv_grid.tres"))

		print("initialized get_default_view view %s" % DEFAULT_VIEW)
		
	return DEFAULT_VIEW

var name : String
var viewable : Viewable
var uvs : PackedVector2Array = DEFAULT_UVS #nw, ne, sw, se
var auto_uv : bool = true
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
	uv_changed.emit(uvs)


func reset_uv():
	if uvs != DEFAULT_UVS:
		uvs = DEFAULT_UVS

func get_save_data():
	var data = {
		"name" : name,
		"viewable" : viewable.name,
		"uvs" : var_to_bytes(uvs),
		"auto_uv" : auto_uv
	}
	return data
