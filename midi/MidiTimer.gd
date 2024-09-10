extends Node
class_name MidiTimer

enum Div{
	NONE,
	THIRTY_SECOND = 3,
	SIXTEENTH = 6,
	EIGHTH_TRIPLET = 4,
	EIGHTH = 12,
	DOTTED_EIGHTH = 18,
	QUARTER_TRIPLET = 8,
	QUARTER = 24,
	DOTTED_QUARTER = 36,
	HALF = 48,
	DOTTED_HALF = 76,
	WHOLE = 92,
	TWO_BAR = 184,
	FOUR_BAR = 368,
	}

@export var interval : Div = Div.QUARTER 
@export var offset : Div = Div.NONE 

var count: int = 0
var reps: int = 0
var normalized: float = 0
var _interval: int = 0
var _offset: int = 0
var _interval_setraw: bool = false
var _offset_setraw: bool = false

signal timeout

func _enter_tree() -> void:
	add_child(MidiClock.ref())

func _ready():
	if !_interval_setraw: 
		_interval = int(interval)
	if !_offset_setraw:
		_offset = int(offset)


func _process(delta: float):
	if MidiClock.is_running():
		count = MidiClock.get_count() - _offset

		if !(count % interval):
			reps = count / _interval
			timeout.emit(reps)


func set_interval_raw(value: int):
	_interval = value
	_interval_setraw = true


func set_offset_raw(value: int):
	_offset = value
	_offset_setraw = true


func get_reps() -> int:
	return reps


func get_normalized() -> float:
	return (count % interval) / float(interval)

