extends Node

var health: int = 100
var towers_available: int = 2
var money: int = 0
var unlocked_weapons: Array = []

signal health_changed(new_health)
signal no_health
signal towers_changed(new_towers)
signal money_changed(new_money)

func decrease_health(amount: int):
    health -= amount
    if health < 0:
        health = 0
    emit_signal("health_changed", health)
    if health == 0:
        emit_signal("no_health")

func decrease_towers():
    towers_available -= 1
    emit_signal("towers_changed", towers_available)

func increase_towers():
    towers_available += 1
    emit_signal("towers_changed", towers_available)

func can_place_tower() -> bool:
    return towers_available > 0

func add_money(amount: int):
    money += amount
    emit_signal("money_changed", money)

func spend_money(amount: int) -> bool:
    if money >= amount:
        money -= amount
        emit_signal("money_changed", money)
        return true
    else:
        return false

func unlock_weapon(weapon_name: String):
    if not unlocked_weapons.has(weapon_name):
        unlocked_weapons.append(weapon_name)
        print("Unlocked: ", weapon_name)

func reset():
    health = 100
    towers_available = 2
    money = 0
    unlocked_weapons.clear()
    emit_signal("health_changed", health)
    emit_signal("towers_changed", towers_available)
    emit_signal("money_changed", money)
