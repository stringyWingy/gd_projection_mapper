class_name PEditorViewsClient
extends PEditorClient

signal view_selected
signal view_deleted
signal view_activated

@onready var ui_views_parent = $ViewsList

const type = "views"

var view_tile_tscn = preload("res://ui/view_tile.tscn")
var views_button_group = preload("res://ui/btn_grp_views.tres")

var selected_face : ProjectionQuad2D
var views
var selected_view : View
var renaming_view : View

func refresh():
  #clear the ui
  for c in ui_views_parent.get_children():
    ui_views_parent.remove_child(c)
    c.queue_free()

  #figure out whose views we need to list
  selected_face = PEditorServer.ref().active_face
  views = selected_face.views

  for v in views:
    add_ui_tile_from_view(PEditorServer.getViewsDB().get_view(v))
	

func add_ui_tile_from_view(view : View):
   var i = view_tile_tscn.instantiate()
   ui_views_parent.add_child(i)
   i.set_from_view(view)
   i.set_button_group(views_button_group)
   i.button.connect("gui_input", _gui_input)


func activate_view(view):
  pass
  #set the texture and uv of the projection quad


func _ready():
   PEditorServer.register_client(self)
   views_button_group.connect("pressed", _on_view_tile_selected)
   self.connect("view_selected", PEditorServer.ref()._on_view_selected)
   self.connect("view_activated", PEditorServer.ref()._on_view_activated)


func _on_view_tile_selected(button : BaseButton):
  selected_view= button.owner.view
  view_selected.emit(selected_view)


func _on_activate_selected():
  activate_view(selected_view)
  view_activated.emit(selected_view)

func _on_face_selected(face : ProjectionQuad2D):
  views = face.views 


func _on_view_list_changed():
  refresh()


func _gui_input(event):
  if event.is_action_pressed("ui_rename"):
    var rename = PEditorServer.ref().popup_rename
    renaming_view = selected_view
    rename.invoke("rename...", renaming_view.name, renaming_view.rename)
  elif event.is_action_pressed("view_activate"):
    view_activated.emit()
