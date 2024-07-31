class_name PEditorServer
extends Node


static var instance : PEditorServer = null

#method to retrieve a reference to the singleton
static func ref() -> PEditorServer:
	if instance != null:
		return instance
	else:
		instance = PEditorServer.new()
		return instance

#fuck it, clients don't even need a reference to the singleton to hook it up
static func register_client(client: PEditorClient) -> void:
	ref()._register_client(client)


#static method to retrieve the thumbnailer
static func getThumbnailer() -> Thumbnailer:
	return ref().thumbnailer


#references for the various clients we will connect
var client_display :	PEditorDisplayClient		= null
var client_uv : PEditorUVClient					= null
var client_viewables : PEditorViewablesClient	= null
var client_views : PEditorViewsClient			= null

var thumbnailer := Thumbnailer.new()
var popup_rename : PopupRename

var active_face : ProjectionQuad2D = null

var selected_view : View = null
var active_view : View = null
var stashed_view : View = null

var selected_viewable : Viewable = null

func _ready():
	add_child(thumbnailer)
	get_viewport().set_embedding_subwindows(true)
	popup_rename = preload("res://ui/popup_new_name.tscn").instantiate()
	add_child(popup_rename)


func _register_client(client: PEditorClient) -> void:
	match client.type:
		"display":
			client_display = client
			print("registered display client %s" % client.name)
			client.connect("face_selected", _on_display_face_selected)	

		"uv":
			client_uv = client
			print("registered uv client %s" % client.name)
			client.connect("uv_changed", _on_uv_update)

		"viewables":
			client_viewables = client
			print("registered viewables client %s" % client.name)
			client.connect("viewable_selected", _on_viewable_selected)

		"views":
			client_views = client
			print("registered views client %s" % client.name)
			client.connect("view_activated", _on_view_activated)
			client.connect("view_selected", _on_view_selected)

		_:
			pass


func _on_display_face_selected(face : Node2D):
	#highlight the face's current view in the view queue
	#load the relevant texture into the UV editor viewport
	#set the uv vertex handle positions in the uv editor
	active_face = face
	client_views.refresh()
	print("EditorServer: active face is %s" % face.name)


func _on_uv_update(uvs : PackedVector2Array):
	pass


func _on_viewable_selected(viewable : Viewable):
	selected_viewable = viewable
	print("EditorServer: selected viewable %s" % viewable.name)


func _on_view_selected(view : View):
	selected_view = view
	print("EditorServer: selected view is %s" % view.name)


func _on_view_activated():
	#stash the view's current settings so we can revert changes easily
	stashed_view = selected_view.duplicate()
	if client_display != null:
		client_display.face_set_view(active_face, selected_view)

func _on_view_replace_viewable():
	#swap the viewable of the active view to the new one and commit the change
	active_view.set_viewable(selected_viewable)


func _on_new_view():
	#add the view parameters to the views db / collection of views on current face
	#create the thumbnail for it
	#notify the view queue ui of the change
	if active_face != null:
		popup_rename.invoke("new view for %s" % active_face.name, selected_viewable.name, confirm_new_view)

func confirm_new_view(_name : String):
	var view = View.new()
	view.rename(_name)
	view.viewable = selected_viewable

	if active_face != null:
		active_face.views[view.name] = view
		client_views.activate_view(view)
		client_views.refresh()
	

func cancel_new_view():
	pass
