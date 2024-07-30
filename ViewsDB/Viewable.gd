class_name Viewable
extends Resource

enum Type {
	SCENE_2D,
	SCENE_3D,
	TEXTURE2D,
	VIDEOSTREAM
	} 

#var viewable_name : String
@export var viewable_name : String = ""
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
			var err = image.load("user://cache/thumbnails/vb_%s.webp" % viewable_name)

			if err != OK:
				print("cache miss for viewable %s thumbnail: %s" % [viewable_name, error_string(err)])
				image = await PEditorServer.getThumbnailer().capture_thumbnail_of(self)
			else:
				print("loaded cached thumbnail for viewable %s" % viewable_name)

			thumbnail = ImageTexture.create_from_image(image)

func set_thumbnail(image : Image):
	thumbnail = ImageTexture.create_from_image(image)
	thumbnail_changed.emit(thumbnail)

func set_viewable_name(_name : String):
	if _name != viewable_name:
		viewable_name = _name
		emit_changed()
	
