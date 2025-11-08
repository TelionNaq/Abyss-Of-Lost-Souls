extends Control

@onready var music = $musicamenu
@onready var arrow = $flecha
@onready var buttons_container = $VBoxContainer
@onready var hover_sound = $HoverSound
@onready var click_sound = $ClickSound

func _ready() -> void:
    music.play()
    arrow.hide()
    
    # Connect mouse signals for each button
    for button in buttons_container.get_children():
        if button is Button:
            button.mouse_entered.connect(_on_button_mouse_entered.bind(button))
    
    # Connect mouse exit signal for the container
    buttons_container.mouse_exited.connect(_on_buttons_container_mouse_exited)

func _on_button_mouse_entered(button: Button) -> void:
    hover_sound.play()
    arrow.show()
    # Center the arrow vertically with the button and position it to the left
    var button_rect = button.get_rect()
    var arrow_size = arrow.get_size()
    var container_pos = buttons_container.position
    
    var target_y = container_pos.y + button_rect.position.y + (button_rect.size.y / 2) - (arrow_size.y / 2)
    var target_x = container_pos.x + button_rect.position.x - arrow_size.x - 20 # 20 pixels padding
    
    arrow.position = Vector2(target_x, target_y)

func _on_buttons_container_mouse_exited() -> void:
    arrow.hide()

func _on_button_newgame_pressed() -> void:
    click_sound.play()
    get_tree().change_scene_to_file("res://level_menu.tscn")

func _on_button_continue_pressed() -> void:
    click_sound.play()
    pass # Replace with function body.

func _on_button_settings_pressed() -> void:
    click_sound.play()
    pass # Replace with function body.

func _on_button_exit_pressed() -> void:
    click_sound.play()
    get_tree().quit()
