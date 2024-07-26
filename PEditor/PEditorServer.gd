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
static func registerClient(client: PEditorClient) -> void:
	ref()._registerClient(client)

#static method to retrieve the thumbnailer
static func getThumbnailer() -> Thumbnailer:
	return ref().thumbnailer

#references for the various clients we will connect
var displayClient :	PEditorDisplayClient		= null
var uvClient : PEditorUVClient					= null
var viewablesClient : PEditorViewablesClient	= null
var viewsClient : PEditorViewsClient			= null

var thumbnailer := Thumbnailer.new()

var active_face : Node2D

func _ready():
	add_child(thumbnailer)

func _registerClient(client: PEditorClient) -> void:
	match client.type:
		"display":
			displayClient = client
			client.connect("face_selected", _on_display_face_selected)	

		"uv":
			uvClient = client
			client.connect("uv_changed", _on_uv_update)

		"viewables":
			viewablesClient = client
			client.connect("viewable_selected", _on_viewable_selected)

		"views":
			viewsClient = client
			client.connect("view_activated", _on_view_activated)

		_:
			pass


func _on_display_face_selected(face : Node2D):
	#highlight the face's current view in the view queue
	#load the relevant texture into the UV editor viewport
	#set the uv vertex handle positions in the uv editor
	active_face = face
	print("EditorServer: active face is %s" % face.name)


func _on_uv_update(uvs : PackedVector2Array):
	pass


func _on_viewable_selected(viewable : Viewable):
	#swap the selected viewable into the current view
	#notify the view queue ui and the current face
	pass


func _on_view_activated(view : View):
	#stash the view's current settings so we can revert changes easily
	pass


func _on_queue_view_add(view : View):
	#add the view parameters to the views db / collection of views on current face
	#create the thumbnail for it
	#notify the view queue ui of the change
	pass
