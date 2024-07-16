extends Control

var window_display = null
@onready var subviewport = $HSplitContainer/VSplitContainer/AspectRatioContainer/SubViewportContainer/SubViewport
@onready var display_scene = preload("res://window_display.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	print(get_viewport().size)
	self.size = get_viewport().size

	get_viewport().set_embedding_subwindows(false)
	window_display = display_scene.instantiate()
	window_display.set_name("WindowDisplay")
	add_child(window_display)
	window_display.find_child("SubViewport").world_2d = subviewport.world_2d


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

#func _input(event):
	#if event is 
