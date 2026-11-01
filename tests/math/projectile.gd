extends Node3D
class_name Projectile
## A ball fired from where it stands, `angle` degrees above the horizontal toward +X, at `speed` m/s;
## gravity pulls it down. Space (`jump`) fires it, again and again. Its physics is stepped by hand,
## `step_time` seconds at a time:
##   velocity.y -= gravity · dt        position += velocity · dt
## The smaller the step, the closer it follows the exact parabola y = y0 + vy·t − ½·g·t², which
## TrajectoryPreview draws.

@export var speed := 15.0:
	set(value):
		if value != speed:
			speed = value
			speed_changed.emit()
			
@export_range(0.0, 90.0) var angle :  float = 45.0:
	set(value):
		if value != angle:
			angle = value
			angle_changed.emit()

@export var gravity := 24.0:
	set(value):
		if value != gravity:
			gravity = value
			gravity_changed.emit()
			

## Seconds per step. Try 0.1, 0.02, 0.001 and compare with the drawn path.
@export_range(0.001, 0.5, 0.001) var step_time := 0.02

var max_height: float = 0.0

## The smallest step it takes, whatever step_time says.
const MIN_STEP := 0.001

var velocity := Vector3.ZERO
var flying := false

var _start := Vector3.ZERO
## Frame time not stepped yet: a frame rarely holds a whole number of steps.
var _left_over := 0.0


signal angle_changed()
signal speed_changed()
signal gravity_changed()

func _ready() -> void:
	_start = position


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		launch()


## Back to the launch point, then off: velocity = (cos a, sin a, 0) · speed.
func launch() -> void:
	position = _start
	var a := deg_to_rad(angle)
	velocity = Vector3(cos(a), sin(a), 0.0) * speed
	flying = true
	_left_over = 0.0
	


func _physics_process(delta: float) -> void:
	if not flying:
		return
	_left_over += delta
	var dt := maxf(step_time, MIN_STEP)    # a step of 0 would never use up the frame
	while flying and _left_over >= dt:
		_left_over -= dt
		step(dt)


## One step of `dt` seconds. Once back down at the launch height it stops there.
func step(dt: float) -> void:
	if not flying:
		return
	velocity.y -= gravity * dt
	position += velocity * dt
	if position.y <= _start.y:
		position.y = _start.y
		flying = false
		print("Firing angle (deg): ", rad_to_deg(calculate_angle_in_rad(_start, position, speed, gravity, true)))
		print("Angle (deg): ", angle)

func calculate_angle_in_rad(start: Vector3, land: Vector3, v: float, g: float, use_low_arc: bool) -> float:
	if start.is_equal_approx(land):
		return NAN

	var diff: Vector3 = land - start
	var y: float = diff.y
	diff.y = 0.0
	var x: float = diff.length()

	if x == 0.0:
		return PI / 2.0 if y > 0 else -PI / 2.0


	if is_zero_approx(g):
		push_warning("Gravity is zero: use atan2(y, x) for a straight shot.")
		return atan2(y, x)

	var x2: float = x * x
	var v2: float = v * v
	var v4: float = v2 * v2

	var root: float = v4 - g * (g * x2 + 2.0 * y * v2)

	# Rounding right at maximum range (e.g. 45° when y = 0) can give a tiny negative root
	if root < 0.0 and root > -1e-4 * v4:
		root = 0.0

	if root < 0.0:
		push_warning("Landing spot is out of range!")
		return NAN

	var root_sqrt := sqrt(root)
	var tan_a: float

	if use_low_arc:
		tan_a = (v2 - root_sqrt) / (g * x)
	else:
		tan_a = (v2 + root_sqrt) / (g * x)

	return atan(tan_a)