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
		DEFAULT_VIEW.set_viewable(preload("res://content/vb_uv_grid.tres"))

	return DEFAULT_VIEW

var name : String
var viewable : Viewable
var uvs : PackedVector2Array = DEFAULT_UVS #nw, ne, sw, se
var auto_uv : bool = true
var material : Material # might just use a common material and apply post process shaders or something
var thumbnail : Texture2D
var id : int
var camera_idx : int = 0

func rename(_name : String):
	if _name != name:
		name = _name
		emit_changed()


func set_viewable(_viewable : Viewable, _camera_idx = -1):
	if viewable != _viewable:
		viewable = _viewable

		if _camera_idx > 0:
			camera_idx = _camera_idx
		#for now we'll just set this thumbnail to whatever the viewables thumb is
		viewable.connect("thumbnail_changed", set_thumbnail)
		emit_changed()


func set_thumbnail(_thumbnail : Texture2D):
	thumbnail = _thumbnail
	thumbnail_changed.emit(thumbnail)


func set_camera_idx(_idx : int):
	camera_idx = _idx


func set_uvs(_uvs : PackedVector2Array):
	uvs = _uvs
	uv_changed.emit(uvs)


func reset_uv():
	if uvs != DEFAULT_UVS:
		uvs = DEFAULT_UVS

func get_save_data():
	var data = {
		"id" : id,
		"name" : name,
		"viewable" : viewable.id,
		"uvs" : Array(var_to_bytes(uvs)),
		"auto_uv" : auto_uv,
		"camera_idx" : camera_idx
	}
	return data

static func from_save_data(data) -> View:
	var view = View.new()
	view.id = data.id
	view.rename(data.name)
	view.set_viewable(PEditorServer.getViewsDB().get_viewable(data.viewable))
	view.set_uvs(bytes_to_var(PackedByteArray(data.uvs)))
	view.auto_uv = data.auto_uv
	view.camera_idx = data.camera_idx
	return view
