class_name Player
extends BaseCharacter


## Seconds of invulnerability after a shield absorbs a hit, and how long one blink takes.
const SHIELD_GRACE := 1.0
const BLINK_PERIOD := 0.2

var decorator_manager: DecoratorManager

## Emitted once the Dead state has played out. GameManager hooks it up to respawn() when the fox's
## stage registers; a scene that isn't a stage connects it itself (tests/test.gd restarts the yard).
signal died

## Turned on throughout the Hurt state so one hit doesn't drain health every single frame in a row.
var is_invulnerable: bool = false

var current_shield: Shield

## The thing currently being carried overhead; null when empty-handed. Kept on Player rather than
## on the Carry state, so other states (and any other code) can ask "is the fox holding anything".
var held: BaseCharacter = null

## True while a conversation runs: F then advances the dialogue instead of interacting again.
var is_talking: bool = false

@onready var hold_point: Marker3D = $HoldPoint
@onready var grab_area: Area3D = $Direction/GrabArea3D


func _ready() -> void:
	fsm = FSM.new(self, $States, $States/Idle)
	decorator_manager = DecoratorManager.new()
	decorator_manager.name = "DecoratorManager"
	add_child(decorator_manager)
	$Direction/HurtArea3D.hurt.connect(_on_hurt_area_3d_hurt)
	super._ready()


## Every state of the fox can take damage, so this calls straight into the current state; whichever
## state doesn't want to lose health (Dead) overrides take_damage().
func _on_hurt_area_3d_hurt(_direction: Vector3, damage: float) -> void:
	if is_invulnerable:
		return
	
	if is_instance_valid(current_shield) and not current_shield.is_depleted:
		current_shield.absorb()    # the decorator sees it is spent and the manager removes it
		current_shield = null
		_start_grace(SHIELD_GRACE)
		return

	fsm.current_state.take_damage(int(damage))


## Invulnerable for `seconds`, with the sprite blinking so the player can see it. No await: the
## handler never suspends, so a freed fox can't resume a dead coroutine.
func _start_grace(seconds: float) -> void:
	is_invulnerable = true
	var blink := sprite.create_tween().set_loops(maxi(1, roundi(seconds / BLINK_PERIOD)))
	blink.tween_property(sprite, "modulate:a", 0.3, BLINK_PERIOD / 2.0)
	blink.tween_property(sprite, "modulate:a", 1.0, BLINK_PERIOD / 2.0)
	get_tree().create_timer(seconds).timeout.connect(func() -> void:
		is_invulnerable = false
	)


## The nearest pickable thing inside GrabArea3D, or null if there's none. GrabArea3D sits under
## Direction so it's always on the side the fox is facing — no need to enable/disable it per
## direction.
func find_carryable() -> BaseCharacter:
	var nearest: BaseCharacter = null
	var nearest_distance := INF
	for body: Node3D in grab_area.get_overlapping_bodies():
		if not (body is BaseCharacter and body.can_be_carried()):
			continue
		var distance := global_position.distance_squared_to(body.global_position)
		if distance < nearest_distance:
			nearest = body
			nearest_distance = distance
	return nearest


## Dies on the spot, whatever the health — e.g. falling into the sea (KillZone).
func die() -> void:
	health = 0
	fsm.change_state(fsm.states.dead)


## Whether the fox may use an InteractiveArea3D right now: alive, and not already talking.
func can_interact() -> bool:
	return health > 0 and not is_talking


## On top of BaseCharacter's: from now on F belongs to the dialogue (can_interact() is false).
## is_talking goes on BEFORE the state change.
func start_talk(listener: Node3D = null) -> void:
	is_talking = true
	super(listener)


## On top of BaseCharacter's: F interacts again. A fox hit mid-dialogue is in Hurt, not Talk — Hurt
## then sees is_talking off and returns to Idle by itself.
func finish_talk() -> void:
	is_talking = false
	super()

## Runs `multiplier` times faster for `seconds` seconds.
func speed_up(multiplier: float, seconds: float) -> void:
	movement_speed *= multiplier
	await get_tree().create_timer(seconds).timeout
	movement_speed /= multiplier


## movement_speed as the running power-ups change it.
func get_movement_speed() -> float:
	return decorator_manager.get_effective_speed(movement_speed)


## attack_damage as the running power-ups change it.
func get_attack_damage() -> int:
	return decorator_manager.get_effective_damage(attack_damage)

