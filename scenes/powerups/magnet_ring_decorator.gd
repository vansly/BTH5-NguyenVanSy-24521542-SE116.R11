class_name MagnetRingDecorator
extends PowerupDecorator


const MAGNET_RING := preload("res://scenes/powerups/magnet_ring.tscn")


var _ring: Area3D


func on_apply() -> void:
	_ring = MAGNET_RING.instantiate()
	fox.add_child(_ring)


func on_remove() -> void:
	if is_instance_valid(_ring):
		_ring.queue_free()

