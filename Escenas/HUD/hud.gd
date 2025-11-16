extends Control

signal start_placement_mode

@onready var health_label = $Vida/ValorVida
@onready var tower_count_label = $TowerCount
@onready var unidad_button = $Unidad

@onready var money_label = $Dinerol

var pause_menu_scene = preload("res://Escenas/HUD/pausa.tscn")

@onready var pause_button = $Pause

var is_fast_forward = false
var fast_forward_texture = preload("res://menu/selectfast.png")
var original_fast_forward_texture: Texture2D

@onready var fast_forward_button = $Fast

func _ready():
    PlayerStats.health_changed.connect(update_health)
    PlayerStats.towers_changed.connect(update_towers)
    PlayerStats.money_changed.connect(update_money)
    unidad_button.pressed.connect(_on_unidad_pressed)
    pause_button.pressed.connect(_on_pause_pressed)
    fast_forward_button.pressed.connect(_on_fast_forward_pressed)
    
    original_fast_forward_texture = fast_forward_button.texture_normal
    
    update_health(PlayerStats.health)
    update_towers(PlayerStats.towers_available)
    update_money(PlayerStats.money)

func update_health(new_health: int):
    health_label.text = str(new_health)

func update_towers(new_towers: int):
    tower_count_label.text = "x" + str(new_towers)

func update_money(new_money: int):
    money_label.text = str(new_money)


func _on_unidad_pressed():
    if PlayerStats.can_place_tower():
        emit_signal("start_placement_mode")

func _on_pause_pressed():
    var pause_menu = pause_menu_scene.instantiate()
    add_child(pause_menu)
    get_tree().paused = true

func _on_fast_forward_pressed():
    is_fast_forward = not is_fast_forward
    if is_fast_forward:
        Engine.time_scale = 2.0
        fast_forward_button.texture_normal = fast_forward_texture
    else:
        Engine.time_scale = 1.0
        fast_forward_button.texture_normal = original_fast_forward_texture

