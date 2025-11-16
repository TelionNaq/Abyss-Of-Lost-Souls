extends Node2D

enum PlacementState { IDLE, SELECTING_PLACEMENT }
enum GameState { PLAYING, TARGETING_WEAPON }

var lose_screen_scene = preload("res://Escenas/HUD/perder.tscn")
var caballero_scene = preload("res://Escenas/Personajes/Caballero/caballero.tscn")

var placement_state = PlacementState.IDLE
var current_game_state = GameState.PLAYING
var weapon_to_apply: String = ""
var targeting_pointer: Control = null

var shadow_tower = null
var is_valid_position = false

@onready var hud = $CanvasLayer/HUD
@onready var build_zone = $BuildZone
@onready var build_tower_node = $BuildTower
@onready var build_checker = $BuildChecker
@onready var canvas_layer = $CanvasLayer
@onready var placement_sound_player = $PlacementSoundPlayer
@onready var background_music_player = $BackgroundMusicPlayer

@onready var round_manager = $RoundManager

func _ready():
    process_mode = Node.PROCESS_MODE_INHERIT # Allow input processing when paused
    background_music_player.play()


    PlayerStats.no_health.connect(_on_no_health)
    hud.start_placement_mode.connect(_on_start_placement_mode)
    round_manager.enter_targeting_mode.connect(_on_enter_targeting_mode)
    
    if GlobalState.load_game_on_start:
        load_game()
        GlobalState.load_game_on_start = false

func _on_enter_targeting_mode(weapon_name: String):
    current_game_state = GameState.TARGETING_WEAPON
    weapon_to_apply = weapon_name
    
    # Create a simple green pointer
    targeting_pointer = ColorRect.new()
    targeting_pointer.color = Color.GREEN
    targeting_pointer.size = Vector2(15, 15)
    canvas_layer.add_child(targeting_pointer)
    
    print("Entering targeting mode for weapon: ", weapon_name)

func save_game(_round_number: int = -1):
    var save_data = {
        "player_stats": {
            "health": PlayerStats.health,
            "money": PlayerStats.money,
            "towers_available": PlayerStats.towers_available,
            "unlocked_weapons": PlayerStats.unlocked_weapons
        },
        "round_manager": {
            "current_round": round_manager.current_round_index,
            "enemy_health_bonus": round_manager.enemy_health_bonus
        },
        "towers": []
    }
    
    for tower in build_tower_node.get_children():
        if "current_direction" in tower:
            save_data["towers"].append({
                "position_x": tower.position.x,
                "position_y": tower.position.y,
                "direction": tower.current_direction,
                "equipped_weapons": tower.equipped_weapons
            })
        
    SaveManager.save_game(save_data)

func load_game():
    var save_data = SaveManager.load_game()
    if save_data.is_empty():
        return

    # Restore player stats
    PlayerStats.health = save_data["player_stats"]["health"]
    PlayerStats.money = save_data["player_stats"]["money"]
    PlayerStats.towers_available = save_data["player_stats"]["towers_available"]
    PlayerStats.unlocked_weapons = save_data["player_stats"].get("unlocked_weapons", [])
    PlayerStats.emit_signal("health_changed", PlayerStats.health)
    PlayerStats.emit_signal("money_changed", PlayerStats.money)
    PlayerStats.emit_signal("towers_changed", PlayerStats.towers_available)

    # Restore towers
    for tower_data in save_data["towers"]:
        var new_tower = caballero_scene.instantiate()
        new_tower.position = Vector2(tower_data["position_x"], tower_data["position_y"])
        new_tower.current_direction = tower_data["direction"]
        new_tower.equipped_weapons = tower_data.get("equipped_weapons", [])
        build_tower_node.add_child(new_tower)
        new_tower.call("_update_visuals")
        
    # Restore round
    round_manager.current_round_index = save_data["round_manager"]["current_round"]
    round_manager.enemy_health_bonus = save_data["round_manager"].get("enemy_health_bonus", 0)
    round_manager.start_prep_phase(round_manager.current_round_index)

