class_name ViewsDB
extends Resource

@export var viewables = {}
@export var views = {}

signal viewables_list_changed

func _init():
	#open the res://viewables folder and collect all the .tres files there into the viewables dict
	var dir = DirAccess.open("res://viewables")
	if dir:
		var fnames = dir.get_files()
		for f in fnames:
			var vb = load("res://viewables/%s" % f)
			viewables[vb.name] = vb
	viewables_list_changed.emit()
