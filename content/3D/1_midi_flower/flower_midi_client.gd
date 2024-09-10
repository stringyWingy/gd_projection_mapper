extends MidiClient

signal sig_note_on
signal sig_note_off

func _init():
	message_handlers = {
		MIDI_MESSAGE_NOTE_ON : note_on,
		MIDI_MESSAGE_NOTE_OFF : note_off
		}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func note_on(event: InputEventMIDI):
	sig_note_on.emit(event.pitch, event.velocity)


func note_off(event: InputEventMIDI):
	sig_note_off.emit(event.pitch)
