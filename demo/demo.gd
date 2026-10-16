extends Node2D
## Wallop Lite demo: click, tap or press Space to hit the bag; hold Shift (or put down a second finger) for a heavy hit.
## Everything that moves the camera or stops time is Wallop Lite; the bag, flash and sparks are plain demo drawing.

@onready var shake: Node = $Camera2D/Shake
@onready var hit_stop: Node = $HitStop
@onready var info: Label = $UI/Info

var swing := 0.0        # bag angle (radians), springs back
var swing_speed := 0.0
var flash := 0.0        # white hit flash on the bag, fades out
var hits := 0
var sparks: CPUParticles2D
var touches := 0


func _ready() -> void:
	sparks = CPUParticles2D.new()
	sparks.emitting = false
	sparks.one_shot = true
	sparks.explosiveness = 1.0
	sparks.amount = 28
	sparks.lifetime = 0.45
	sparks.direction = Vector2(-1, -0.2)
	sparks.spread = 70.0
	sparks.initial_velocity_min = 260.0
	sparks.initial_velocity_max = 620.0
	sparks.gravity = Vector2(0, 900)
	sparks.scale_amount_min = 3.0
	sparks.scale_amount_max = 6.0
	sparks.color = Color(1.0, 0.86, 0.45)
	sparks.position = Vector2(560, 380)
	add_child(sparks)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		touches += 1 if event.pressed else -1
		if event.pressed:
			hit(touches >= 2)
		return
	# Taps also arrive as emulated mouse clicks (device -1); count them once, as touches.
	var pressed: bool = (event is InputEventMouseButton and event.pressed and event.device != InputEvent.DEVICE_ID_EMULATION) or event.is_action_pressed("ui_accept")
	if pressed:
		hit(Input.is_key_pressed(KEY_SHIFT))


func hit(heavy: bool) -> void:
	hits += 1
	shake.add_trauma(0.9 if heavy else 0.45)
	hit_stop.freeze(0.12 if heavy else 0.05)
	swing_speed -= 7.0 if heavy else 4.0
	flash = 1.0
	sparks.amount = 44 if heavy else 28
	sparks.restart()


func _process(delta: float) -> void:
	# The bag springs back on unscaled time, so it settles even while the hit-stop holds the world.
	var real := delta / maxf(Engine.time_scale, 0.001)
	swing_speed += (-swing * 40.0 - swing_speed * 5.0) * real
	swing += swing_speed * real
	flash = maxf(0.0, flash - real * 6.0)
	info.text = "Click, tap or Space: hit   Shift or a second finger: heavy hit   hits %d" % hits
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 560, 1280, 160), Color(0.13, 0.16, 0.2))
	draw_line(Vector2(640, 70), Vector2(640, 120), Color(0.55, 0.6, 0.66), 4.0)
	draw_set_transform(Vector2(640, 120), swing * 0.35)
	var bag := Rect2(-70, 0, 140, 330)
	draw_rect(bag, Color(0.72, 0.27, 0.22).lerp(Color.WHITE, flash * 0.8))
	draw_rect(Rect2(-70, 40, 140, 14), Color(0.3, 0.12, 0.1))
	draw_rect(Rect2(-70, 270, 140, 14), Color(0.3, 0.12, 0.1))
	draw_set_transform(Vector2.ZERO)
	_meter(Vector2(40, 600), "trauma", shake.trauma, Color(0.96, 0.66, 0.26))
	_meter(Vector2(40, 650), "time scale", Engine.time_scale, Color(0.45, 0.8, 0.6))


func _meter(at: Vector2, label: String, value: float, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, at + Vector2(0, 18), label, HORIZONTAL_ALIGNMENT_LEFT, 140, 20, Color(0.8, 0.84, 0.88))
	draw_rect(Rect2(at + Vector2(150, 2), Vector2(360, 18)), Color(0.22, 0.26, 0.32))
	draw_rect(Rect2(at + Vector2(150, 2), Vector2(360 * clampf(value, 0.0, 1.0), 18)), color)
	draw_string(ThemeDB.fallback_font, at + Vector2(530, 18), "%.2f" % value, HORIZONTAL_ALIGNMENT_LEFT, 80, 20, Color(0.8, 0.84, 0.88))
