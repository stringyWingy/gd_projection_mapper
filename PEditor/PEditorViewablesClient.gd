class_name PEditorViewablesClient
extends PEditorClient

@onready var ui_viewables_parent = $"../Viewables"
var scene_tile_tscn = preload("res://ui/scene_item.tscn")
var viewables = preload("res://ViewsDB/ViewsDB.tres").viewables

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
   var i = scene_tile_tscn.instantiate()
   ui_viewables_parent.add_child(i)
   i.setFromViewable(viewable)


func _ready():
   #load up the existing views in the ViewsDB tres
   refresh()
