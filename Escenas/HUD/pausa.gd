extends Control

var settings_menu_scene = preload("res://Escenas/HUD/settings_menu.tscn")

func _ready():
    process_mode = Node.PROCESS_MODE_ALWAYS
    $TextureButton4.pressed.connect(_on_resume_pressed)
    $TextureButton3.pressed.connect(_on_main_menu_pressed)
    $TextureButton2.pressed.connect(_on_settings_pressed)

func _on_resume_pressed():
    get_tree().paused = false
    queue_free()

func _on_main_menu_pressed():
    get_tree().paused = false
    get_tree().current_scene.save_game()
    get_tree().change_scene_to_file("res://main_menu.tscn")

func _on_settings_pressed():
    var settings_menu = settings_menu_scene.instantiate()
    add_child(settings_menu)