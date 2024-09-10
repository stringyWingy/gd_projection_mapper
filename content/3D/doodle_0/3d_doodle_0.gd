extends Node3D

@export var base_rotation_speed : float = 1
@export var harmonic_1 : float = 1 + 1/3.0
@export var harmonic_2 : float = 1 + 3/5.0

@onready var flower0 = $Flower0
@onready var flower1 = $Flower1
@onready var flower2 = $Flower2

var multi : MultiMesh = MultiMesh.new()
var multi_instance : MultiMeshInstance3D = MultiMeshInstance3D.new()
var transforms : Array = []
var all_tears : Array = []
var mesh_count : int = 0

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
	#still apply transforms to these nicely hierarchized nodes

	$Flower0.rotate_z(delta * base_rotation_speed)
	$Flower1.rotate_z(delta * base_rotation_speed * harmonic_1)
	$Flower2.rotate_z(delta * base_rotation_speed * harmonic_2)
	
	#then just copy the resulting global transforms to our multimesh
	multi_copy_transforms()


func init_multi_mesh():
	multi.set_use_custom_data(true)
	multi.set_use_colors(true)
	multi.set_transform_format(MultiMesh.TRANSFORM_3D)

	#collect all the tears in the static .tscn
	all_tears.append_array(flower0.get_children())
	all_tears.append_array(flower1.get_children())
	all_tears.append_array(flower2.get_children())

	mesh_count = all_tears.size()
	transforms.resize(mesh_count)
	custom_data.resize(mesh_count)
	multi.instance_count = mesh_count
	multi.mesh = all_tears[0].mesh

	multi_copy_transforms()
	for i in mesh_count:
		var note_velocity = 0.0
		var cid = i/7.0
		var custom = Color(note_velocity, cid, 0, 0)
		multi.set_instance_custom_data(i, custom)

	flower0.set_visible(false)
	flower1.set_visible(false)
	flower2.set_visible(false)

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

