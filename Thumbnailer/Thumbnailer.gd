class_name Thumbnailer
extends SubViewport


static var thumbnail_res := Vector2i(160, 90)

var thumbnailer_env = preload("res://Thumbnailer/thumb_environment.tres")

func create_cache_dir():
	DirAccess.make_dir_recursive_absolute("user://cache/thumbnails")

func capture_thumbnail_of(viewable : Viewable) -> Image:
	var newChild : Node
	var thumbnail : Image
	render_target_update_mode = SubViewport.UPDATE_ONCE

	match viewable.type:
		Viewable.Type.SCENE_2D, Viewable.Type.SCENE_3D:
			newChild = viewable.resource.instantiate()
			add_child(newChild)
			await RenderingServer.frame_post_draw
			thumbnail = get_texture().get_image()
			remove_child(newChild)
			newChild.queue_free()
		Viewable.Type.TEXTURE2D:
			#we'll just be using the texture itself as the thumbnail
			pass
		Viewable.Type.VIDEOSTREAM:
			newChild = VideoStreamPlayer.new()
			newChild.stream = viewable.resource
			newChild.size = thumbnail_res
			newChild.volume = 0
			newChild.autoplay = true
			#VideoStreamPlayer must be added to scene tree to trigger autoplay i guess
			add_child(newChild)
			await RenderingServer.frame_post_draw
			thumbnail = newChild.get_video_texture().get_image()
			remove_child(newChild)
			newChild.stop()
			newChild.queue_free()
		Viewable.Type.VNC_TEXTURE:
			var placeholder_data : PackedByteArray
			placeholder_data.resize(64 * 64 * 4)
			placeholder_data.fill(Color("#DD22DDFF").to_rgba32())
			thumbnail = Image.create_from_data(64, 64, false, Image.FORMAT_RGBA8, placeholder_data)
		_:
			pass
	
	var fname = "vb_%s" % viewable.name
	var full_path = "user://cache/thumbnails/%s.webp" % fname
	var err = thumbnail.save_webp(full_path, true, 0.5)
	#if saving returns an error we wanna know
	if err != OK:
		printerr("error saving thumbnail %s : %s" % [fname, error_string(err)])
	else:
		print("saved new thumbnail at: %s" % full_path)
	return thumbnail

	
# Called when the node enters the scene tree for the first time.
func _ready():
	create_cache_dir()
	size = Thumbnailer.thumbnail_res
	own_world_3d = true
	world_3d = World3D.new()
	world_3d.environment = thumbnailer_env


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
