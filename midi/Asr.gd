extends RefCounted
class_name Asr

signal finished
signal value_changed

static func clone(from) -> Asr:
	return Asr.new(from.attack, from.sustain, from.release)

static func from_array(from) -> Asr:
	return Asr.new(from[0], from[1], from[2])

var attack: float = 0
var sustain: float = 0
var release: float = 0
var value: float = 0

enum {
	IDLE,
	ACTIVE
	}

var state = IDLE
var time_mark: float = 0

func _init(a: float = 0, s: float = 0, r: float = 0):
	attack = a
	sustain = s
	release = r
	

func is_active():
	return state != IDLE


func trigger_press():
	time_mark = Time.get_ticks_msec()
	state = ACTIVE


func evaluate():
	var rtime = Time.get_ticks_msec() - time_mark
	var last_val = value

	match state:
		IDLE:
			value =  0
		ACTIVE when rtime < attack:
			value =  rtime / attack
		ACTIVE when rtime < attack + sustain :
			value =  1
		ACTIVE when rtime < attack + sustain + release:
			value =  1 - (rtime - attack - sustain) / release
		_:
			state = IDLE
			finished.emit()
			value = 0

	if last_val != value:
		value_changed.emit(value)
	
	return value
