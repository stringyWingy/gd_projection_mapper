extends Node

@onready var display_world = get_parent()

@onready var faces = [
	$"../DemoQuad1",
	$"../DemoQuad2"
]
var selected_faces = []
var selected_vertices = []
var projection_quad_tscn = preload("res://projection_quad_2d.tscn")

var grabbing := false
var mouse_grab_start_pos := Vector2(0,0)
var verts_grab_start_pos := PackedVector2Array() 

const grab_fine_scale = 0.5

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if grabbing:
		var grab_vec = display_world.get_local_mouse_position() - mouse_grab_start_pos
		if Input.is_action_pressed("grab_fine"):
			grab_vec *= grab_fine_scale
		var i = 0
		for v in selected_vertices:
			v.position = verts_grab_start_pos[i] + grab_vec
			i += 1

		for f in selected_faces:
			f.needs_rebuild = true
			

func _input(event):
	if event.is_action_pressed("grab"):
		begin_grab()
	elif event.is_action_pressed("left_click"):
		if grabbing:
			commit_grab()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("right_click") or event.is_action_pressed("ui_cancel"):
		if grabbing:
			cancel_grab()
			get_viewport().set_input_as_handled()

	if not grabbing:
		if event.is_action_pressed("select_all"):
			for f in faces:
				try_select_face(f)
		elif event.is_action_pressed("select_none"):
			for f in faces:
				deselect_face(f)
		elif event.is_action_pressed("new_quad"):
			create_projection_quad()
		elif event.is_action_pressed("delete_quad"):
			for f in selected_faces:
				faces.erase(f)
				display_world.remove_child(f)

func create_projection_quad() -> void:
	var pq = projection_quad_tscn.instantiate()
	display_world.add_child(pq)
	pq.set_editor_context(self)
	faces.append(pq)


func try_select_face(face) -> bool:
	if not selected_faces.has(face):
		selected_faces.append(face)
		face.clickable_face.highlight()
		for v in face.handles:
			try_select_vertex(v)
			v.set_clickable(true)
			v.set_visible(true)
		return true
	else: return false


func try_select_vertex(vertex) -> bool:
	if not selected_vertices.has(vertex):
		selected_vertices.append(vertex)
		vertex.highlight()
		vertex.set_process_priority(-333)
		return true
	else: return false


func deselect_face(face) -> void:
	selected_faces.erase(face)
	face.clickable_face.unhighlight()
	for h in face.handles:
		deselect_vertex(h)
		h.set_clickable(false)
		h.set_visible(false)


func deselect_vertex(vertex) -> void:
	selected_vertices.erase(vertex)
	vertex.unhighlight()
	vertex.set_process_priority(0)


func deselect_all_faces() -> void:
	for f in selected_faces:
		deselect_face(f)


func deselect_all_vertices() -> void:
	for f in selected_faces:
		for h in f.handles:
			deselect_vertex(h)

func begin_grab() -> void:
	mouse_grab_start_pos = display_world.get_local_mouse_position()

	verts_grab_start_pos.clear()
	for v in selected_vertices:
		verts_grab_start_pos.append(v.position)

	grabbing = true

func commit_grab() -> void:
	grabbing = false

func cancel_grab() -> void:
	var i = 0
	
	for v in selected_vertices:
		v.position = verts_grab_start_pos[i]
		i += 1

	for f in selected_faces:
		f.needs_rebuild = true

	grabbing = false

#TODO: try deferring these signal responses so we can prioritize an active vertex click over an unselected face click
func _on_face_clicked(face : Node2D) -> void:
	if grabbing: return
	if Input.is_action_pressed("select_add") or selected_faces.is_empty():
		try_select_face(face)
	elif Input.is_action_pressed("select_sub"):
		deselect_face(face)
	else:
		if try_select_face(face):
			deselect_all_faces()
			try_select_face(face)

func _on_vertex_handle_clicked(handle : Node2D) -> void:
	if grabbing: return
	if Input.is_action_pressed("select_add") or selected_vertices.is_empty():
		try_select_vertex(handle)
	elif Input.is_action_pressed("select_sub"):
		deselect_vertex(handle)
	else:
		deselect_all_vertices()
		try_select_vertex(handle)
