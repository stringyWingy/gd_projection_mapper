@tool

class_name ProjectionQuad2D
extends MeshInstance2D

signal face_clicked
signal vertex_handle_clicked
signal tex_data_changed

@export var start_size : Vector2i = Vector2i(200,200)
@export var subdivision_resolution : Vector2i = Vector2(4,4)
@export var editor_context : PEditorClient

@onready var clickable_poly2D_script = preload("res://projection_quad/clickable_poly2D.gd")
@onready var clickable_face : Polygon2D = $clickable_face
@onready var outline : Line2D = $outline
@onready var subviewport : SubViewport = $SubViewport
@onready var transition_viewport : SubViewport = %TransitionViewport
@onready var label := $Label
@onready var anim_player = %AnimationPlayer

static var DEFAULT_UVS := PackedVector2Array(
	[Vector2(0,0),
	Vector2(1,0),
	Vector2(0,1),
	Vector2(1,1)])

var xverts = subdivision_resolution.x + 1
var yverts = subdivision_resolution.y + 1

var handle_uvs := PackedVector2Array(DEFAULT_UVS) 
var handle_uvs_2 := PackedVector2Array(DEFAULT_UVS) 
var handles = []

var views = [0] #0 will be default view, eh?

var active_view : View
var active_view_instance : Node
var video_player = VideoStreamPlayer.new()

var transition_view : View
var transition_view_instance : Node
var transition_video_player = VideoStreamPlayer.new()

var tex_data = {
	resolution = start_size,
	aspect = float(start_size.x) / start_size.y,
}

var mesh_data = []
var vertices := PackedVector3Array() 
var uvs := PackedVector2Array() 
var uvs2 := PackedColorArray()
var indices := PackedInt32Array() 
var arraymesh_flags = Mesh.ARRAY_CUSTOM_RG_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT

var needs_rebuild_mesh := false
var needs_rebuild_uvs := false
var needs_rebuild_uvs_2 := false

func set_editor_context(context : Node) -> void:
	editor_context = context
	face_clicked.connect(editor_context._on_face_clicked)
	for h in handles:
		h.clicked.connect(editor_context._on_vertex_handle_clicked)


#main thing to be called from outside, will transition by default
func set_view(view: View):
	set_view_transition(view)


func set_texture2(texture2: Texture2D) -> void:
	material.set_shader_parameter("texture2", texture2)


func get_texture2() -> Texture2D:
	return material.get_shader_parameter("texture2")


func set_mix_alpha(alpha: float):
	material.set_shader_parameter("mix_alpha", alpha)


func finish_transition():
	set_mix_alpha(0)

	#overwrite the texture and uvs with those from the transition
	texture = get_texture2()
	handle_uvs = PackedVector2Array(handle_uvs_2)

	var i = 0
	for uv in uvs:
		uv.x = uvs2[i].r
		uv.y = uvs2[i].g
		i += 1

	#swap the video players since we'll probably need separate references still
	var video_temp = transition_video_player
	transition_video_player = video_player
	video_player = video_temp

	#switcheroo the viewports
	#we've already swapped around texture references so this should be...fine?
	var subv_temp = transition_viewport
	transition_viewport = subviewport
	subviewport = subv_temp
	transition_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED


	active_view = transition_view
	active_view_instance = transition_view_instance

	
func v3_v2(vec: Vector3) -> Vector2:
	return Vector2(vec.x,vec.y)
	

func v2_v3(vec: Vector2) -> Vector3:
	return Vector3(vec.x,vec.y,0)


func v2_color(vec: Vector2) -> Color:
	return Color(vec.x, vec.y, 0, 0)

func colors_to_mesh_custom_buffer(colors: PackedColorArray) -> PackedFloat32Array:
	var out = PackedFloat32Array()
	var stride = 2
	out.resize(colors.size() * stride)

	for c in colors.size():
		#var c_int32 = colors[c].to_abgr32()
		var idx = c * stride 
		out[idx + 0] = colors[c].r
		out[idx + 1] = colors[c].g
		#out[idx + 0] = c_int32
		#out[idx + 1] = c_int32 >> 8
		#out[idx + 2] = c_int32 >> 16
		#out[idx + 3] = c_int32 >> 24

	print("converted colors:")
	print(colors)
	print("to rgba8's:")
	print(out)
	return out


