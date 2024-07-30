class_name PopupRename
extends Popup

@onready var label = $PanelContainer/VBoxContainer/Label
@onready var input = $PanelContainer/VBoxContainer/InputText
@onready var button_confirm = $PanelContainer/VBoxContainer/HFlowContainer/ButtonConfirm
@onready var button_cancel = $PanelContainer/VBoxContainer/HFlowContainer/ButtonCancel

signal confirm
signal cancel

# Called when the node enters the scene tree for the first time.
func _ready():
	button_confirm.connect("pressed", _on_confirm)
	button_cancel.connect("pressed", _on_cancel)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func set_and_show(label_text : String, default_text : String):
	input.grab_focus()
	label.text = label_text
	input.placeholder_text = default_text

func _on_confirm():
	if input.text != "":
		confirm.emit(input.text)
	else:
		confirm.emit(input.placeholder_text)
	hide()
	
func _on_cancel():
	cancel.emit()
	hide()

func _input(event):
	if event.is_action_pressed("rename_accept"):
		_on_confirm()
