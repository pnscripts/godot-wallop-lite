extends SceneTree
## Wallop Lite test runner.
##
##   godot --headless --path . -s tests/run_tests.gd
##
## Every test drives the components with fixed time steps through step(), so
## results do not depend on frame timing. Exit code 0 when all pass.

const Shake2D := preload("res://addons/wallop_lite/wallop_shake_2d.gd")
const Shake3D := preload("res://addons/wallop_lite/wallop_shake_3d.gd")
const HitStop := preload("res://addons/wallop_lite/wallop_hit_stop.gd")

const DT := 1.0 / 60.0

var _failures: Array[String] = []
var _checks := 0
var _passed := 0
var _failed := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var tests := [
		"test_shake_2d_same_seed_same_motion",
		"test_shake_2d_bounded_and_decays_to_rest",
		"test_shake_2d_keeps_external_offset",
		"test_shake_power_curve",
		"test_shake_3d_deterministic_and_restores",
		"test_hit_stop_freezes_and_restores",
		"test_hit_stop_overlap_and_slow_motion",
		"test_shake_stop_clears_immediately",
		"test_hit_stop_release_and_free_restore_scale",
		"test_plugin_files_present",
		"test_handles",
	]
	for t in tests:
		var before := _failures.size()
		call(t)
		_cleanup()
		if _failures.size() == before:
			_passed += 1
			print("ok   ", t)
		else:
			_failed += 1
			print("FAIL ", t)
			for f in _failures.slice(before):
				print("     ", f)
	print("")
	print("%d tests, %d passed, %d failed, %d checks" % [tests.size(), _passed, _failed, _checks])
	Engine.time_scale = 1.0
	quit(0 if _failed == 0 else 1)

func _cleanup() -> void:
	for c in root.get_children():
		root.remove_child(c)
		c.free()
	Engine.time_scale = 1.0