func init_handles() -> void:
	for c in find_children("handle_*"):
		remove_child(c)
		c.set_owner(null)

	for i in range(4):
		var nname = "handle_%s" % i
		var h = Polygon2D.new()
		h.set_script(clickable_poly2D_script)
		h.name = nname
		add_child(h)
		handles.append(h)
		h.set_owner(self)
		h.color_highlight = Color("#ffff69")
		h.color_normal = Color("#8f8f8f")
		h.behavior = h.Behavior.COLORTOGGLE
		h.set_visibility_layer(2)
		h.z_index = 69
		h.set_polygon(
			PackedVector2Array([
				Vector2(-8,-8),
				Vector2(8,-8),
				Vector2(8,8),
				Vector2(-8,8)
			])
		)

	handles[0].position = Vector2(-start_size.x/2, -start_size.y/2) #top left
	handles[1].position = Vector2(start_size.x/2, -start_size.y/2) #top right
	handles[2].position = Vector2(-start_size.x/2, start_size.y/2) #bot left
	handles[3].position = Vector2(start_size.x/2, start_size.y/2) #bot right


func init_outline() -> void:
	outline.color_highlight = Color("#ffff69")
	outline.color_normal = Color("#8f8f8f")
	outline.closed = true
	outline.set_points([
		handles[0].position,
		handles[1].position,
		handles[3].position,
		handles[2].position
	])


func init_video_player() -> void:
	video_player.set_volume(0)
	video_player.set_autoplay(true)
	video_player.set_loop(true)


func init_mesh() -> void:
	uvs.clear()
	uvs2.clear()
	vertices.clear()
	indices.clear()

	xverts = subdivision_resolution.x + 1
	yverts = subdivision_resolution.y + 1

	#create grid of vertices
	for j in yverts:
		for i in xverts:
			#helpful to have normalized cords progressing along the mesh's limits
			var frac = Vector2(i,j) / Vector2(subdivision_resolution)

			#init uvs as full 0-1
			var uv = Vector2(frac.x,frac.y)

			var pos2 = (Vector2(start_size) * frac) - (Vector2(start_size) / 2)
			var pos = v2_v3(pos2)

			uvs.append(uv)
			uvs2.append(v2_color(uv))
			vertices.append(pos)
	#end creating vertices
	print("initialized uvs [0]")
	print(uvs)
	print("initialized uvs [1]")
	print(uvs2)

	#order up triangles
	#strategy: go one quad at a time
	#  0  1
	#  2  3
	#  for each subdiv quad, crate triangles [0, 1, 2] and [1,3,2]

	for j in subdivision_resolution.y:
		for i in subdivision_resolution.x:
			var v0 = j * xverts + i
			var v1 = v0 + 1
			var v2 = (j + 1) * xverts + i
			var v3 = v2 + 1

			var quad = PackedInt32Array([
				v0, v1, v2, #top tri
				v1, v3, v2 #bot tri
				])

			indices.append_array(quad)
	#end ordering triangles

	#slap all this data into the surface
	mesh_data[ArrayMesh.ARRAY_VERTEX] = vertices
	mesh_data[ArrayMesh.ARRAY_TEX_UV] = uvs
	mesh_data[ArrayMesh.ARRAY_CUSTOM0] = colors_to_mesh_custom_buffer(uvs2)
	mesh_data[ArrayMesh.ARRAY_INDEX] =  indices
	mesh.clear_surfaces()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_data,[],{},arraymesh_flags)
	refresh_tex_data()
	#force refresh tex data on first construction
	tex_data_changed.emit(tex_data)
	

func rebuild_selector_polygon() -> void:
	clickable_face.set_polygon([
		handles[0].position,
		handles[1].position,
		handles[3].position,
		handles[2].position
	])
	outline.set_points([
		handles[0].position,
		handles[1].position,
		handles[3].position,
		handles[2].position
	])


func rebuild_positions() -> void:

	vertices.clear()

	for j : float in yverts:
		for i : float in xverts:
			#get positions along the 'top' and 'bottom' edges (in handle space) based on the x index coordinate of this vertex
			var p1 = handles[0].position.lerp(handles[1].position, i/subdivision_resolution.x)
			var p2 = handles[2].position.lerp(handles[3].position, i/subdivision_resolution.x)

			#lerp between those two positions to create a y axis in handle space
			var p = p1.lerp(p2, j/subdivision_resolution.y)
			vertices.append(v2_v3(p))

	mesh.clear_surfaces()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_data,[],{},arraymesh_flags)
	refresh_tex_data()