func _on_no_health():
    var lose_screen = lose_screen_scene.instantiate()
    var canvas = CanvasLayer.new()
    canvas.add_child(lose_screen)
    add_child(canvas)
    get_tree().paused = true


func _on_start_placement_mode():
    placement_state = PlacementState.SELECTING_PLACEMENT
    shadow_tower = caballero_scene.instantiate()
    shadow_tower.set_process(false)
    shadow_tower.get_node("Area2D").collision_mask = 2
    shadow_tower.input_pickable = false
    add_child(shadow_tower)
    Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _process(_delta):
    if current_game_state == GameState.TARGETING_WEAPON:
        print("Processing in targeting mode. Mouse position: ", get_global_mouse_position())
        if targeting_pointer:
            targeting_pointer.global_position = get_global_mouse_position()

    if placement_state == PlacementState.SELECTING_PLACEMENT:
        shadow_tower.global_position = get_global_mouse_position()
        build_checker.global_position = get_global_mouse_position()
        
        # Check for BuildZone using BuildChecker
        var overlapping_areas = build_checker.get_overlapping_areas()
        var is_on_build_zone = false
        for area in overlapping_areas:
            if area == build_zone:
                is_on_build_zone = true
                break

        # Check for other towers using intersect_point
        var space_state = get_world_2d().direct_space_state
        var query = PhysicsPointQueryParameters2D.new()
        query.position = get_global_mouse_position()
        query.collision_mask = 1 # Only check for towers
        query.exclude = [shadow_tower] # Exclude the shadow tower itself
        var tower_result = space_state.intersect_point(query)
        var is_on_another_tower = not tower_result.is_empty()

        is_valid_position = is_on_build_zone and not is_on_another_tower
        
        if is_valid_position:
            shadow_tower.modulate = Color(0, 1, 0, 0.5)
        else:
            shadow_tower.modulate = Color(1, 0, 0, 0.5)

func _input(event):
    if current_game_state == GameState.TARGETING_WEAPON:
        print("Input event in targeting mode: ", event)
        if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            var space_state = get_world_2d().direct_space_state
            var query = PhysicsPointQueryParameters2D.new()
            query.position = get_global_mouse_position()
            query.collision_mask = 1 # Assumes towers are on physics layer 1
            var results = space_state.intersect_point(query)
            
            if not results.is_empty():
                var clicked_node = results[0].collider
                if clicked_node.has_method("add_weapon"):
                    clicked_node.add_weapon(weapon_to_apply)
                    
                    # Exit targeting mode
                    current_game_state = GameState.PLAYING
                    weapon_to_apply = ""
                    if targeting_pointer:
                        targeting_pointer.queue_free()
                        targeting_pointer = null
                    
                    # Unpause and continue the game
                    get_tree().paused = false
                    round_manager.start_round(round_manager.current_round_index)
                    return # Consume the input

    if placement_state == PlacementState.SELECTING_PLACEMENT:
        if event.is_action_pressed("rotate_tower"):
            if shadow_tower and shadow_tower.is_node_ready() and shadow_tower.get_node_or_null("AnimatedSprite2D"):
                var new_direction = (shadow_tower.current_direction + 1) % 4
                shadow_tower.current_direction = new_direction
                shadow_tower.call("_update_visuals")
        
        if event is InputEventMouseButton and event.pressed:
            if event.button_index == MOUSE_BUTTON_LEFT:
                if is_valid_position:
                    placement_sound_player.play()
                    var new_tower = caballero_scene.instantiate()
                    new_tower.global_position = shadow_tower.global_position
                    new_tower.current_direction = shadow_tower.current_direction
                    build_tower_node.add_child(new_tower)
                    new_tower.call("_update_visuals")
                    
                    PlayerStats.decrease_towers()
                    
                    placement_state = PlacementState.IDLE
                    shadow_tower.queue_free()
                    shadow_tower = null
                    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
            elif event.button_index == MOUSE_BUTTON_RIGHT:
                placement_state = PlacementState.IDLE
                shadow_tower.queue_free()
                shadow_tower = null
                Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
