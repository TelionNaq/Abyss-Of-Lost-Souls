extends Control

@export var Character: Array[character_data]
@export var morphblade: Array[Resource]
@export var eidonol: Array[Resource]
@export var nightfall: Array[Resource]

@onready var personaje = $character
@onready var fondo = $background
@onready var nombre = $"character info/name"
@onready var desc = $"character info/desc"
@onready var dmg = $"character info2/attdmg"
@onready var rang = $"character info2/attrange"
@onready var perso_show = $show_perso

@onready var hover_sound = $HoverSound
@onready var click_sound = $ClickSound

@onready var btn_morphblade = $pick_morphblade
@onready var btn_eidonol = $pick_eidonol
@onready var btn_nightfall = $pick_nightfall
@onready var btn_personality = $TextureButton
@onready var btn_back = $back

var current_character_index: int = 0
var current_personality_index: int = 0

func _ready() -> void:
    update_character_display()
    # Connect hover sounds
    btn_morphblade.mouse_entered.connect(_on_any_button_mouse_entered)
    btn_eidonol.mouse_entered.connect(_on_any_button_mouse_entered)
    btn_nightfall.mouse_entered.connect(_on_any_button_mouse_entered)
    btn_personality.mouse_entered.connect(_on_any_button_mouse_entered)
    btn_back.mouse_entered.connect(_on_any_button_mouse_entered)

func _on_any_button_mouse_entered() -> void:
    hover_sound.play()

func update_character_display() -> void:
    # Update character info
    personaje.texture = Character[current_character_index].Imagen
    fondo.texture = Character[current_character_index].Background
    nombre.text = Character[current_character_index].Name
    desc.text = Character[current_character_index].Description
    dmg.text = Character[current_character_index].AttDamage
    rang.text = Character[current_character_index].AttRange
    
    # Update personality
    var personalities = get_current_personalities()
    if personalities and not personalities.is_empty():
        current_personality_index = clamp(current_personality_index, 0, personalities.size() - 1)
        perso_show.texture = personalities[current_personality_index].Icono
        desc.text = personalities[current_personality_index].Desc
    else:
        perso_show.texture = null

func get_current_personalities() -> Array[Resource]:
    match current_character_index:
        0:
            return morphblade
        1:
            return eidonol
        2:
            return nightfall
        _:
            return []

const DOUBLE_CLICK_TIME_S = 0.4
var last_press_time = 0
var last_button_pressed = -1

func _handle_character_selection(character_index: int) -> void:
    click_sound.play()
    
    var current_time = Time.get_ticks_msec()
    
    if last_button_pressed == character_index and current_time - last_press_time < DOUBLE_CLICK_TIME_S * 1000:
        # Double-click detected
        get_tree().change_scene_to_file("res://Escenas/Niveles/Nivel1/lv_1.tscn")
    else:
        # Single-click
        if current_character_index != character_index:
            current_character_index = character_index
            current_personality_index = 0
            update_character_display()
        
        last_press_time = current_time
        last_button_pressed = character_index

func _on_pick_morphblade_pressed() -> void:
    _handle_character_selection(0)

func _on_pick_eidonol_pressed() -> void:
    _handle_character_selection(1)

func _on_pick_nightfall_pressed() -> void:
    _handle_character_selection(2)

func _on_texture_button_pressed() -> void:
    click_sound.play()
    var personalities = get_current_personalities()
    if personalities and not personalities.is_empty():
        current_personality_index = (current_personality_index + 1) % personalities.size()
        update_character_display()

func _on_back_pressed() -> void:
    click_sound.play()
    get_tree().change_scene_to_file("res://level_menu.tscn")
