class_name PEditorViewablesClient
extends PEditorClient

@onready var ui_viewables_parent = $FlowContainer
@onready var ui_new_or_replace_view = $UiNewOrReplaceView

const type = "viewables"

var view_tile_tscn = preload("res://ui/view_tile.tscn")
var viewables = preload("res://ViewsDB/ViewsDB.tres").viewables
var viewables_button_group = preload("res://ui/btn_grp_viewables.tres")

var selected_viewable : Viewable
var renaming_viewable : Viewable

signal viewable_selected

#remove and delete all children of the ui node
#then repopulate them using the data from the viewables DB
func refresh():
   for c in ui_viewables_parent.get_children():
      ui_viewables_parent.remove_child(c)
      c.queue_free()

   for v in viewables:
      await viewables[v].setThumbnail()
      add_ui_tile_from_viewable(viewables[v])


func add_ui_tile_from_viewable(viewable : Viewable):
   var i = view_tile_tscn.instantiate()
   ui_viewables_parent.add_child(i)
   i.set_from_viewable(viewable)
   i.set_button_group(viewables_button_group)
   i.button.connect("gui_input", _gui_input)


func _ready():
   #load up the existing views in the ViewsDB tres
   PEditorServer.register_client(self)
   viewables_button_group.connect("pressed", _on_scene_tile_selected)
   self.connect("viewable_selected", PEditorServer.ref()._on_viewable_selected)
   refresh()

func _on_scene_tile_selected(button : BaseButton):
   selected_viewable = button.owner.viewable
   ui_new_or_replace_view.set_label_text(selected_viewable.name)
   ui_new_or_replace_view.visible = true
   ui_new_or_replace_view.button_new.connect("pressed", PEditorServer.ref()._on_new_view)
   ui_new_or_replace_view.button_replace.connect("pressed", PEditorServer.ref()._on_view_replace_viewable)
   ui_new_or_replace_view.set_replace_valid(
	  PEditorServer.ref().active_view != null && 
	  PEditorServer.ref().active_view.viewable != selected_viewable
	  )

   viewable_selected.emit(selected_viewable)


func _on_view_selected(view : View):
   pass


func _gui_input(event):
   if event.is_action_pressed("ui_rename"):
      var rename = PEditorServer.ref().popup_rename
      renaming_viewable = selected_viewable
      rename.invoke("rename...", selected_viewable.name, selected_viewable.rename)
