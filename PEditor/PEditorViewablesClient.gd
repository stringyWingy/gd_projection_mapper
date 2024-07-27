class_name PEditorViewablesClient
extends PEditorClient

@onready var ui_viewables_parent = $"../Viewables"
var view_tile_tscn = preload("res://ui/view_tile.tscn")
var viewables = preload("res://ViewsDB/ViewsDB.tres").viewables
var viewables_button_group = preload("res://ui/btn_grp_viewables.tres")

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


func _ready():
   #load up the existing views in the ViewsDB tres
   refresh()
   viewables_button_group.connect("pressed", _on_scene_tile_selected)

func _on_scene_tile_selected(button : BaseButton):
   print("the selected viewable tile is %s" % button.owner.find_child("Label").text)
