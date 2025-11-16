extends CharacterBody2D

signal enemy_defeated
signal enemy_escaped

# Este script asume que la escena del enemigo será una hija de un nodo PathFollow2D.
# La estructura de la escena debería ser:
# - Path2D (con la curva de tu camino dibujada)
#   - PathFollow2D
#     - Enemy (esta escena, con este script)

# Velocidad a la que el enemigo se moverá a lo largo del camino.
# Puedes ajustarla desde el editor de Godot para cada enemigo.
@export var speed: float = 100.0

# Referencia al nodo PathFollow2D que controla la posición en el camino.
# Se obtiene automáticamente al iniciar.
@onready var path_follow: PathFollow2D = get_parent()

# Variable para la vida del enemigo.
@export var health: int = 65
var is_dead: bool = false
var original_speed: float = -1.0
var slow_timer: Timer

func _ready():
    # Obtenemos la referencia al nodo AnimatedSprite2D. 
    # El '$' es un atajo para get_node().
    var animated_sprite = $AnimatedSprite2D

    # Nos aseguramos de que el PathFollow2D no esté en modo loop (bucle)
    # y que no rote al personaje.
    if path_follow:
        path_follow.loop = false
        path_follow.rotates = false # <-- AÑADIDO: Esto evita que el enemigo rote con el camino.
    else:
        print("Error: El enemigo no es hijo de un nodo PathFollow2D. No se podrá mover.")
        # Desactivamos el procesamiento si no hay camino para ahorrar rendimiento.
        set_process(false)
        return # Salimos de la función si no hay camino

    # Iniciamos la animación de caminar. 
    # El nombre "default" lo he sacado de tu archivo .tscn.
    animated_sprite.play("default") # <-- AÑADIDO: Inicia la animación.
    
    slow_timer = Timer.new()
    slow_timer.one_shot = true
    slow_timer.timeout.connect(_on_slow_timer_timeout)
    add_child(slow_timer)


func _process(delta):
    # Si tenemos una referencia válida al PathFollow2D, movemos al enemigo.
    if path_follow:
        # Actualizamos el progreso a lo largo del camino.
        # Godot se encarga de mover el nodo automáticamente.
        path_follow.progress += speed * delta

        # Comprobamos si el enemigo ha llegado al final del camino.
        # progress_ratio es un valor de 0.0 (inicio) a 1.0 (final).
        if path_follow.progress_ratio >= 1.0:
            # El enemigo llegó al final. Emitimos la señal y lo eliminamos.
            enemy_escaped.emit()
            queue_free()

# --- Opcional: Funciones adicionales para un enemigo ---

func take_damage(amount):
    if is_dead:
        return

    health -= amount
    if health <= 0:
        is_dead = true
        enemy_defeated.emit()
        queue_free()

func apply_knockback(strength: float):
    if path_follow:
        path_follow.progress = max(0, path_follow.progress - strength)

func apply_slow(duration: float, amount: float):
    if original_speed == -1.0:
        original_speed = speed
    
    speed = original_speed * (1.0 - amount)
    slow_timer.start(duration)

func _on_slow_timer_timeout():
    speed = original_speed
