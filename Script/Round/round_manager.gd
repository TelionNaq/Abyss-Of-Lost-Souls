extends Node

signal round_started(round_number)
signal round_ended(round_number)
signal prep_phase_started(round_number, prep_time)
signal prep_phase_ended(round_number)

enum RoundState {
    PREP_PHASE,
    ROUND_IN_PROGRESS,
    ROUND_FINISHED
}

@export var prep_time_between_rounds: float = 10.0
@export var enemy_path: NodePath

@onready var enemy_spawn_timer: Timer = $EnemySpawnTimer
@onready var prep_phase_timer: Timer = $PrepPhaseTimer

var hud_rondas_label: Label
var hud_contador_ronda_label: Label

var current_round_state: RoundState = RoundState.PREP_PHASE
var current_round_index: int = 0
var current_wave_index: int = 0
var enemies_to_spawn_in_wave: int = 0
var enemies_spawned_in_wave: int = 0
var enemies_alive_in_round: int = 0

var all_rounds = [
    # Ronda 1
    [
        {"enemy_scene": preload("res://Escenas/enemigo/enemigo.tscn"), "count": 5}
    ],
    # Ronda 2
    [
        {"enemy_scene": preload("res://Escenas/enemigo/enemigo.tscn"), "count": 8}
    ],
    # Ronda 3
    [
        {"enemy_scene": preload("res://Escenas/enemigo/enemigo.tscn"), "count": 10}
    ]
]

func _ready() -> void:
    randomize() # Inicializa el generador de números aleatorios
    enemy_spawn_timer.timeout.connect(_on_enemy_spawn_timer_timeout)
    prep_phase_timer.timeout.connect(_on_prep_phase_timer_timeout)
    
    hud_rondas_label = get_node_or_null("../CanvasLayer/HUD/Rondas")
    hud_contador_ronda_label = get_node_or_null("../CanvasLayer/HUD/ContadorRonda")

    if not hud_rondas_label or not hud_contador_ronda_label:
        print("ERROR: No se pudieron encontrar los labels del HUD. Verifica las rutas en round_manager.gd")
        return

    hud_rondas_label.text = "Round %d/%d" % [current_round_index + 1, all_rounds.size()]
    hud_contador_ronda_label.text = "Preparando..."
    
    start_prep_phase(current_round_index)

func _process(_delta: float) -> void:
    if current_round_state == RoundState.PREP_PHASE:
        if prep_phase_timer.is_stopped():
            return
            
        if prep_phase_timer.time_left > 0:
            if hud_contador_ronda_label:
                hud_contador_ronda_label.text = "Próxima ronda en: %d s" % [ceil(prep_phase_timer.time_left)]
        else:
            pass

func start_prep_phase(round_idx: int) -> void:
    current_round_state = RoundState.PREP_PHASE
    current_round_index = round_idx
    current_wave_index = 0
    enemies_alive_in_round = 0
    
    if current_round_index >= all_rounds.size():
        print("Todas las rondas completadas!")
        current_round_state = RoundState.ROUND_FINISHED
        if hud_rondas_label:
            hud_rondas_label.text = "ROUND 50/50"
        if hud_contador_ronda_label:
            hud_contador_ronda_label.text = ""
        return

    print("Iniciando fase de preparación para Ronda %d" % [current_round_index + 1])
    prep_phase_started.emit(current_round_index + 1, prep_time_between_rounds)
    
    if hud_rondas_label:
        hud_rondas_label.text = "Round %d/%d" % [current_round_index + 1, all_rounds.size()]
    
    prep_phase_timer.start(prep_time_between_rounds)

func start_round(round_idx: int) -> void:
    if current_round_state != RoundState.PREP_PHASE:
        return

    current_round_state = RoundState.ROUND_IN_PROGRESS
    prep_phase_ended.emit(round_idx + 1)
    print("Iniciando Ronda %d" % [round_idx + 1])
    round_started.emit(round_idx + 1)
    
    if hud_contador_ronda_label:
        hud_contador_ronda_label.text = "Ronda en curso"
    
    start_next_wave()

func start_next_wave() -> void:
    var current_round_data = all_rounds[current_round_index]
    if current_wave_index < current_round_data.size():
        var wave_data = current_round_data[current_wave_index]
        enemies_to_spawn_in_wave = wave_data.count
        enemies_spawned_in_wave = 0
        
        # Generar intervalo aleatorio entre 1.0 y 3.0 segundos
        enemy_spawn_timer.wait_time = randf() * 2.0 + 1.0
        
        enemy_spawn_timer.start()
        print("Iniciando Oleada %d de Ronda %d. Enemigos a spawnear: %d (Intervalo: %.2f s)" % [current_wave_index + 1, current_round_index + 1, enemies_to_spawn_in_wave, enemy_spawn_timer.wait_time])
    else:
        print("Todas las oleadas de la Ronda %d han sido iniciadas." % [current_round_index + 1])

func _on_enemy_spawn_timer_timeout() -> void:
    if enemies_spawned_in_wave < enemies_to_spawn_in_wave:
        spawn_enemy()
        enemies_spawned_in_wave += 1
    else:
        enemy_spawn_timer.stop()
        print("Oleada %d de Ronda %d completada (spawning)." % [current_wave_index + 1, current_round_index + 1])
        current_wave_index += 1
        start_next_wave()

func spawn_enemy() -> void:
    var path_node = get_node_or_null(enemy_path)
    if not path_node or not path_node is Path2D:
        print("ERROR: No se ha asignado un 'Path2D' válido en el RoundManager.")
        return

    var current_round_data = all_rounds[current_round_index]
    var wave_data = current_round_data[current_wave_index]
    var enemy_scene_to_spawn = wave_data.enemy_scene
    
    if enemy_scene_to_spawn:
        var enemy_path_follow_instance = enemy_scene_to_spawn.instantiate()
        path_node.add_child(enemy_path_follow_instance)

        var enemy_node = null
        for child in enemy_path_follow_instance.get_children():
            if child is CharacterBody2D:
                enemy_node = child
                break
        
        if enemy_node:
            enemies_alive_in_round += 1
            enemy_node.enemy_defeated.connect(_on_enemy_removed)
            enemy_node.enemy_escaped.connect(_on_enemy_removed)
            print("Enemigo spawneado. Enemigos vivos en ronda: %d" % [enemies_alive_in_round])
        else:
            print("ERROR: La escena de enemigo instanciada no contiene un hijo CharacterBody2D.")
            enemy_path_follow_instance.queue_free()
    else:
        print("ERROR: No se pudo spawnear enemigo. Escena de enemigo no definida para esta oleada.")

func _on_enemy_removed() -> void:
    enemies_alive_in_round -= 1
    print("Enemigo removido (derrotado o escapado). Enemigos vivos en ronda: %d" % [enemies_alive_in_round])
    
    if enemies_alive_in_round <= 0 and current_round_state == RoundState.ROUND_IN_PROGRESS:
        var current_round_data = all_rounds[current_round_index]
        if current_wave_index >= current_round_data.size():
            print("Ronda %d completada!" % [current_round_index + 1])
            round_ended.emit(current_round_index + 1)
            current_round_index += 1
            start_prep_phase(current_round_index)

func _on_prep_phase_timer_timeout() -> void:
    start_round(current_round_index)
