extends Node
class_name MidiClient

@export var channel : int = 0
@export var omni: bool = false

var message_handlers = {}

enum {
	C0 = 12,
	C1 = 24,
	C2 = 36,
	C3 = 48,
	C4 = 60,
	C5 = 72,
	C6 = 84,
	C7 = 96,
	C8 = 108
	}

func _process(delta : float):
	pass

func _input(event: InputEvent):
	if event is not InputEventMIDI:
		return

	if !(omni || event.channel == channel):
		return

	if !message_handlers.has(event.message):
		return

	message_handlers[event.message].call(event)
