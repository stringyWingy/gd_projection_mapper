class_name PEditorDisplayClient
extends PEditorClient

signal face_selected
signal face_created
signal face_deleted

@onready var display_world = $DisplayWorldViewport/DisplayWorld

var type = "display"

var faces = []
var selected_faces = []
var selected_vertices = []
var projection_quad_tscn = preload("res://projection_quad/projection_quad_2d.tscn")

var grabbing := false
var mouse_grab_start_pos := Vector2(0,0)
var verts_grab_start_pos := PackedVector2Array() 

var deferred_face_click := false
var deferred_face : Node2D

var deferred_vertex_handle_click := false
var deferred_vertex_handle : Node2D

const grab_fine_scale = 0.5

# Called when the node enters the scene tree for the first time.
func _ready():
	#hook this client into the editor server and let the server hook up the signals
	PEditorServer.register_client(self)
	for f in faces:
		f.set_editor_context(self)

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
			f.needs_rebuild_mesh = true

	elif deferred_vertex_handle_click:
		var handle = deferred_vertex_handle

		if Input.is_action_pressed("select_add") or selected_vertices.is_empty():
			try_select_vertex(handle)
		elif Input.is_action_pressed("select_sub"):
			deselect_vertex(handle)
		else:
			deselect_all_vertices()
			try_select_vertex(handle)

	elif deferred_face_click:
		var face = deferred_face

		if Input.is_action_pressed("select_add") or selected_faces.is_empty():
			try_select_face(face)
		elif Input.is_action_pressed("select_sub"):
			deselect_face(face)
		else:
			if try_select_face(face):
				deselect_all_faces()
				try_select_face(face)

	#if we have both deferred clicks, reset so we only handle the vertex click
	deferred_face_click = false
	deferred_vertex_handle_click = false

			

func _gui_input(event):
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
		elif event.is_action_pressed("ui_rename"):
			var f = selected_faces[0]
			PEditorServer.ref().popup_rename.invoke("rename %s" % f.name, f.name, f.rename)	

func create_projection_quad() -> void:
	var pq = projection_quad_tscn.instantiate()
	pq.rename("Quad_%s" % faces.size())
	display_world.add_child(pq)
	pq.set_editor_context(self)
	faces.append(pq)

func add_face(face: ProjectionQuad2D):
	faces.append(face)
	face.set_editor_context(self)
	display_world.add_child(face)

func clear():
	faces.clear()
	for c in display_world.get_children():
		display_world.remove_child(c)

func face_set_view(face : ProjectionQuad2D, view : View):
	face.set_view(view)
	#if view.viewable.type == Viewable.Type.TEXTURE2D:
		#face.texture = view.viewable.resource
	
	#face.active_view = view


func try_select_face(face) -> bool:
	if not selected_faces.has(face):
		selected_faces.append(face)
		face.clickable_face.highlight()
		face.outline.highlight()
		face.label.set_visible(true)
		face_selected.emit(face)
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
	face.label.set_visible(false)
	face.outline.unhighlight()
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
		f.needs_rebuild_mesh = true

	grabbing = false

func defer_face_clicked(face : Node2D) -> void:
	deferred_face_click = true
	deferred_face = face


func defer_vertex_handle_clicked(handle: Node2D) -> void:
	deferred_vertex_handle_click = true
	deferred_vertex_handle = handle



func _on_face_clicked(face : Node2D) -> void:
	defer_face_clicked(face)


func _on_vertex_handle_clicked(handle : Node2D) -> void:
	defer_vertex_handle_clicked(handle)

func _on_view_activated(face : ProjectionQuad2D, view : View):
	face_set_view(face, view)
