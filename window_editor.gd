extends Control

var window_display = null
@onready var display_world = $HSplitContainer/VSplitContainer/SubViewportContainer/SubViewport/DisplayWorld
@onready var display_scene = preload("res://window_display.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	self.size = get_viewport().size

	get_viewport().set_embedding_subwindows(false)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _input(event):
	if event.is_action_pressed("spawn_window_display"):
		if window_display ==  null:
			window_display = display_scene.instantiate()
			window_display.set_name("WindowDisplay")
			add_child(window_display)
			window_display.find_child("SubViewport").world_2d = display_world
		
		
