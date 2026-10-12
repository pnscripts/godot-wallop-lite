GODOT ?= godot
.PHONY: test images
test:
	$(GODOT) --headless --path . --import >/dev/null 2>&1 || true
	$(GODOT) --headless --path . -s tests/run_tests.gd
images:
	node tools/render.mjs tools/images.mjs
