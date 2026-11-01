extends Area3D

var atractted_coins: Array = []

## Pull radius in meters. Can be changed at any time (e.g. by the decorator or its data).
@export_range(1.0, 10.0, 0.1) var collect_radius: float = 5.0:
	set(value):
		collect_radius = value
		_apply_radius()

@onready var collision: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	# The scene's shape is a resource shared by every instance: give this ring its own copy.
	collision.shape = collision.shape.duplicate()
	_apply_radius()


func _apply_radius() -> void:
	# The setter can run before the node is ready (exports are set at instantiate).
	if collision != null and collision.shape is CylinderShape3D:
		collision.shape.radius = collect_radius


func _on_area_entered(area: Area3D) -> void:
	if area.has_method("get_is_following") and area.has_method("set_follow_player"):
		if area.get_is_following():
			return #already following
		var player = self.get_parent()
		if not player:
			return
		area.set_follow_player(true, player)
		atractted_coins.append(area)

func _on_area_exited(area: Area3D) -> void:
	if area.has_method("get_is_following") and area.has_method("set_follow_player"):
		if not area.get_is_following():
			return #not following
		area.set_follow_player(false, null) #does not need to pass player
		atractted_coins.erase(area)
	
func clear_list() ->void:
	for area in atractted_coins:
		if not is_instance_valid(area):
			continue
		area.set_follow_player(false)
			
func _exit_tree() -> void:
	clear_list()