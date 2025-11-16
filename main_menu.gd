extends Control

@onready var music = $musicamenu
@onready var arrow = $flecha
@onready var buttons_container = $VBoxContainer
@onready var hover_sound = $HoverSound
@onready var click_sound = $ClickSound

@onready var new_game_confirmation = $NewGameConfirmation
@onready var continue_button = $VBoxContainer/button_continue

func _ready() -> void:
    music.play()
    arrow.hide()
    
    if not SaveManager.has_save():
        continue_button.disabled = true
    
    new_game_confirmation.confirmed.connect(_on_new_game_confirmed)
    
    # Connect mouse signals for each button
    for button in buttons_container.get_children():
        if button is Button:
            button.mouse_entered.connect(_on_button_mouse_entered.bind(button))
    
    # Connect mouse exit signal for the container
    buttons_container.mouse_exited.connect(_on_buttons_container_mouse_exited)

func _on_button_mouse_entered(button: Button) -> void:
    if button.disabled:
        return
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

func _on_button_newgame_pressed():
    click_sound.play()
    if SaveManager.has_save():
        new_game_confirmation.show()
    else:
        start_new_game()

func start_new_game():
    PlayerStats.reset()
    SaveManager.delete_save()
    GlobalState.load_game_on_start = false
    get_tree().change_scene_to_file("res://level_menu.tscn")

func _on_new_game_confirmed():
    start_new_game()

func _on_button_continue_pressed() -> void:
    click_sound.play()
    GlobalState.load_game_on_start = true
    get_tree().change_scene_to_file("res://Escenas/Niveles/Nivel1/lv_1.tscn")

func _on_button_settings_pressed() -> void:
    click_sound.play()
    get_tree().change_scene_to_file("res://settings.tscn")

func _on_button_exit_pressed() -> void:
    click_sound.play()
    get_tree().quit()
