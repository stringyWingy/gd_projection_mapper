extends Node3D

@export var base_rotation_speed : float = 1
@export var max_harmonic : float = 8/5.0
@export var beat_all_scale : float = 1.2
@export var active_note_scale : float = 1.2

@onready var flower_parent = $FlowerParent
@onready var num_layers : int = flower_parent.get_children().size()

var multi : MultiMesh = MultiMesh.new()
var multi_instance : MultiMeshInstance3D = MultiMeshInstance3D.new()
var transforms : Array = []
var orig_scales : Array = []
var all_tears : Array = []
var mesh_count : int = 0

var material: Material
var shader_param_name = "u_quarter_note_asr"

var adsr_pool_free : Array = []
var adsr_pool_active : Dictionary = {}
var adsr_settings = {
	attack = 50, 
	decay = 100,
	sustain = 1,
	release =400 
}
var beat_envelope := Asr.new(50,100,100)

#custom data:
#R: note velocity 0-1
#G: group id (cast to int in shader)

var custom_data := PackedColorArray()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	init_multi_mesh()
	multi_instance.multimesh = multi
	add_child(multi_instance)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	beat_envelope.evaluate()
	for a in adsr_pool_active:
		adsr_pool_active[a].evaluate()

	if base_rotation_speed > 0:
		var i = 0
		for f in flower_parent.get_children():
			var ssign = 1 if ((i + 1) % 4 < 2) else -1
			var harmonic = lerp(1.0, max_harmonic, (((i+1)/2) + 0.5) / (float(num_layers)/2))
			f.rotate_z(delta * base_rotation_speed * harmonic * ssign)
			i += 1

	#then just copy the resulting global transforms to our multimesh
	multi_copy_transforms()


func init_multi_mesh():
	multi.set_use_custom_data(true)
	multi.set_transform_format(MultiMesh.TRANSFORM_3D)

	#collect all the tears in the static .tscn
	for c in flower_parent.get_children():
		all_tears.append_array(c.get_children())

	mesh_count = all_tears.size()
	transforms.resize(mesh_count)
	custom_data.resize(mesh_count)
	multi.instance_count = mesh_count
	multi.mesh = all_tears[0].mesh

	#set callback to plug in the beat asr into the shader uniform
	material = multi.mesh.surface_get_material(0)
	beat_envelope.value_changed.connect(update_shader_uniform)

	multi_copy_transforms()
	#stash these starting scales for later shenanigans
	orig_scales = transforms.map(func(t: Transform3D):
		return t.basis.get_scale())


	for i in mesh_count:
		var adsr_value = 0.0
		var layer_id = i/7.0
		var custom = Color(adsr_value, layer_id, 0, 0)
		custom_data[i] = custom
		multi.set_instance_custom_data(i, custom)

	flower_parent.set_visible(false)

#loop through all the collected meshes, copy their transforms into the multimesh, then set them invisible
func multi_copy_transforms():
	var i = 0
	for tear in all_tears:
		var t = tear.get_global_transform()
		transforms[i] = t
		multi.set_instance_transform(i, t)
		i += 1

func multi_push_transforms():
	var i = 0
	for t in transforms:
		multi.set_instance_transform(i, t)
		i += 1


func midi_note_to_mesh_index(note: int) -> int:
	var idx = note - MidiClient.C2
	if idx < 0 || idx >= mesh_count:
		idx = -1
	return idx


func get_adsr(note: int):
	if adsr_pool_free.is_empty():
		var new = Adsr.clone(adsr_settings)
		adsr_pool_active[note] = new
		new.finished.connect(return_adsr.bind(note), CONNECT_ONE_SHOT)
		return new
	else:
		var ret = adsr_pool_free.pop_back()
		adsr_pool_active[note] = ret
		ret.finished.connect(return_adsr.bind(note), CONNECT_ONE_SHOT)
		return ret


func return_adsr(note: int):
	var which = adsr_pool_active[note]
	#disconnect everything that was listening for value changed
	var connections = which.value_changed.get_connections()
	for c in connections:
		c.signal.disconnect(c.callable)

	adsr_pool_active.erase(note)
	adsr_pool_free.append(which)


func update_shader_uniform(value: float):
	material.set_shader_parameter(shader_param_name, value)


func _on_quarter_note(quarters_counted: int):
	beat_envelope.trigger_press()

func _on_note_on(note: int, vel: int):
	var tear_index = midi_note_to_mesh_index(note)
	#out of array bounds
	if tear_index < 0:
		return

	var adsr = get_adsr(note)
	adsr.trigger_press()

	var value_changed_func = func(value: float):
		custom_data[tear_index].r = value
		multi.set_instance_custom_data(tear_index, custom_data[tear_index])

	adsr.value_changed.connect(value_changed_func)


func _on_note_off(note: int) -> void:
	if adsr_pool_active.has(note):
		adsr_pool_active[note].trigger_release()
