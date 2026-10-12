@tool
extends "res://addons/wallop_lite/wallop_component.gd"
## Trauma-based camera shake for a [Camera3D].
##
## Same model as the 2D shake: trauma 0 to 1, shake = trauma ^ power, seeded
## noise. Position shake uses [member Camera3D.h_offset] and
## [member Camera3D.v_offset] (it moves the view, not the node), rotation shake
## is added to the camera's rotation and removed again, so your camera code
## keeps control.

signal settled

@export var camera: Camera3D
@export_range(0.0, 1.0) var trauma := 0.0
@export var decay := 1.2
@export_range(1.0, 4.0) var trauma_power := 2.0
## Largest view offset in metres at full trauma (x = horizontal, y = vertical).
@export var max_offset := Vector2(0.18, 0.12)
## Largest rotation in degrees at full trauma (pitch, yaw, roll).
@export var max_angles := Vector3(2.0, 2.0, 4.0)
@export var frequency := 18.0
@export var noise_seed := 1:
	set(value):
		noise_seed = value
		_noise.seed = value

var _noise := FastNoiseLite.new()
var _time := 0.0
var _applied_offset := Vector2.ZERO
var _applied_rot := Vector3.ZERO


func _init() -> void:
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.frequency = 1.0
	_noise.seed = noise_seed


func _ready() -> void:
	super._ready()
	if camera == null and get_parent() is Camera3D:
		camera = get_parent()


func add_trauma(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)


func get_shake() -> float:
	return pow(trauma, trauma_power)


## [code][Vector2 offset, Vector3 rotation_radians][/code] for the current time.
func sample() -> Array:
	var s := get_shake()
	var t := _time * frequency
	var off := Vector2(max_offset.x * s * _noise.get_noise_2d(t, 0.0),
		max_offset.y * s * _noise.get_noise_2d(t, 1000.0))
	var rot := Vector3(
		deg_to_rad(max_angles.x) * s * _noise.get_noise_2d(t, 2000.0),
		deg_to_rad(max_angles.y) * s * _noise.get_noise_2d(t, 3000.0),
		deg_to_rad(max_angles.z) * s * _noise.get_noise_2d(t, 4000.0))
	return [off, rot]


func step(delta: float) -> void:
	if camera == null:
		return
	var was_shaking := trauma > 0.0
	_time += delta
	var res := sample()
	var off: Vector2 = res[0]
	var rot: Vector3 = res[1]
	camera.h_offset += off.x - _applied_offset.x
	camera.v_offset += off.y - _applied_offset.y
	camera.rotation += rot - _applied_rot
	_applied_offset = off
	_applied_rot = rot
	trauma = maxf(trauma - decay * delta, 0.0)
	if was_shaking and trauma == 0.0:
		_clear()
		settled.emit()


func stop() -> void:
	trauma = 0.0
	_clear()


func _clear() -> void:
	if camera:
		camera.h_offset -= _applied_offset.x
		camera.v_offset -= _applied_offset.y
		camera.rotation -= _applied_rot
	_applied_offset = Vector2.ZERO
	_applied_rot = Vector3.ZERO


func _exit_tree() -> void:
	_clear()
