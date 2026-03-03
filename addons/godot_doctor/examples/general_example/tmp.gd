@tool
extends EditorScript


# Called when the node enters the scene tree for the first time.
func _run() -> void:
	get_editor_interface().get_edited_scene_root().print_tree_pretty()