func rename(_name : String) -> void:
	call_deferred("rename_internal", _name)


func rename_internal(_name: String) -> void:
	name = _name
	label.text = _name


func refresh_label_position():
	#set the label in the midpoint of all the vertices
	var intersection = Geometry2D.segment_intersects_segment(handles[0].position, handles[3].position, handles[1].position, handles[2].position)
	if intersection: label.position = intersection


func rebuild_uv(channel: int = 0) -> void:
	var handle_uv_channel = handle_uvs if !channel else handle_uvs_2
	var uv_mesh_data = uvs if !channel else uvs2
	uv_mesh_data.clear()

	for j : float in yverts:
		for i : float in xverts:
			#get positions along the 'top' and 'bottom' edges (in uv space) based on the x index coordinate of this vertex
			var p1 = handle_uv_channel[0].lerp(handle_uv_channel[1], i/subdivision_resolution.x)
			var p2 = handle_uv_channel[2].lerp(handle_uv_channel[3], i/subdivision_resolution.x)

			#lerp between those two positions to create a y axis in handle space
			var p = p1.lerp(p2, j/subdivision_resolution.y)
			if channel:
				uvs2.append(v2_color(p))
			else:
				uvs.append(p)

	mesh.clear_surfaces()
	if channel:
		mesh_data[ArrayMesh.ARRAY_CUSTOM0] = colors_to_mesh_custom_buffer(uvs2)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_data,[],{},arraymesh_flags)


func refresh_tex_data():
	var mid_y1 = handles[0].position.lerp(handles[1].position, 0.5)
	var mid_y2 = handles[2].position.lerp(handles[3].position, 0.5)

	var height = mid_y1.distance_to(mid_y2)
	
	var mid_x1 = handles[0].position.lerp(handles[2].position, 0.5)
	var mid_x2 = handles[1].position.lerp(handles[3].position, 0.5)

	var width = mid_x1.distance_to(mid_x2)

	var res_changed : bool = (width != tex_data.resolution.x || height != tex_data.resolution.y)
	var aspect_changed : bool = width/height != tex_data.aspect

	tex_data.resolution = Vector2i(width, height)
	tex_data.aspect = width/height

	#resize the subviewport

	if res_changed || aspect_changed:
		tex_data_changed.emit(tex_data)


func set_uvs(_uvs : PackedVector2Array, channel: int = 0):
	var uv_channel = handle_uvs if !channel else handle_uvs_2
	if uv_channel != _uvs:
		uv_channel = _uvs
		match channel:
			0:
				needs_rebuild_uvs = true
			1:
				needs_rebuild_uvs_2 = true
			_:
				pass


func reset_uvs(channel: int = 0):
	var uv_channel = handle_uvs if !channel else handle_uvs_2
	if uv_channel != ProjectionQuad2D.DEFAULT_UVS:
		uv_channel = ProjectionQuad2D.DEFAULT_UVS
		match channel:
			0:
				needs_rebuild_uvs = true
			1:
				needs_rebuild_uvs_2 = true
			_:
				pass
	

#by default, will map uvs so that textures of mismatched dimensions
#(video streams or raw texture viewables) will "cover" the surface while preserving aspect ration
#optionally, provide a different viewable, or assign the resulting uvs to the secondary uv attribute in the mesh instead
func auto_uv(viewable: Viewable = active_view.viewable, channel: int = 0):
	#get the resolution and aspect of the quad
	#set new resolution for its subviewport
	#get resolution data of the texture of its active view??
	#set its uvs so as to "center / cover"

	match viewable.type:
		Viewable.Type.TEXTURE2D:
			var tex = viewable.resource
			var t_aspect = tex.get_width() / tex.get_height()
			var q_aspect = tex_data.aspect
			
			if t_aspect > q_aspect:
				var uv_width = q_aspect / t_aspect
				var _uvs = PackedVector2Array([
					Vector2(0.5 - uv_width/2, 0),
					Vector2(0.5 + uv_width/2, 0),
					Vector2(0.5 - uv_width/2, 1),
					Vector2(0.5 + uv_width/2, 1)])
				set_uvs(_uvs, channel)

			elif q_aspect > t_aspect:
				var uv_height : float = t_aspect / q_aspect
				var _uvs = PackedVector2Array([
					Vector2(0, 0.5 - uv_height/2),
					Vector2(1, 0.5 - uv_height/2),
					Vector2(0, 0.5 + uv_height/2),
					Vector2(1, 0.5 + uv_height/2)])
				set_uvs(_uvs, channel)

			else:
				reset_uvs(channel)

		#if the face's texture is being rendered from a camera/subviewport
		#the uvs should cover the full rectangle
		Viewable.Type.SCENE_2D, Viewable.Type.SCENE_3D:
			reset_uvs(channel)

		Viewable.Type.VIDEOSTREAM:
			#the videoplayer should fill the subviewport?
			reset_uvs(channel)

		_:
			pass