func check(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		_failures.append(msg)


func near(a: float, b: float, tol: float, msg: String) -> void:
	check(absf(a - b) <= tol, "%s: %s vs %s (tol %s)" % [msg, a, b, tol])


func add(n: Node) -> Node:
	root.add_child(n)
	return n


func make_shake_2d(seed: int) -> Node:
	var cam := Camera2D.new()
	add(cam)
	var s: Node = Shake2D.new()
	s.auto_process = false
	s.noise_seed = seed
	cam.add_child(s)
	return s


func test_shake_2d_same_seed_same_motion() -> void:
	var a := make_shake_2d(42)
	var b := make_shake_2d(42)
	var c := make_shake_2d(7)
	for s in [a, b, c]:
		s.add_trauma(0.8)
	var same := true
	var differs := false
	for i in 30:
		for s in [a, b, c]:
			s.step(DT)
		if a.camera.offset != b.camera.offset or a.camera.rotation != b.camera.rotation:
			same = false
		if a.camera.offset.distance_to(c.camera.offset) > 0.01:
			differs = true
	check(same, "same seed must give identical offsets")
	check(differs, "different seed must give different offsets")


func test_shake_2d_bounded_and_decays_to_rest() -> void:
	var s := make_shake_2d(3)
	s.decay = 1.0
	s.add_trauma(1.0)
	var settled := [false]
	s.settled.connect(func(): settled[0] = true)
	var biggest := 0.0
	var max_roll := 0.0
	for i in 54:  # 0.9 s
		s.step(DT)
		biggest = maxf(biggest, absf(s.camera.offset.x) / s.max_offset.x)
		biggest = maxf(biggest, absf(s.camera.offset.y) / s.max_offset.y)
		max_roll = maxf(max_roll, absf(s.camera.rotation))
	check(biggest <= 1.0001, "offset never exceeds max_offset (got %s)" % biggest)
	check(biggest > 0.2, "full trauma actually moves the camera (got %s)" % biggest)
	check(max_roll <= deg_to_rad(s.max_roll_degrees) + 1e-6, "roll bounded")
	check(not settled[0], "still shaking at 0.9 s")
	for i in 7:
		s.step(DT)
	near(s.trauma, 0.0, 1e-9, "trauma gone after 1 s at decay 1")
	check(settled[0], "settled signal fired")
	check(s.camera.offset.length() < 1e-4, "offset back to zero: %s" % s.camera.offset)
	near(s.camera.rotation, 0.0, 1e-6, "rotation back to zero")


func test_shake_2d_keeps_external_offset() -> void:
	var s := make_shake_2d(5)
	s.camera.offset = Vector2(100, 50)
	s.add_trauma(0.9)
	for i in 10:
		s.step(DT)
	s.camera.offset += Vector2(10, 0)  # game code moves the camera meanwhile
	for i in 120:
		s.step(DT)
	check(s.camera.offset.is_equal_approx(Vector2(110, 50)), "external offset kept: %s" % s.camera.offset)


func test_shake_power_curve() -> void:
	var s := make_shake_2d(1)
	s.trauma = 0.5
	s.trauma_power = 2.0
	near(s.get_shake(), 0.25, 1e-6, "shake = trauma^2")
	s.trauma_power = 3.0
	near(s.get_shake(), 0.125, 1e-6, "shake = trauma^3")
	s.trauma = 0.9
	s.add_trauma(0.5)
	near(s.trauma, 1.0, 1e-9, "trauma clamps at 1")


func test_shake_3d_deterministic_and_restores() -> void:
	var runs := []
	for r in 2:
		var cam := Camera3D.new()
		add(cam)
		cam.rotation = Vector3(0.1, 0.2, 0.0)
		var s: Node = Shake3D.new()
		s.auto_process = false
		s.noise_seed = 99
		cam.add_child(s)
		s.add_trauma(1.0)
		var trace := []
		for i in 20:
			s.step(DT)
			trace.append([cam.h_offset, cam.v_offset, cam.rotation])
		runs.append(trace)
		for i in 120:
			s.step(DT)
		near(cam.h_offset, 0.0, 1e-6, "h_offset restored")
		near(cam.v_offset, 0.0, 1e-6, "v_offset restored")
		check(cam.rotation.is_equal_approx(Vector3(0.1, 0.2, 0.0)), "rotation restored: %s" % cam.rotation)
	check(str(runs[0]) == str(runs[1]), "3D shake is deterministic for a seed")
	var moved := false
	for row in runs[0]:
		if absf(row[0]) > 0.01:
			moved = true
	check(moved, "3D shake moves the view")


func test_hit_stop_freezes_and_restores() -> void:
	var h: Node = add(HitStop.new())
	h.auto_process = false
	var events := []
	h.started.connect(func(): events.append("start"))
	h.finished.connect(func(): events.append("end"))
	h.freeze(0.1)
	near(Engine.time_scale, 0.0, 1e-9, "time scale 0 during freeze")
	check(h.is_active(), "active")
	for i in 5:
		h.step(DT)  # 0.083 s
	check(h.is_active(), "still frozen at 0.083 s")
	h.step(DT)
	check(not h.is_active(), "released after 0.1 s")
	near(Engine.time_scale, 1.0, 1e-9, "time scale back to 1")
	check(events == ["start", "end"], "signals: %s" % [events])


func test_hit_stop_overlap_and_slow_motion() -> void:
	Engine.time_scale = 0.5  # game is in slow motion already
	var h: Node = add(HitStop.new())
	h.auto_process = false
	h.freeze(0.05, 0.2)
	h.step(0.03)
	h.freeze(0.1, 0.05)  # longer, stronger hit lands during the first
	near(Engine.time_scale, 0.05, 1e-9, "lowest scale wins")
	near(h.get_remaining(), 0.1, 1e-9, "remaining extended to the longer freeze")
	h.step(0.09)
	check(h.is_active(), "still active")
	h.step(0.02)
	near(Engine.time_scale, 0.5, 1e-9, "restores the earlier slow motion, not 1")
	h.freeze(5.0)
	near(h.get_remaining(), h.max_duration, 1e-9, "duration capped")


func test_shake_stop_clears_immediately() -> void:
	var s := make_shake_2d(9)
	s.camera.offset = Vector2(5, 5)
	s.add_trauma(1.0)
	for i in 5:
		s.step(DT)
	check(s.camera.offset != Vector2(5, 5), "shaking")
	s.stop()
	check(s.camera.offset.is_equal_approx(Vector2(5, 5)), "stop() restores the offset at once")
	near(s.trauma, 0.0, 1e-9, "no trauma left")


func test_hit_stop_release_and_free_restore_scale() -> void:
	Engine.time_scale = 0.8
	var h: Node = add(HitStop.new())
	h.auto_process = false
	h.freeze(0.2, 0.1)
	h.release()
	near(Engine.time_scale, 0.8, 1e-9, "release() restores")
	h.freeze(0.2, 0.0)
	root.remove_child(h)
	h.free()
	near(Engine.time_scale, 0.8, 1e-9, "removing the node mid-freeze restores")
	var h2: Node = add(HitStop.new())
	h2.freeze(0.0)
	check(not h2.is_active() and Engine.time_scale == 0.8, "zero duration does nothing")


func test_plugin_files_present() -> void:
	var cfg := ConfigFile.new()
	check(cfg.load("res://addons/wallop_lite/plugin.cfg") == OK, "plugin.cfg loads")
	check(cfg.get_value("plugin", "script") == "plugin.gd", "plugin script set")
	check(cfg.get_value("plugin", "author") == "PN Scripts", "author")
	var src := FileAccess.get_file_as_string("res://addons/wallop_lite/plugin.gd")
	for t in ["WallopLiteShake2D", "WallopLiteShake3D", "WallopLiteHitStop"]:
		check(src.contains('"%s"' % t), "plugin registers " + t)
	for icon in ["shake", "hit_stop"]:
		check(FileAccess.file_exists("res://addons/wallop_lite/icons/%s.svg" % icon), "icon " + icon)
	check(FileAccess.file_exists("res://addons/wallop_lite/LICENSE.md"), "licence ships inside the addon folder")


func test_handles() -> void:
	check(WallopLite.Shake2D == Shake2D and WallopLite.HitStop == HitStop, "WallopLite handles")
	var cam := Camera2D.new()
	add(cam)
	var s: Node = Shake2D.new()
	cam.add_child(s)
	check(WallopLite.find(cam, Shake2D) == s, "find() returns the child")
	check(s.camera == cam, "parent Camera2D picked up automatically")
