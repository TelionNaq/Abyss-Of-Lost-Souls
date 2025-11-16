extends Control

func _ready():
    process_mode = Node.PROCESS_MODE_ALWAYS
    $TextureButton.pressed.connect(_on_main_menu_pressed)
    $TextureButton2.pressed.connect(_on_try_again_pressed)

func _on_try_again_pressed():
    get_tree().paused = false
    PlayerStats.reset()
    get_tree().reload_current_scene()

func _on_main_menu_pressed():
    get_tree().paused = false
    PlayerStats.reset()
    get_tree().change_scene_to_file("res://main_menu.tscn")
