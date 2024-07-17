@tool
extends MeshInstance2D

@export var start_size : Vector2 = Vector2(200,200)
@export var subdivision_resolution : Vector2 = Vector2(4,4)

@onready var face_selector : Polygon2D = $face_selector

signal face_clicked

var xverts = subdivision_resolution.x + 1
var yverts = subdivision_resolution.y + 1

var mesh_data = []
var handles = []

var vertices = PackedVector3Array() 
var uvs = PackedVector2Array() 
var indices = PackedInt32Array() 

var needs_rebuild := false

var editor_context = null

func set_editor_context(context : Node) -> void:
	editor_context = context


func v3_v2(vec: Vector3) -> Vector2:
	return Vector2(vec.x,vec.y)
	

func v2_v3(vec: Vector2) -> Vector3:
	return Vector3(vec.x,vec.y,0)


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
			var frac = Vector2(i,j) / subdivision_resolution

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
	
func rebuild_selector_polygon() -> void:
	face_selector.set_polygon([
		handles[0],
		handles[1],
		handles[3],
		handles[2]
	])

func rebuild_positions() -> void:

	vertices.clear()

	for j in yverts:
		for i in xverts:
			#get positions along the 'top' and 'bottom' edges (in handle space) based on the x index coordinate of this vertex
			var p1 = handles[0].lerp(handles[1], i/subdivision_resolution.x)
			var p2 = handles[2].lerp(handles[3], i/subdivision_resolution.x)

			#lerp between those two positions to create a y axis in handle space
			var p = p1.lerp(p2, j/subdivision_resolution.y)
			vertices.append(v2_v3(p))

	mesh.clear_surfaces()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_data)

func rebuild_uv() -> void:
	uvs.clear()
	var corners = []
	corners[0] = uvs[0]
	corners[1] = uvs[subdivision_resolution.x]
	corners[2] = uvs[xverts * subdivision_resolution.y]
	corners[3] = uvs[xverts * subdivision_resolution.y + subdivision_resolution.x]

	for j in yverts:
		for i in xverts:
			#get positions along the 'top' and 'bottom' edges (in handle space) based on the x index coordinate of this vertex
			var p1 = corners[0].lerp(corners[1], i/subdivision_resolution.x)
			var p2 = corners[2].lerp(corners[3], i/subdivision_resolution.x)

			#lerp between those two positions to create a y axis in handle space
			var p = p1.lerp(p2, j/subdivision_resolution.y)
			uvs.append(p)

	mesh.clear_surfaces()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_data)

# Called when the node enters the scene tree for the first time.
func _ready():
	#update handle positions in editor
	$vert_handle_0.position = Vector2(-start_size.x/2, -start_size.y/2) - $vert_handle_0.size/2 #top left
	$vert_handle_1.position = Vector2(start_size.x/2, -start_size.y/2) - $vert_handle_1.size/2 #top right
	$vert_handle_2.position = Vector2(-start_size.x/2, start_size.y/2) - $vert_handle_2.size/2 #bot left
	$vert_handle_3.position = Vector2(start_size.x/2, start_size.y/2) - $vert_handle_3.size/2 #bot right

	handles = [
		$vert_handle_0.position + $vert_handle_0.size/2,
		$vert_handle_1.position + $vert_handle_1.size/2,
		$vert_handle_2.position + $vert_handle_2.size/2,
		$vert_handle_3.position + $vert_handle_3.size/2
	]

	mesh = ArrayMesh.new()
	mesh_data.resize(ArrayMesh.ARRAY_MAX)
	init_mesh()
	rebuild_selector_polygon()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if needs_rebuild:
		rebuild_positions()
		rebuild_selector_polygon()
		needs_rebuild = false


func on_vertex_handle_moved(index, local_position):
	handles[index] = local_position
	needs_rebuild = true


func _on_face_selector_clicked():
	face_clicked.emit()
	
