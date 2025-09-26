@tool
extends EditorPlugin

const VALIDATION_GLOBAL_NAME := "Validation"
const VALIDATION_GLOBAL_PATH := "res://addons/validator/globals/validation.gd"
const VALIDATING_METHOD_NAME := "_get_validation_conditions"
var current_edited_scene_root: Node = null


func _enable_plugin() -> void:
	print("[VALIDATOR] Enabling plugin...")
	# Add autoloads here.
	add_autoload_singleton(VALIDATION_GLOBAL_NAME, VALIDATION_GLOBAL_PATH)
	scene_changed.connect(_on_scene_changed)
	scene_closed.connect(_on_scene_closed)
	current_edited_scene_root = get_editor_interface().get_edited_scene_root()


func _disable_plugin() -> void:
	print("[VALIDATOR] Disabling plugin...")
	# Remove autoloads here.
	remove_autoload_singleton(VALIDATION_GLOBAL_NAME)
	if scene_changed.is_connected(_on_scene_changed):
		scene_changed.disconnect(_on_scene_changed)
	if scene_closed.is_connected(_on_scene_closed):
		scene_closed.disconnect(_on_scene_closed)


func _on_scene_changed(scene_root: Node) -> void:
	print("[VALIDATOR] Scene changed.")
	current_edited_scene_root = scene_root
	if is_instance_valid(current_edited_scene_root):
		print("[VALIDATOR] notifying property list changed.")
		current_edited_scene_root.notify_property_list_changed()


func _on_scene_closed(file_path: String) -> void:
	print("[VALIDATOR] Scene closed.")
	current_edited_scene_root = null
	update_overlays.call_deferred()


func get_configuration_warnings() -> PackedStringArray:
	print("[VALIDATOR] Getting configuration warnings...")
	if not Engine.is_editor_hint() or not is_instance_valid(current_edited_scene_root):
		return []

	var all_errors: PackedStringArray = []
	var nodes_to_validate: Array = _find_nodes_to_validate_in_tree(current_edited_scene_root)

	for node: Node in nodes_to_validate:
		if not node.has_method(VALIDATING_METHOD_NAME):
			push_error("Node %s does not have method %s" % [node.name, VALIDATING_METHOD_NAME])
			continue

		var conditions: Array[ValidationCondition] = node.call(VALIDATING_METHOD_NAME)

		if typeof(conditions) != TYPE_ARRAY:
			push_error(
				(
					"Node %s method %s must return an Array of ValidationCondition"
					% [node.name, VALIDATING_METHOD_NAME]
				)
			)
			continue

		var validation_result: ValidationResult = ValidationResult.new(conditions)
		if not validation_result.ok:
			all_errors.append_array(validation_result.errors)
	print("[VALIDATOR] Found %d validation errors." % all_errors.size())
	return all_errors


func _find_nodes_to_validate_in_tree(node: Node) -> Array:
	var nodes_to_validate: Array = []

	if node.has_method(VALIDATING_METHOD_NAME):
		nodes_to_validate.append(node)

	for child in node.get_children():
		nodes_to_validate.append_array(_find_nodes_to_validate_in_tree(child))
	return nodes_to_validate


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	pass


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	pass
