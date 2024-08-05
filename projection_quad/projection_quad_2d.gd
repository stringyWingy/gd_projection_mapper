@tool
class_name ProjectionQuad2D
extends MeshInstance2D

@export var start_size : Vector2i = Vector2i(200,200)
@export var subdivision_resolution : Vector2i = Vector2(4,4)
@export var editor_context : Node

@onready var clickable_poly2D_script = preload("res://projection_quad/clickable_poly2D.gd")
@onready var clickable_face : Polygon2D = $clickable_face
@onready var outline : Line2D = $outline
@onready var viewport : SubViewport = $SubViewport


signal face_clicked
signal vertex_handle_clicked
signal tex_data_changed

static var DEFAULT_UVS = PackedVector2Array(
	[Vector2(0,0),
	Vector2(0,1),
	Vector2(1,0),
	Vector2(0,1)])

var xverts = subdivision_resolution.x + 1
var yverts = subdivision_resolution.y + 1

var handle_uvs := PackedVector2Array() 
var handles = []

var views = {}
var active_view : View

var tex_data = {
	resolution = start_size,
	aspect = start_size.x / start_size.y,
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
	print("rebuilt uvs: %s" %uvs)


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

	if res_changed || aspect_changed:
		tex_data_changed.emit(tex_data)

func set_uvs(_uvs : PackedVector2Array):
	handle_uvs = _uvs
	needs_rebuild_uvs = true

func reset_uvs():
	if handle_uvs != ProjectionQuad2D.DEFAULT_UVS:
		handle_uvs = ProjectionQuad2D.DEFAULT_UVS
		needs_rebuild_uvs = true
	

# Called when the node enters the scene tree for the first time.
func _ready():
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
		needs_rebuild_mesh = false

	if needs_rebuild_uvs:
		rebuild_uv()
		needs_rebuild_uvs = false


func _on_face_selector_clicked(face):
	face_clicked.emit(self)

