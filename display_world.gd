extends Node2D


func _ready():
	get_viewport().size_changed.connect(_root_viewport_size_changed)

	$DemoQuad1.texture = $SubViewport1.get_texture()
	$DemoQuad2.texture = $SubViewport2.get_texture()

# Called when the root's viewport size changes (i.e. when the window is resized).
# This is done to handle multiple resolutions without losing quality.
func _root_viewport_size_changed():
	pass
