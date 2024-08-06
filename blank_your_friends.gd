extends Control

@onready var prefix = $Prefix
@onready var suffix = $Suffix

#\n will be the delimiter to split the strings prefix and suffix
#for example: "make \n soup" -> "make your friends soup"
var verb_phrases : PackedStringArray = PackedStringArray([
	"kiss",
	"make \n soup",
	"have sex with",
	"grow old with",
	"die young with",
	"protect",
	"call",
	"antagonize",
	"make amends with",
	"conduct psychological experiements on",
	"hold \n accountable",
	"do labor for",
	"accept help from",
	"do drugs with",
	"get sober with",
	"annoy",
	"introduce \n to each other",
	"spend time with",
	"avoid",
	"let go of",
	"make art with",
	"make \n into art",
	"dream of a better world with",
	"fight cops with",
	"party with",
	"work with",
	"fall in love with",
	"start a band with",
	"break up with",
	"teach",
	"learn from",
	"meditate with",
	"dance with",
	"challenge",
	"do crimes with",
	"reticulate \n splines"
])

@export var timer_interval : float = 1

var current_phrase : int = 0
var timer = Timer.new()

var unused_indices : Array = []

func next():
	if unused_indices.is_empty():
		shuffle_indices()

	var rand_index = unused_indices.pop_back()
	var phrase = verb_phrases[rand_index]
	if phrase.contains("\n"):
		var sub_phrases = phrase.split("\n")
		prefix.text = sub_phrases[0]
		suffix.text = sub_phrases[1]
	else:
		prefix.text = phrase
		suffix.text = ""
	
	
func shuffle_indices():
	unused_indices.clear()
	for i in verb_phrases.size() - 1:
		unused_indices.append(i)
		
	unused_indices.shuffle()
	

# Called when the node enters the scene tree for the first time.
func _ready():
	shuffle_indices()
	add_child(timer)
	timer.timeout.connect(next)
	timer.start(timer_interval)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

