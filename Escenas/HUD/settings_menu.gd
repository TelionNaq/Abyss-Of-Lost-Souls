extends Control

@onready var volume_slider = $VBoxContainer/VolumeSlider
@onready var back_button = $VBoxContainer/BackButton
@onready var volume_label = $VBoxContainer/Label

func _ready():
    process_mode = Node.PROCESS_MODE_ALWAYS
    volume_slider.value_changed.connect(_on_volume_slider_changed)
    back_button.pressed.connect(_on_back_pressed)
    
    # Initialize slider value from current volume
    var master_bus_idx = AudioServer.get_bus_index("Master")
    var current_db = AudioServer.get_bus_volume_db(master_bus_idx)
    volume_slider.value = db_to_linear(current_db) * 100.0
    volume_label.text = "Volume: %d" % [int(volume_slider.value)]

func _on_volume_slider_changed(value):
    var db = linear_to_db(value / 100.0)
    var master_bus_idx = AudioServer.get_bus_index("Master")
    AudioServer.set_bus_volume_db(master_bus_idx, db)
    volume_label.text = "Volume: %d" % [int(value)]

func _on_back_pressed():
    queue_free()
