class_name Shield
extends Node3D

## One-hit shield carried by the fox. absorb() uses it up.

signal shield_depleted

var is_depleted: bool = false


## Soaks up one hit: from now on the shield is spent.
func absorb() -> void:
	if is_depleted:
		return
	is_depleted = true
	shield_depleted.emit()
