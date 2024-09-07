class_name Viewable
extends Resource

enum Type {
	SCENE_2D,
	SCENE_3D,
	TEXTURE2D,
	VIDEOSTREAM,
	VNC_TEXTURE,
	} 

#var name : String
@export var name : String = ""
@export var type : Type = Type.TEXTURE2D
@export var resource : Resource = null
var thumbnail : Texture2D = null
var id : int
var views_of : int = 0

#list of objects with
# name : name of camera
# path : relative path from root node to camera
var cameras = []

signal thumbnail_changed

func get_id():
	id = resource.resource_path.hash()
	return id


func setThumbnail():
	match type:
		Type.TEXTURE2D:
			thumbnail = resource
		_:
			#try and load a thumbnail from the cache
			#if we fail to, have the thumbnailer grab a new one
			var image = Image.new()
			var err = image.load("user://cache/thumbnails/vb_%s.webp" % name)

			if err != OK:
				print("cache miss for viewable %s thumbnail: %s" % [name, error_string(err)])
				image = await PEditorServer.getThumbnailer().capture_thumbnail_of(self)
			else:
				print("loaded cached thumbnail for viewable %s" % name)

			thumbnail = ImageTexture.create_from_image(image)

func set_thumbnail(image : Image):
	thumbnail = ImageTexture.create_from_image(image)
	thumbnail_changed.emit(thumbnail)

func rename(_name : String):
	if _name != name:
		name = _name
		emit_changed()
	
func get_save_data():
	var data = {
		"id" : id,
		"name" : name,
		"type" : type,
		"resource_path" : resource.resource_path
	}
	return data
