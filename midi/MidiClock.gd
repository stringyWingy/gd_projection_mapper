extends Node
class_name MidiClock

static var instance : MidiClock = null

static func ref() -> MidiClock:
	if instance != null:
		return instance
	else:
		instance = MidiClock.new()
		print("MidiClock instantiated")
		return instance

static func is_running() -> bool:
	return ref()._clock_running

static func get_count() -> int:
	return ref()._clock_count


var channels = Array()
var _clock_running := false
var _clock_count: int = 0


func _init():
	OS.open_midi_inputs()
	var midi_inputs = OS.get_connected_midi_inputs()
	if midi_inputs.size() < 0:
		print("no midi inputs detected")
	else:
		print("midi inputs \n=======")
		for m in midi_inputs:
			print(m)
		
	channels.resize(16)


func _input(event : InputEvent):
	if event is not InputEventMIDI:
		return

	if event.message < MIDI_MESSAGE_SYSTEM_EXCLUSIVE:
		return

	#parse system / clock messages
	match event.message:
		MIDI_MESSAGE_START:
			_clock_running = true
			print("MIDI: clock started")
		MIDI_MESSAGE_STOP:
			_clock_running = false
			_clock_count = 0
			print("MIDI: clock stopped")
		MIDI_MESSAGE_CONTINUE:
			_clock_running = false
		MIDI_MESSAGE_TIMING_CLOCK:
			_clock_count += 1
		_:
			pass
