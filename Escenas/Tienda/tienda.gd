extends Control

# Emits the purchased weapon name, or null if the user just continued.
signal shop_interaction_finished(weapon_name)

const WHIP_COST = 55
const AXE_COST = 79
const SCYTHE_COST = 67

@onready var axe_button = $"Menu Tienda(Cambiar)/Button Axe"
@onready var whip_button = $"Menu Tienda(Cambiar)/Button WHIP"
@onready var scythe_button = $"Menu Tienda(Cambiar)/Button SCHYTHE"
@onready var continue_button = $"Menu Tienda(Cambiar)/Button Continue"

@onready var axe_cost_label = $"axe"
@onready var whip_cost_label = $"whip"
@onready var scythe_cost_label = $"scythe"

func _ready():
    process_mode = Node.PROCESS_MODE_WHEN_PAUSED
    
    axe_button.pressed.connect(_on_axe_button_pressed)
    whip_button.pressed.connect(_on_whip_button_pressed)
    scythe_button.pressed.connect(_on_scythe_button_pressed)
    continue_button.pressed.connect(_on_continue_button_pressed)

    axe_cost_label.text = str(AXE_COST)
    whip_cost_label.text = str(WHIP_COST)
    scythe_cost_label.text = str(SCYTHE_COST)

func _on_axe_button_pressed():
    if PlayerStats.spend_money(AXE_COST):
        emit_signal("shop_interaction_finished", "axe")
        queue_free()
    else:
        print("Not enough money for Axe")

func _on_whip_button_pressed():
    if PlayerStats.spend_money(WHIP_COST):
        emit_signal("shop_interaction_finished", "whip")
        queue_free()
    else:
        print("Not enough money for Whip")

func _on_scythe_button_pressed():
    if PlayerStats.spend_money(SCYTHE_COST):
        emit_signal("shop_interaction_finished", "scythe")
        queue_free()
    else:
        print("Not enough money for Scythe")

func _on_continue_button_pressed():
    emit_signal("shop_interaction_finished", null)
    queue_free()
