@tool
extends MeshInstance2D

@export var start_size : Vector2

var mesh_data = []

func build_mesh() -> void:
	pass

func v3_v2(vec: Vector3) -> Vector2:
	return Vector2(vec.x,vec.y)

func calc_vert5() -> Vector3:
	var p1 = mesh_data[ArrayMesh.ARRAY_VERTEX][0]
	var p2 = mesh_data[ArrayMesh.ARRAY_VERTEX][3]
	var q1 = mesh_data[ArrayMesh.ARRAY_VERTEX][1]
	var q2 = mesh_data[ArrayMesh.ARRAY_VERTEX][2]
	return Geometry3D.get_closest_points_between_segments(p1,p2,q1,q2)[0] #the point should be the intersection if all z coords are 0


func calc_uv5():
	var p1 = mesh_data[ArrayMesh.ARRAY_TEX_UV][0]
	var p2 = mesh_data[ArrayMesh.ARRAY_TEX_UV][3]
	var q1 = mesh_data[ArrayMesh.ARRAY_TEX_UV][1]
	var q2 = mesh_data[ArrayMesh.ARRAY_TEX_UV][2]
	return Geometry2D.segment_intersects_segment(p1, p2, q1, q2); #this may return null if the segments don't intersect
	

# Called when the node enters the scene tree for the first time.
func _ready():
	mesh_data.resize(ArrayMesh.ARRAY_MAX)

	#we create a quad out of 5 vertices, 4 triangles, allowing us to cleanly sheer/tilt/whatever our 2d texture
	mesh_data[ArrayMesh.ARRAY_VERTEX] = PackedVector3Array(
			[
				Vector3(-start_size.x/2, -start_size.y/2, 0), #top left
				Vector3(start_size.x/2, -start_size.y/2, 0), #top right
				Vector3(-start_size.x/2, start_size.y/2, 0), #bot left
				Vector3(start_size.x/2, start_size.y/2, 0), #bot right
				Vector3(0, 0, 0), #center
			]
		)

	mesh_data[ArrayMesh.ARRAY_TEX_UV] = PackedVector2Array(
			[
				Vector2(0,0), #top left
				Vector2(1,0), #top right
				Vector2(0,1), #bot left
				Vector2(1,1), #bot right
				Vector2(0.5,0.5), #center
			]
		)

	mesh_data[ArrayMesh.ARRAY_INDEX] = PackedInt32Array(
			[
				4, 0, 1, #top
				4, 1, 3, #right
				4, 3, 2, #bot
				4, 2, 0, #left
			]
		)

	mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_data)

	#update handle positions in editor
	$vert_handle_0.position = Vector2(-start_size.x/2, -start_size.y/2) - $vert_handle_0.size/2 #top left
	$vert_handle_1.position = Vector2(start_size.x/2, -start_size.y/2) - $vert_handle_1.size/2 #top right
	$vert_handle_2.position = Vector2(-start_size.x/2, start_size.y/2) - $vert_handle_2.size/2 #bot left
	$vert_handle_3.position = Vector2(start_size.x/2, start_size.y/2) - $vert_handle_3.size/2 #bot right

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func on_vertex_handle_moved(index, local_position):
	mesh_data[ArrayMesh.ARRAY_VERTEX].set(index, Vector3(local_position.x, local_position.y, 0))
	
	#upate the 5th vertex
	var v5 = calc_vert5()
	mesh_data[ArrayMesh.ARRAY_VERTEX].set(4, v5)

	mesh.clear_surfaces()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_data)
