extends Node3D

@export var base_rotation_speed : float = 1
@export var harmonic_1 : float = 1 + 1/3.0
@export var harmonic_2 : float = 1 + 3/5.0

@onready var flower0 = $Flower0
@onready var flower1 = $Flower1
@onready var flower2 = $Flower2


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$Flower0.rotate_z(delta * base_rotation_speed)
	$Flower1.rotate_z(delta * base_rotation_speed * harmonic_1)
	$Flower2.rotate_z(delta * base_rotation_speed * harmonic_2)
	pass
