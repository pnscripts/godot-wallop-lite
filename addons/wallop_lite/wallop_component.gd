@tool
extends Node
## Shared base for Wallop Lite components.
##
## Every component does its work in [method step], which [method _process] calls
## once per frame. Tests and custom loops can call [method step] directly with a
## fixed delta, which makes all effects deterministic.

## Keep animating while [member Engine.time_scale] is changed (for example
## during hit-stop). Uses real elapsed time instead of the scaled frame delta.
@export var ignore_time_scale := true
## Let the component advance itself every frame. Turn off to drive it yourself
## with [method step].
@export var auto_process := true

var _last_ticks := -1


func _ready() -> void:
	if ignore_time_scale:
		process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or not auto_process:
		return
	var dt := delta
	if ignore_time_scale:
		dt = unscaled_delta(delta)
	step(dt)


## Frame time without [member Engine.time_scale]. In Movie Maker mode the
## recording clock is used instead of the wall clock, so recorded videos show
## the same timing as live play.
func unscaled_delta(delta: float) -> float:
	if Engine.get_write_movie_path() != "":
		if Engine.time_scale > 0.0:
			return delta / Engine.time_scale
		return 1.0 / float(ProjectSettings.get_setting("editor/movie_writer/fps", 60))
	return _real_delta()


func _real_delta() -> float:
	var now := Time.get_ticks_usec()
	var dt := 0.0
	if _last_ticks >= 0:
		dt = float(now - _last_ticks) / 1000000.0
	_last_ticks = now
	return minf(dt, 0.1)


## Advance the effect by [param delta] seconds. Override in components.
func step(_delta: float) -> void:
	pass
