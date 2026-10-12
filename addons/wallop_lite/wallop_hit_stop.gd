@tool
extends "res://addons/wallop_lite/wallop_component.gd"
## Hit-stop (freeze frames) through [member Engine.time_scale].
##
## [method freeze] drops the time scale for a short real-time duration and then
## restores whatever it was before (so it plays well with your own slow motion).
## Overlapping freezes extend to the longest end time and use the lowest scale.
## The countdown uses real time, so it ends even at time scale 0.

signal started
signal finished

## Time scale used by [method freeze] when none is given.
@export_range(0.0, 1.0) var default_scale := 0.0
## Longest freeze allowed, in seconds, to protect against stacking.
@export var max_duration := 0.4

var _remaining := 0.0
var _active := false
var _saved_scale := 1.0
var _scale := 1.0


func _ready() -> void:
	ignore_time_scale = true
	super._ready()


## Freeze (or slow) the game for [param duration] real seconds.
func freeze(duration: float, time_scale: float = -1.0) -> void:
	if time_scale < 0.0:
		time_scale = default_scale
	duration = minf(duration, max_duration)
	if duration <= 0.0:
		return
	if not _active:
		_saved_scale = Engine.time_scale
		_scale = time_scale
		_active = true
		started.emit()
	else:
		_scale = minf(_scale, time_scale)
	_remaining = maxf(_remaining, duration)
	Engine.time_scale = _scale


func is_active() -> bool:
	return _active


func get_remaining() -> float:
	return _remaining


func step(delta: float) -> void:
	if not _active:
		return
	_remaining -= delta
	if _remaining <= 1e-6:
		_release()


## End the freeze now.
func release() -> void:
	if _active:
		_release()


func _release() -> void:
	_remaining = 0.0
	_active = false
	Engine.time_scale = _saved_scale
	finished.emit()


func _exit_tree() -> void:
	if _active:
		_active = false
		Engine.time_scale = _saved_scale
