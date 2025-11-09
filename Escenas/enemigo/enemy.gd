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

# Variable para la vida del enemigo.
@export var health: int = 50

# Una función para cuando el enemigo recibe daño.
func take_damage(amount):
    health -= amount
    if health <= 0:
        enemy_defeated.emit() # Emitir la señal antes de morir
        queue_free() # El enemigo muere.
