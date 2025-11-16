extends StaticBody2D

# --- VARIABLES ---

enum Direction { DOWN, LEFT, UP, RIGHT }
@export var current_direction: Direction = Direction.DOWN

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $Area2D
@onready var attack_area_shape: CollisionShape2D = $Area2D/CollisionShape2D
@onready var attack_timer: Timer = $Timer
@onready var axe_slash_effect: TextureRect = $AxeSlashEffect
@onready var whip_slash_effect: TextureRect = $WhipSlashEffect
@onready var scythe_slash_effect: TextureRect = $ScytheSlashEffect
@onready var attack_sound_player: AudioStreamPlayer = $AttackSoundPlayer

var _targets_in_range: Array[Node2D] = []
var equipped_weapons: Array = []

# Weapon specific variables
var axe_timer: Timer
const AXE_COOLDOWN = 3.0
const AXE_DAMAGE = 80

var whip_timer: Timer
const WHIP_COOLDOWN = 1.6
const WHIP_DAMAGE = 35
const WHIP_KNOCKBACK = 50.0

var scythe_timer: Timer
const SCYTHE_COOLDOWN = 2.5
const SCYTHE_DAMAGE = 50
const SCYTHE_SLOW_DURATION = 1.0
const SCYTHE_SLOW_AMOUNT = 0.5


# --- FUNCIONES DE GODOT ---

func _ready():
    attack_timer.wait_time = 1.0
    attack_timer.one_shot = true
    
    attack_area.body_entered.connect(_on_Area2D_body_entered)
    attack_area.body_exited.connect(_on_Area2D_body_exited)
    
    _update_visuals()
    # If the tower is loaded from a save, initialize its weapons
    if has_weapon("axe"): _initialize_axe_weapon()
    if has_weapon("whip"): _initialize_whip_weapon()
    if has_weapon("scythe"): _initialize_scythe_weapon()

func _process(_delta):
    # Normal attack
    if attack_timer.is_stopped() and not _targets_in_range.is_empty():
        _attack()
        
    # Weapon attacks
    if has_weapon("axe") and axe_timer and axe_timer.is_stopped() and not _targets_in_range.is_empty():
        _axe_attack()
        
    if has_weapon("whip") and whip_timer and whip_timer.is_stopped() and not _targets_in_range.is_empty():
        _whip_attack()
        
    if has_weapon("scythe") and scythe_timer and scythe_timer.is_stopped() and not _targets_in_range.is_empty():
        _scythe_attack()


# --- LÓGICA DE INVENTARIO ---

func add_weapon(weapon_name: String):
    if equipped_weapons.size() < 3 and not has_weapon(weapon_name):
        equipped_weapons.append(weapon_name)
        print("Weapon '", weapon_name, "' added to tower.")
        
        if weapon_name == "axe": _initialize_axe_weapon()
        elif weapon_name == "whip": _initialize_whip_weapon()
        elif weapon_name == "scythe": _initialize_scythe_weapon()
    else:
        print("Tower inventory is full or weapon already equipped.")

func has_weapon(weapon_name: String) -> bool:
    return equipped_weapons.has(weapon_name)

func _initialize_axe_weapon():
    if get_node_or_null("AxeTimer"): return
    axe_timer = Timer.new()
    axe_timer.name = "AxeTimer"
    axe_timer.wait_time = AXE_COOLDOWN
    axe_timer.one_shot = true
    add_child(axe_timer)
    axe_timer.start()

func _initialize_whip_weapon():
    if get_node_or_null("WhipTimer"): return
    whip_timer = Timer.new()
    whip_timer.name = "WhipTimer"
    whip_timer.wait_time = WHIP_COOLDOWN
    whip_timer.one_shot = true
    add_child(whip_timer)
    whip_timer.start()

func _initialize_scythe_weapon():
    if get_node_or_null("ScytheTimer"): return
    scythe_timer = Timer.new()
    scythe_timer.name = "ScytheTimer"
    scythe_timer.wait_time = SCYTHE_COOLDOWN
    scythe_timer.one_shot = true
    add_child(scythe_timer)
    scythe_timer.start()


