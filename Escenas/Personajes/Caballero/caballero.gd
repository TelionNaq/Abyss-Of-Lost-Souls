extends StaticBody2D

## LÓGICA DE LA TORRE (CABALLERO) - v3 (Animación Corregida)

# --- VARIABLES ---

enum Direction { DOWN, LEFT, UP, RIGHT }
@export var current_direction: Direction = Direction.DOWN

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $Area2D
@onready var attack_area_shape: CollisionShape2D = $Area2D/CollisionShape2D
@onready var attack_timer: Timer = $Timer

var _targets_in_range: Array[Node2D] = []


# --- FUNCIONES DE GODOT ---

func _ready():
    attack_timer.wait_time = 1.0
    attack_timer.one_shot = true
    
    attack_area.body_entered.connect(_on_Area2D_body_entered)
    attack_area.body_exited.connect(_on_Area2D_body_exited)
    
    # AÑADIDO: Conectamos la señal de que una animación ha terminado.
    animated_sprite.animation_finished.connect(_on_AnimatedSprite2D_animation_finished)
    
    _update_visuals()

func _process(_delta):
    if attack_timer.is_stopped() and not _targets_in_range.is_empty():
        _attack()


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
    
    var attack_animation_name = ""
    match current_direction:
        Direction.DOWN:
            attack_animation_name = "abajo_atacar"
        Direction.LEFT:
            attack_animation_name = "izquierda_atacar"
        Direction.UP:
            attack_animation_name = "arriba_atacar"
        Direction.RIGHT:
            attack_animation_name = "derecha_atacar"
    animated_sprite.play(attack_animation_name)
    
    var current_targets = _targets_in_range.duplicate()
    for enemy in current_targets:
        if is_instance_valid(enemy) and enemy.has_method("take_damage"):
            enemy.take_damage(25)

# --- MANEJO DE SEÑALES (SIGNALS) ---

# Se llama cuando un cuerpo entra en el Area2D.
func _on_Area2D_body_entered(body: Node2D):
    if body.has_method("take_damage"):
        if not _targets_in_range.has(body):
            _targets_in_range.append(body)

# Se llama cuando un cuerpo sale del Area2D.
func _on_Area2D_body_exited(body: Node2D):
    if _targets_in_range.has(body):
        _targets_in_range.erase(body)

# AÑADIDO: Se llama CADA VEZ que una animación del AnimatedSprite2D termina.
func _on_AnimatedSprite2D_animation_finished():
    # Verificamos si la animación que terminó fue una de ataque.
    var current_anim = animated_sprite.animation
    if current_anim.begins_with("abajo_atacar") or \
       current_anim.begins_with("izquierda_atacar") or \
       current_anim.begins_with("arriba_atacar") or \
       current_anim.begins_with("derecha_atacar"):
        
        # Si fue una de ataque, volvemos a la animación idle correspondiente.
        _update_visuals()