func set_view_immediate(view : View):
	if active_view == view && active_view.camera_idx == view.camera_idx : return


	#check if all we have to do is swap cameras on the current view
	if active_view == view && active_view.camera_idx != view.camera_idx : 
		set_view_camera()
		return


	#cleanup
	if active_view:
		match active_view.viewable.type:
			Viewable.Type.SCENE_2D, Viewable.Type.SCENE_3D:
				#clear the subviewports children
				for c in subviewport.get_children():
					subviewport.remove_child(c)
					c.queue_free()

			Viewable.Type.VIDEOSTREAM:
				#remove the videoplayer but don't free it from memory
				video_player.stop()
				subviewport.remove_child(video_player)
				
			Viewable.Type.VNC_TEXTURE:
				#stop getting updates from the server i guess
				active_view.viewable.resource.end()

			_:
				pass

	active_view = view

	#new view
	#TODO: check if the view has already been instanced for another viewport, and copy that world
	match view.viewable.type:
		Viewable.Type.TEXTURE2D:
			texture = view.viewable.resource

		Viewable.Type.SCENE_2D, Viewable.Type.SCENE_3D:
			texture = subviewport.get_texture()
			var scn = view.viewable.resource.instantiate()
			active_view_instance = scn
			if view.camera_idx > 0:
				set_view_camera()
			subviewport.add_child(scn)

		Viewable.Type.VIDEOSTREAM:
			video_player.set_stream(view.viewable.resource)
			video_player.set_size(tex_data.resolution)
			subviewport.add_child(video_player)
			texture = video_player.get_video_texture()
			video_player.play()

		Viewable.Type.VNC_TEXTURE:
			#it will take a sec for the texture to be usable (and have non-zero dimensions)
			texture = PlaceholderTexture2D.new()
			texture.set_size(Vector2(64,64))

			var vnc = view.viewable.resource

			var ready_callback = func():
				texture = vnc
				print("vnc ready, swapping out placeholder texture")
				if view.auto_uv:
					auto_uv()


			#try to connect to the server
			vnc.begin(vnc.host, vnc.password)

			#vnc_texture will emit this signal when it's initialized
			vnc.connect("texture_ready", ready_callback, CONNECT_ONE_SHOT)

		_:
			pass
	
	#then auto-uv-ify after updating the teture etc
	if view.auto_uv:
		auto_uv()


