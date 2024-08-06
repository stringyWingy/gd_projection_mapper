class_name Viewable
extends Resource

enum Type {
	SCENE_2D,
	SCENE_3D,
	TEXTURE2D,
	VIDEOSTREAM
	} 

#var name : String
@export var name : String = ""
@export var type : Type = Type.TEXTURE2D
@export var resource : Resource = null
var thumbnail : Texture2D = null

signal thumbnail_changed

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
		"name" : name,
		"type" : type,
		"resource_path" : resource.resource_path
	}
	return data