# --- LÓGICA DE VISUALES ---

func _update_visuals():
    var animation_name = ""
    var shape_rotation_deg = 0
    match current_direction:
        Direction.DOWN:
            animation_name = "abajo_idle"
            shape_rotation_deg = 0
        Direction.LEFT:
            animation_name = "izquierda_idle"
            shape_rotation_deg = 90
        Direction.UP:
            animation_name = "arriba_idle"
            shape_rotation_deg = 180
        Direction.RIGHT:
            animation_name = "derecha_idle"
            shape_rotation_deg = 270
    animated_sprite.play(animation_name)
    attack_area_shape.rotation_degrees = shape_rotation_deg


# --- LÓGICA DE ATAQUE ---

func _attack():
    attack_timer.start()
    attack_sound_player.play() # Play sound here
    var attack_animation_name = ""
    match current_direction:
        Direction.DOWN: attack_animation_name = "abajo_atacar"
        Direction.LEFT: attack_animation_name = "izquierda_atacar"
        Direction.UP: attack_animation_name = "arriba_atacar"
        Direction.RIGHT: attack_animation_name = "derecha_atacar"
    animated_sprite.play(attack_animation_name)
    
    var tween = create_tween()
    tween.tween_interval(0.4)
    tween.tween_callback(_update_visuals)
    
    var current_targets = _targets_in_range.duplicate()
    for enemy in current_targets:
        if is_instance_valid(enemy) and enemy.has_method("take_damage"):
            enemy.take_damage(25)

func _axe_attack():
    if not axe_timer: return
    axe_timer.start()
    attack_sound_player.play() # Play sound here
    var target = _get_valid_target()
    if target:
        target.take_damage(AXE_DAMAGE)
        _display_axe_slash_effect(target.global_position)

func _whip_attack():
    if not whip_timer: return
    whip_timer.start()
    attack_sound_player.play() # Play sound here
    var target = _get_valid_target()
    if target:
        target.take_damage(WHIP_DAMAGE)
        target.apply_knockback(WHIP_KNOCKBACK)
        _display_whip_slash_effect(target.global_position)

func _scythe_attack():
    if not scythe_timer: return
    scythe_timer.start()
    attack_sound_player.play() # Play sound here
    var target = _get_valid_target()
    if target:
        target.take_damage(SCYTHE_DAMAGE)
        target.apply_slow(SCYTHE_SLOW_DURATION, SCYTHE_SLOW_AMOUNT)
        _display_scythe_slash_effect(target.global_position)

func _get_valid_target() -> Node2D:
    for enemy in _targets_in_range:
        if is_instance_valid(enemy):
            return enemy
    return null

func _display_axe_slash_effect(pos: Vector2):
    if not axe_slash_effect: return
    _animate_slash_effect(axe_slash_effect, pos)

func _display_whip_slash_effect(pos: Vector2):
    if not whip_slash_effect: return
    _animate_slash_effect(whip_slash_effect, pos)

func _display_scythe_slash_effect(pos: Vector2):
    if not scythe_slash_effect: return
    _animate_slash_effect(scythe_slash_effect, pos)

func _animate_slash_effect(effect_node: TextureRect, pos: Vector2):
    effect_node.global_position = pos
    effect_node.rotation = randf() * PI * 2
    effect_node.modulate = Color(1, 1, 1, 1)
    effect_node.z_index = 100
    effect_node.visible = true
    
    var tween = create_tween()
    tween.tween_property(effect_node, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE)
    tween.tween_callback(func(): effect_node.visible = false)


# --- MANEJO DE SEÑALES (SIGNALS) ---

func _on_Area2D_body_entered(body: Node2D):
    if body.has_method("take_damage"):
        if not _targets_in_range.has(body):
            _targets_in_range.append(body)

func _on_Area2D_body_exited(body: Node2D):
    if _targets_in_range.has(body):
        _targets_in_range.erase(body)
