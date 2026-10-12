extends Node2D
## Wallop Lite demo: click or press Space for a hit, hold Shift for a heavy one.

@onready var shake: Node = $Camera2D/Shake
@onready var hit_stop: Node = $HitStop
@onready var box: ColorRect = $Box
@onready var info: Label = $UI/Info


func _unhandled_input(event: InputEvent) -> void:
	var pressed: bool = (event is InputEventMouseButton and event.pressed) or event.is_action_pressed("ui_accept")
	if not pressed:
		return
	var heavy := Input.is_key_pressed(KEY_SHIFT)
	shake.add_trauma(0.9 if heavy else 0.45)
	hit_stop.freeze(0.12 if heavy else 0.05)
	box.color = Color(1, 0.85, 0.4) if heavy else Color(0.95, 0.95, 0.95)


func _process(delta: float) -> void:
	box.rotation += delta * 1.5
	box.color = box.color.lerp(Color(0.18, 0.49, 0.36), minf(1.0, delta * 6.0))
	info.text = "Click or Space: hit   Shift: heavy hit\ntrauma %.2f   time scale %.2f" % [shake.trauma, Engine.time_scale]
