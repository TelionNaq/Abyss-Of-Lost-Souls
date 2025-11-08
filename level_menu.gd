extends Control

@export var Niveles: Array[level_data]
@onready var spr = $stage_visual
@onready var st_number = $VBoxContainer/text_stage1
@onready var st_name = $VBoxContainer/text_stagename1

@onready var hover_sound = $HoverSound
@onready var click_sound = $ClickSound

@onready var button_left = $button_left
@onready var button_right = $button_right
@onready var texture_button = $TextureButton
@onready var back_button = $back

var cont: int = 0

func _ready() -> void:
    st_number.text = Niveles[cont].Stage
    spr.texture = Niveles[cont].Imagen
    st_name.text = Niveles[cont].Name

    # Connect hover sounds
    button_left.mouse_entered.connect(_on_any_button_mouse_entered)
    button_right.mouse_entered.connect(_on_any_button_mouse_entered)
    texture_button.mouse_entered.connect(_on_any_button_mouse_entered)
    back_button.mouse_entered.connect(_on_any_button_mouse_entered)

func _on_any_button_mouse_entered() -> void:
    hover_sound.play()

func forward() -> void:
    if cont < Niveles.size() -1:
        cont += 1
        st_number.text = Niveles[cont].Stage
        spr.texture = Niveles[cont].Imagen
        st_name.text = Niveles[cont].Name

func backward() -> void:
    if cont > 0:
        cont -= 1
        st_number.text = Niveles[cont].Stage
        spr.texture = Niveles[cont].Imagen
        st_name.text = Niveles[cont].Name

func _on_button_right_pressed() -> void:
    click_sound.play()
    forward()

func _on_button_left_pressed() -> void:
    click_sound.play()
    backward()

func _on_texture_button_pressed() -> void:
    click_sound.play()
    get_tree().change_scene_to_file("res://character_menu.tscn")

func _on_back_pressed() -> void:
    click_sound.play()
    get_tree().change_scene_to_file("res://main_menu.tscn")
