extends RefCounted
class_name Adsr

signal finished
signal value_changed

static func clone(from) -> Adsr:
	return Adsr.new(from.attack, from.decay, from.sustain, from.release)

static func from_array(from) -> Adsr:
	return Adsr.new(from[0], from[1], from[2], from[3])

var attack: float = 0
var decay: float = 0
var sustain: float = 1
var release: float = 0

var value: float = 0

enum {
	IDLE,
	PRESSED,
	RELEASING,
	}

var state = IDLE
var time_mark: float = 0

func _init(a: float = 0, d: float = 0, s: float = 1, r: float = 0):
	attack = a
	decay = d
	sustain = s
	release = r
	

func is_active():
	return state != IDLE


func trigger_press():
	time_mark = Time.get_ticks_msec()
	state = PRESSED


func trigger_release():
	time_mark = Time.get_ticks_msec()
	state = RELEASING


func evaluate():
	var rtime = Time.get_ticks_msec() - time_mark
	var last_val = value

	var defer_finished: bool = false

	match state:
		IDLE:
			value = 0
		PRESSED when rtime < attack:
			value = rtime / attack
		PRESSED when rtime < attack + decay:
			value = lerp(1.0, sustain, (rtime - attack) / decay)
		PRESSED when rtime > attack + decay:
			value = sustain
		RELEASING when rtime < release:
			value = (1 - (rtime / release)) / sustain 
		_:
			state = IDLE
			defer_finished = true
			value = 0

	if last_val != value:
		value_changed.emit(value)
	
	if defer_finished:
		finished.emit()
	return value
