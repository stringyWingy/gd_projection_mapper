class_name ViewsDB
extends Resource

const gather_from_path = "res://content"
var viewables = {}

var views = {
	0 : View.get_default_view()	
}

var views_id_index : int = 0

signal viewables_list_changed
signal views_list_changed

func _init():
	#open the res://viewables folder and collect all the .tres files there into the viewables dict
	var dir = DirAccess.open(gather_from_path)
	if dir:
		var fnames = dir.get_files()
		for f in fnames:
			var vb = load(gather_from_path + "/" + f)
			viewables[vb.get_id()] = vb
	viewables_list_changed.emit()

	probe_for_cameras()



func probe_for_cameras() -> void:
	for vid in viewables:
		var v = viewables[vid]
		match v.type:
			Viewable.Type.SCENE_2D, Viewable.Type.SCENE_3D:
				var tmp = v.resource.instantiate()
				var cameras = parse_camera_paths(tmp)
				v.cameras = cameras
				tmp.queue_free()
		
func parse_camera_paths(n : Node) -> Array:
	var ret = []
	#print("looking for cameras in %s" % n.name)
	for c in n.get_children():
		if c is Camera2D or c is Camera3D:
			#print("found camera %s" %  c.name)
			ret.append({
				"name" : c.name,
				"path" : n.get_path_to(c)
				})
	return ret

func create_view() -> View:
	var id = create_view_id()
	var view = View.new()
	view.id = id
	views[id] = view
	return view


func create_view_id() -> int:
	var id : int = String("%d" % views_id_index).hash()
	views_id_index +=1 
	return id


func get_view(vid : int) -> View:
	return views[vid]

func get_viewable(vid : int) -> Viewable:
	return viewables[vid]


func get_save_data():
	var views_data = []
	for v in views:
		views_data.append(views[v].get_save_data())

	var data = {
		"views_id_index" : views_id_index,
		"views" : views_data
	} 

	return data

func load_save_data(data):
	views_id_index = int(data.views_id_index)
	for view_data in data.views:
		var view = View.from_save_data(view_data)
		views[view.id] = view