#TODO: add option to customise transition material
func set_view_transition(view : View):
	if active_view == view && active_view.camera_idx == view.camera_idx : return


	#cleanup
	if transition_view:
		match transition_view.viewable.type:
			Viewable.Type.SCENE_2D, Viewable.Type.SCENE_3D:
				#clear the subviewports children
				for c in transition_viewport.get_children():
					transition_viewport.remove_child(c)
					c.queue_free()

			Viewable.Type.VIDEOSTREAM:
				#remove the videoplayer but don't free it from memory
				transition_video_player.stop()
				transition_viewport.remove_child(transition_video_player)
				
			Viewable.Type.VNC_TEXTURE:
				#stop getting updates from the server i guess
				transition_view.viewable.resource.end()

			_:
				pass

	transition_view = view

	#new view
	#TODO: check if the view has already been instanced for another viewport, and copy that world
	match view.viewable.type:
		Viewable.Type.TEXTURE2D:
			set_texture2(view.viewable.resource)

		Viewable.Type.SCENE_2D, Viewable.Type.SCENE_3D:
			set_texture2(transition_viewport.get_texture())
			var scn = view.viewable.resource.instantiate()
			transition_view_instance = scn
			if transition_view.camera_idx > 0:
				set_view_camera_transition()
			transition_viewport.add_child(scn)
			transition_viewport.set_update_mode(SubViewport.UPDATE_ALWAYS)

		Viewable.Type.VIDEOSTREAM:
			transition_video_player.set_stream(view.viewable.resource)
			transition_video_player.set_size(tex_data.resolution)
			transition_viewport.add_child(transition_video_player)
			set_texture2(transition_video_player.get_video_texture())
			transition_video_player.play()

		Viewable.Type.VNC_TEXTURE:
			#it will take a sec for the texture to be usable (and have non-zero dimensions)
			var placeholder = PlaceholderTexture2D.new() 
			placeholder.set_size(Vector2(64,64))
			set_texture2(placeholder)

			var vnc = view.viewable.resource

			var ready_callback = func():
				set_texture2(vnc)
				print("vnc ready, swapping out placeholder texture")
				if view.auto_uv:
					auto_uv(transition_view.viewable, 1)


			#try to connect to the server
			vnc.begin(vnc.host, vnc.password)

			#vnc_texture will emit this signal when it's initialized
			vnc.connect("texture_ready", ready_callback, CONNECT_ONE_SHOT)

		_:
			pass
	
	#then auto-uv-ify after updating the teture etc
	if transition_view.auto_uv:
		auto_uv(transition_view.viewable, 1)

	#start the animation player babyee
	#the anim will automatically call finish_transition
	anim_player.stop()
	anim_player.play("basic_fade")


func set_view_camera()->void:
	var camera_path = active_view.viewable.cameras[active_view.camera_idx].path
	active_view_instance.get_node(camera_path).make_current()

func set_view_camera_transition()->void:
	var camera_path = transition_view.viewable.cameras[transition_view.camera_idx].path
	transition_view_instance.get_node(camera_path).make_current()
	
# Called when the node enters the scene tree for the first time.
func _ready():
	label.text = name

	set_view_immediate(View.get_default_view())
	tex_data_changed.connect(_on_tex_data_changed)

	init_video_player()

	init_handles()
	init_outline()
	for h in handles:
		h.set_visible(false)
		h.set_clickable(false)
	rebuild_selector_polygon()
	if editor_context != null:
		set_editor_context(editor_context)

	mesh = ArrayMesh.new()
	mesh_data.resize(ArrayMesh.ARRAY_MAX)
	init_mesh()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if needs_rebuild_mesh:
		rebuild_positions()
		rebuild_selector_polygon()
		refresh_label_position()
		needs_rebuild_mesh = false

	if active_view.viewable.type == Viewable.Type.VNC_TEXTURE:
		active_view.viewable.resource.refresh(delta)

	if needs_rebuild_uvs:
		rebuild_uv()
		needs_rebuild_uvs = false

	if needs_rebuild_uvs_2:
		rebuild_uv(1)
		needs_rebuild_uvs_2 = false


func _on_face_selector_clicked(face):
	face_clicked.emit(self)


#no harm in listening to our own events yeah?
func _on_tex_data_changed(tex_data):
	subviewport.set_size(tex_data.resolution)
	transition_viewport.set_size(tex_data.resolution)
	var vp = subviewport.find_child("video_player")
	if vp:
		vp.set_size(tex_data.resolution)

	if active_view.auto_uv:
		auto_uv()


func get_save_data():
	var handle_positions = PackedVector2Array()
	for h in handles:
		handle_positions.append(h.position)
		

	var data = {
		"name" : name,
		"position" : Array(var_to_bytes(position)),
		"handle_positions" : Array(var_to_bytes(handle_positions)),
		"views" : views,
		"active_view" : active_view.id,
	}
	return data

static func from_save_data(data) -> ProjectionQuad2D:
	var quad = preload("res://projection_quad/projection_quad_2d.tscn").instantiate()
	quad.rename(data.name)
	quad.position = bytes_to_var(PackedByteArray(data.position))
	quad.views = data.views
	quad.set_view_immediate.call_deferred(PEditorServer.getViewsDB().get_view(data.active_view))

	#need to defer this call so the quad can initialize its handles first
	var handle_positions = bytes_to_var(PackedByteArray(data.handle_positions))
	var set_quad_handles = func(positions):
		for i in 4:
			quad.handles[i].position = positions[i]
	set_quad_handles.call_deferred(handle_positions)

	quad.needs_rebuild_mesh = true
	return quad
