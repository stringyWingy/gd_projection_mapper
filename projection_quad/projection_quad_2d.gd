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
@onready var viewport_texture := subviewport.get_texture()
@onready var label := $Label

static var DEFAULT_UVS := PackedVector2Array(
	[Vector2(0,0),
	Vector2(1,0),
	Vector2(0,1),
	Vector2(1,1)])

var xverts = subdivision_resolution.x + 1
var yverts = subdivision_resolution.y + 1

var handle_uvs := PackedVector2Array() 
var handles = []

var views = [0] #0 will be default view, eh?

var active_view : View
var video_player = VideoStreamPlayer.new()

var tex_data = {
	resolution = start_size,
	aspect = float(start_size.x) / start_size.y,
}

var mesh_data = []
var vertices := PackedVector3Array() 
var uvs := PackedVector2Array() 
var indices := PackedInt32Array() 

var needs_rebuild_mesh := false
var needs_rebuild_uvs := false

func set_editor_context(context : Node) -> void:
	editor_context = context
	face_clicked.connect(editor_context._on_face_clicked)
	for h in handles:
		h.clicked.connect(editor_context._on_vertex_handle_clicked)


func v3_v2(vec: Vector3) -> Vector2:
	return Vector2(vec.x,vec.y)
	

func v2_v3(vec: Vector2) -> Vector3:
	return Vector3(vec.x,vec.y,0)


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
	vertices.clear()
	indices.clear()

	xverts = subdivision_resolution.x + 1
	yverts = subdivision_resolution.y + 1

	#create grid of vertices
	for j in yverts:
		for i in xverts:
			#helpful to have normalized cords progressing along the mesh's limits
			var frac = Vector2i(i,j) / subdivision_resolution

			#init uvs as full 0-1
			var uv = Vector2(frac.x,frac.y)

			var pos2 = (start_size * frac) - (start_size / 2)
			var pos = v2_v3(pos2)

			uvs.append(uv)
			vertices.append(pos)
	#end creating vertices

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
	mesh_data[ArrayMesh.ARRAY_INDEX] =  indices
	mesh.clear_surfaces()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_data)
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
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_data)
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



func rebuild_uv() -> void:
	uvs.clear()

	for j : float in yverts:
		for i : float in xverts:
			#get positions along the 'top' and 'bottom' edges (in uv space) based on the x index coordinate of this vertex
			var p1 = handle_uvs[0].lerp(handle_uvs[1], i/subdivision_resolution.x)
			var p2 = handle_uvs[2].lerp(handle_uvs[3], i/subdivision_resolution.x)

			#lerp between those two positions to create a y axis in handle space
			var p = p1.lerp(p2, j/subdivision_resolution.y)
			uvs.append(p)

	mesh.clear_surfaces()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_data)


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


func set_uvs(_uvs : PackedVector2Array):
	if handle_uvs != _uvs:
		handle_uvs = _uvs
		needs_rebuild_uvs = true


func reset_uvs():
	if handle_uvs != ProjectionQuad2D.DEFAULT_UVS:
		handle_uvs = ProjectionQuad2D.DEFAULT_UVS
		needs_rebuild_uvs = true
	

func auto_uv():
	#get the resolution and aspect of the quad
	#set new resolution for its subviewport
	#get resolution data of the texture of its active view??
	#set its uvs so as to "center / cover"
	var viewable = active_view.viewable

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
				set_uvs(_uvs)

			elif q_aspect > t_aspect:
				var uv_height : float = t_aspect / q_aspect
				var _uvs = PackedVector2Array([
					Vector2(0, 0.5 - uv_height/2),
					Vector2(1, 0.5 - uv_height/2),
					Vector2(0, 0.5 + uv_height/2),
					Vector2(1, 0.5 + uv_height/2)])
				set_uvs(_uvs)

			else:
				reset_uvs()

		#if the face's texture is being rendered from a camera/subviewport
		#the uvs should cover the full rectangle
		Viewable.Type.SCENE_2D, Viewable.Type.SCENE_3D:
			reset_uvs()

		Viewable.Type.VIDEOSTREAM:
			#the videoplayer should fill the subviewport?
			reset_uvs()

		_:
			pass


func set_view(view : View):
	if active_view == view: return

	#case-by-case cleanup of previous view
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

	match view.viewable.type:
		Viewable.Type.TEXTURE2D:
			texture = view.viewable.resource

		Viewable.Type.SCENE_2D, Viewable.Type.SCENE_3D:
			texture = viewport_texture
			subviewport.add_child(view.viewable.resource.instantiate())

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

	
# Called when the node enters the scene tree for the first time.
func _ready():
	label.text = name

	set_view(View.get_default_view())
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


func _on_face_selector_clicked(face):
	face_clicked.emit(self)


#no harm in listening to our own events yeah?
func _on_tex_data_changed(tex_data):
	subviewport.set_size(tex_data.resolution)
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
	quad.set_view.call_deferred(PEditorServer.getViewsDB().get_view(data.active_view))

	#need to defer this call so the quad can initialize its handles first
	var handle_positions = bytes_to_var(PackedByteArray(data.handle_positions))
	var set_quad_handles = func(positions):
		for i in 4:
			quad.handles[i].position = positions[i]
	set_quad_handles.call_deferred(handle_positions)

	quad.needs_rebuild_mesh = true
	return quad
