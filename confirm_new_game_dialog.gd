extends Panel

signal confirmed

func _ready():
    $VBoxContainer/HBoxContainer/OKButton.pressed.connect(_on_ok_pressed)
    $VBoxContainer/HBoxContainer/CancelButton.pressed.connect(_on_cancel_pressed)

func _on_ok_pressed():
    emit_signal("confirmed")
    queue_free()

func _on_cancel_pressed():
    queue_free()
