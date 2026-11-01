extends Pickup


@export var max_follow_speed: float = 20.0
@export var acceleration := 40.0

var is_following_player: bool = false
var speed: float = 0.0
var target: Node3D

## One coin.
func _collect(_fox: Player) -> void:
	is_following_player = false
	Inventory.add_coin(1)
	EventBus.item_collected.emit("coin", 1)
	
	
func set_follow_player(value: bool, player: Node3D):
	if value:
		target = player
	else:
		target = null
		speed = 0.0
	is_following_player = value

func _physics_process(delta: float) -> void:
	# Not following, or the player is gone: stay put.
	if not is_following_player or not is_instance_valid(target):
		return
	speed = move_toward(speed, max_follow_speed, acceleration * delta)
	# Constant-speed pull (m/s), independent of frame rate, that reaches the player.
	global_position = global_position.move_toward(target.global_position, speed * delta)
	
func get_is_following() -> bool:
	return is_following_player