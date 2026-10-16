extends Node
## Copyright (c) 2026 PN Scripts. MIT licence.
## Test-only probe (not shipped): demo state for the browser console, every 20 ms of real time.
var last := 0
func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec()
	if now - last < 20:
		return
	last = now
	var d := get_tree().current_scene
	print("PROBE hits=%d trauma=%.2f scale=%.2f offset=%.1f" % [d.hits, d.shake.trauma, Engine.time_scale, (d.get_node("Camera2D") as Camera2D).offset.length()])
