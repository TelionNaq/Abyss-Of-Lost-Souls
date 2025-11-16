extends Node

signal round_started(round_number)
signal round_ended(round_number)
signal prep_phase_started(round_number, prep_time)
signal prep_phase_ended(round_number)
signal enter_targeting_mode(weapon_name: String)

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
var enemy_health_bonus: int = 0

var active_enemies: Array = []

var boss_scene = preload("res://Escenas/enemigo/boss.tscn")

var all_rounds = [
    [{"enemy_scene": preload("res://Escenas/enemigo/enemigo.tscn"), "count": 5}],
    [{"enemy_scene": preload("res://Escenas/enemigo/enemigo.tscn"), "count": 8}],
    [{"enemy_scene": preload("res://Escenas/enemigo/enemigo.tscn"), "count": 10}],
    [{"enemy_scene": preload("res://Escenas/enemigo/enemigo.tscn"), "count": 12}],
    [{"enemy_scene": preload("res://Escenas/enemigo/enemigo.tscn"), "count": 15}],
    [{"enemy_scene": preload("res://Escenas/enemigo/enemigo.tscn"), "count": 18}],
    [{"enemy_scene": preload("res://Escenas/enemigo/enemigo.tscn"), "count": 20}],
    [{"enemy_scene": preload("res://Escenas/enemigo/enemigo.tscn"), "count": 22}],
    [{"enemy_scene": preload("res://Escenas/enemigo/enemigo.tscn"), "count": 25}],
    [{"enemy_scene": boss_scene, "count": 1}, {"enemy_scene": preload("res://Escenas/enemigo/enemigo.tscn"), "count": 15}]
]

var tienda_scene = preload("res://Escenas/Tienda/tienda.tscn")

func _ready() -> void:
    print("RoundManager ready. Initial current_round_index: ", current_round_index, ", enemy_health_bonus: ", enemy_health_bonus)
    randomize()
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
                hud_contador_ronda_label.text = "next round in: %d s" % [ceil(prep_phase_timer.time_left)]
    
    elif current_round_state == RoundState.ROUND_IN_PROGRESS:
        # Polling check for active enemies
        for i in range(active_enemies.size() - 1, -1, -1):
            if not is_instance_valid(active_enemies[i]):
                active_enemies.remove_at(i)

        # Check for round end condition
        var all_waves_spawned = current_wave_index >= all_rounds[current_round_index].size()
        if all_waves_spawned and active_enemies.is_empty():
            # Ensure this block only runs once
            current_round_state = RoundState.ROUND_FINISHED 
            
            print("Ronda %d completada!" % [current_round_index + 1])
            round_ended.emit(current_round_index + 1)
            
            print("Round ", current_round_index + 1, " complete. enemy_health_bonus before increment: ", enemy_health_bonus)
            enemy_health_bonus += 10
            current_round_index += 1
            print("Starting next round. New current_round_index: ", current_round_index, ", new enemy_health_bonus: ", enemy_health_bonus)
            start_prep_phase(current_round_index)


func start_prep_phase(round_idx: int) -> void:
    active_enemies.clear()
    current_round_state = RoundState.PREP_PHASE
    current_round_index = round_idx
    current_wave_index = 0
    
    if current_round_index >= all_rounds.size():
        print("Todas las rondas completadas!")
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
        hud_contador_ronda_label.text = "Round in progress"
    
    start_next_wave()

func start_next_wave() -> void:
    var current_round_data = all_rounds[current_round_index]
    if current_wave_index < current_round_data.size():
        var wave_data = current_round_data[current_wave_index]
        enemies_to_spawn_in_wave = wave_data.count
        enemies_spawned_in_wave = 0
        
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
            enemy_node.health += enemy_health_bonus
            print("Spawning enemy with health: ", enemy_node.health, " (base: ", enemy_node.health - enemy_health_bonus, " + bonus: ", enemy_health_bonus, ")")
            active_enemies.append(enemy_node) # Add to our tracking list
            
            # Connect signals for stat changes
            if "boss.tscn" in enemy_scene_to_spawn.resource_path:
                enemy_node.enemy_defeated.connect(_on_boss_defeated)
            else:
                enemy_node.enemy_defeated.connect(func(): PlayerStats.add_money(3))
            enemy_node.enemy_escaped.connect(func(): PlayerStats.decrease_health(5))
        else:
            print("ERROR: La escena de enemigo instanciada no contiene un hijo CharacterBody2D.")
            enemy_path_follow_instance.queue_free()
    else:
        print("ERROR: No se pudo spawnear enemigo. Escena de enemigo no definida para esta oleada.")

func _on_boss_defeated():
    PlayerStats.add_money(100)
    PlayerStats.increase_towers()

func _open_shop():
    var shop_instance = tienda_scene.instantiate()
    shop_instance.shop_interaction_finished.connect(_on_shop_interaction_finished)
    get_node("../CanvasLayer").add_child(shop_instance)
    get_tree().paused = true

func _on_shop_interaction_finished(weapon_name: String):
    get_tree().paused = false
    if weapon_name:
        emit_signal("enter_targeting_mode", weapon_name)
    else:
        start_round(current_round_index)

func _on_prep_phase_timer_timeout() -> void:
    if (current_round_index + 1) % 5 == 0:
        _open_shop()
    else:
        start_round(current_round_index)
