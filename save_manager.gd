extends Node

const SAVE_PATH = "user://savegame.dat"

func save_game(data: Dictionary):
    var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    file.store_var(data)
    file.close()

func load_game() -> Dictionary:
    if not has_save():
        return {}
    
    var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
    var data = file.get_var()
    file.close()
    return data

func has_save() -> bool:
    return FileAccess.file_exists(SAVE_PATH)

func delete_save():
    if has_save():
        DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
