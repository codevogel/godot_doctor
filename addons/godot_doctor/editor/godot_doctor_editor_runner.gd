## A [GodotDoctorRunner] that validates the currently open scene and inspected resource
## in the Godot editor. Triggered automatically on save (if configured) or manually.
class_name GodotDoctorEditorRunner
extends GodotDoctorRunner

## Emitted when a validation run starts for [param scene_root] in the editor.
signal started_run_for_edited_scene_root(scene_root: Node)
## Emitted when a validation run finishes for [param scene_root] in the editor.
signal finished_run_for_edited_scene_root(scene_root: Node)

## Emitted when a validation run starts for the resource open in the inspector.
signal started_run_for_edited_resource
## Emitted when a validation run finishes for the resource open in the inspector.
signal finished_run_for_edited_resource

signal run_for_edited_scene_root_requested


## Runs validation for the currently open scene root and the resource open in the inspector.
func _run() -> void:
	_run_for_edited_scene_root()
	_run_for_edited_resource()


## Validates the scene root currently open in the editor.
## Emits scene collection signals around the validation run.
func _run_for_edited_scene_root() -> void:
	run_for_edited_scene_root_requested.emit()
	var current_edited_scene_root: Node = EditorInterface.get_edited_scene_root()
	if current_edited_scene_root == null:
		GodotDoctorNotifier.print_debug(
			"No current edited scene root. Skipping scene validation.", self
		)
		return

	started_run_for_edited_scene_root.emit(current_edited_scene_root)

	started_scene_collection.emit()

	var current_edited_scene_res_path: String = GodotDoctorResourceHelper.to_res_path(
		current_edited_scene_root.scene_file_path
	)
	started_run_for_scene_res_path.emit(current_edited_scene_res_path)

	started_node_collection.emit()

	_validator.validate_scene_root(current_edited_scene_root)

	finished_node_collection.emit()

	finished_run_for_scene_res_path.emit(current_edited_scene_res_path)

	finished_scene_collection.emit()

	finished_run_for_edited_scene_root.emit(current_edited_scene_root)


## Validates the resource currently open in the inspector, if it has a script.
## Emits resource collection signals around the validation run.
func _run_for_edited_resource() -> void:
	var edited_object: Object = EditorInterface.get_inspector().get_edited_object()
	if not edited_object is Resource:
		GodotDoctorNotifier.print_debug(
			"Edited object %s is not a Resource. Skipping resource validation." % edited_object,
			self
		)
		return
	var edited_resource: Resource = edited_object as Resource
	var edited_resource_script: Script = edited_resource.get_script()
	if edited_resource_script == null:
		GodotDoctorNotifier.print_debug(
			"Edited resource %s has no script. Skipping resource validation." % edited_resource,
			self
		)
		return

	started_run_for_edited_resource.emit()

	started_run_for_resource.emit(edited_resource)

	started_resource_collection.emit()

	started_run_for_resource.emit(edited_resource)

	_validator.validate_resource(edited_resource)

	finished_run_for_resource.emit(edited_resource)

	finished_resource_collection.emit()

	finished_run_for_resource.emit(edited_resource)

	finished_run_for_edited_resource.emit()
