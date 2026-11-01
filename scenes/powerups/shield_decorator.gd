class_name ShieldDecorator
extends PowerupDecorator

## A one-hit shield over the fox. It runs until the shield has absorbed a hit; the manager then
## removes it (so the tint goes too).


const SHIELD := preload("res://scenes/powerups/shield.tscn")


var _shield: Shield


func on_apply() -> void:
	_shield = SHIELD.instantiate()
	fox.add_child(_shield)
	fox.current_shield = _shield


func on_remove() -> void:
	if fox.current_shield == _shield:
		fox.current_shield = null
	if is_instance_valid(_shield):
		_shield.queue_free()


## Done once the shield is spent (or gone).
func update(_delta: float) -> bool:
	return not is_instance_valid(_shield) or _shield.is_depleted
