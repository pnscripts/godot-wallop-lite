@tool
extends EditorPlugin
## Registers the Wallop Lite nodes in the Create Node dialog.

const TYPES := [
	["WallopLiteShake2D", "Node", "wallop_shake_2d.gd", "shake.svg"],
	["WallopLiteShake3D", "Node", "wallop_shake_3d.gd", "shake.svg"],
	["WallopLiteHitStop", "Node", "wallop_hit_stop.gd", "hit_stop.svg"],
]


func _enter_tree() -> void:
	var base: String = get_script().resource_path.get_base_dir()
	for t in TYPES:
		add_custom_type(t[0], t[1], load(base + "/" + t[2]), load(base + "/icons/" + t[3]))


func _exit_tree() -> void:
	for t in TYPES:
		remove_custom_type(t[0])
