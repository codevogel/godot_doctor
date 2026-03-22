## Validation reporter for the Godot Editor.
## Displays results as toasts and pushes them to the [GodotDoctorDock].
class_name GodotDoctorEditorValidationReporter
extends GodotDoctorValidationReporter

## Path to the dock scene instantiated by this reporter.
const DOCK_SCENE_PATH: String = "res://addons/godot_doctor/editor/dock/godot_doctor_dock.tscn"

## The [GodotDoctorDock] that validation messages are pushed to.
var _dock: GodotDoctorDock


## Initializes this reporter and adds the [GodotDoctorDock] to the editor layout
## at the position defined by [member GodotDoctorSettings.default_dock_position].
func _init() -> void:
	GodotDoctorNotifier.print_debug("Adding dock to editor", self)
	_dock = preload(DOCK_SCENE_PATH).instantiate() as GodotDoctorDock

	GodotDoctorPlugin.instance.add_control_to_dock(
		GodotDoctorPlugin.instance.settings.default_dock_position, _dock
	)


## Called when a validation run starts for [param scene_root].
## Clears the dock and sets the active scene root for validation display.
func on_started_run_for_edited_scene_root(scene_root: Node) -> void:
	_dock.scene_root_for_validations = scene_root


## Called when a validation run finishes for [param _scene_root].
func on_finished_run_for_edited_scene_root(_scene_root: Node) -> void:
	# No action needed
	pass


## Called when a validation run starts for the edited resource.
func on_started_run_for_edited_resource() -> void:
	# No action needed
	pass


## Called when a validation run finishes for the edited resource.
func on_finished_run_for_edited_resource() -> void:
	# No action needed
	pass


## Called when a validation run is requested for the edited scene root.
func on_run_for_edited_scene_root_requested() -> void:
	_dock.clear_errors()


## Reports validation results from [param scene_validation_collection] to the dock.
func report_on_scene_validation_collection(
	scene_validation_collection: GodotDoctorSceneValidationCollection
) -> void:
	if scene_validation_collection == null:
		push_error("Scene validation collection called with a null collection.")
		GodotDoctorPlugin.instance.quit_with_fail_early_if_headless()
		return

	var scene_path_to_node_validation_collection_map: Dictionary = (
		scene_validation_collection.get_scene_path_to_node_validation_collection_map()
	)

	for scene_path: String in scene_path_to_node_validation_collection_map.keys():
		#gdlint: ignore=max-line-length
		var node_validation_collection: GodotDoctorNodeValidationCollection = scene_path_to_node_validation_collection_map[scene_path]
		var node_ancestor_path_to_validation_messages_map: Dictionary = (
			node_validation_collection.get_node_ancestor_path_to_validation_messages_map()
		)
		for node_ancestor_path: String in node_ancestor_path_to_validation_messages_map.keys():
			var messages: Array = node_ancestor_path_to_validation_messages_map[node_ancestor_path]
			report_node_messages(node_ancestor_path, messages)


## Reports validation results from [param resource_validation_collection] to the dock.
func report_on_resource_validation_collection(
	resource_validation_collection: GodotDoctorResourceValidationCollection
) -> void:
	if resource_validation_collection == null:
		push_error("Resource validation collection called with a null collection.")
		GodotDoctorPlugin.instance.quit_with_fail_early_if_headless()
		return

	var resource_path_to_validation_messages_map: Dictionary = (
		resource_validation_collection.get_resource_path_to_validation_messages_map()
	)

	for resource_path: String in resource_path_to_validation_messages_map.keys():
		var messages: Array = resource_path_to_validation_messages_map[resource_path]
		report_resource_messages(resource_path, messages)


## Pushes a toast notification and adds each message in [param messages] to the dock
## as a node warning associated with [param node].
func report_node_messages(
	node_ancestor_path: String, messages: Array[GodotDoctorValidationMessage]
) -> void:
	GodotDoctorNotifier.print_debug(
		"Reporting %s messages for node: %s" % [messages.size(), node_ancestor_path], self
	)
	if messages.is_empty():
		GodotDoctorNotifier.print_debug(
			"No messages to report for node: %s" % node_ancestor_path, self
		)
		return

	var num_messages: int = messages.size()

	var promoted_severity_levels: Array = messages.map(
		func(msg: GodotDoctorValidationMessage) -> int:
			return promoted_severity_level(
				GodotDoctorPlugin.instance.settings.treat_warnings_as_errors, msg.severity_level
			)
	)
	var toast_severity_level: int = promoted_severity_levels.max()

	GodotDoctorNotifier.push_toast(
		"Found %s validation message(s) in %s." % [num_messages, node_ancestor_path],
		toast_severity_level
	)

	for msg in messages:
		_dock.add_node_validation_message(node_ancestor_path, msg)


## Pushes a toast notification and adds each message in [param messages] to the dock
## as a resource warning associated with [param resource].
func report_resource_messages(
	resource_path: String, messages: Array[GodotDoctorValidationMessage]
) -> void:
	GodotDoctorNotifier.print_debug(
		"Reporting %s messages for resource: %s" % [messages.size(), resource_path], self
	)
	if messages.is_empty():
		GodotDoctorNotifier.print_debug(
			"No messages to report for resource: %s" % resource_path, self
		)
		return

	var num_messages: int = messages.size()

	var promoted_severity_levels: Array[ValidationCondition.Severity] = (
		GodotDoctorValidationMessage
		. map_to_promoted_severity_levels(
			GodotDoctorPlugin.instance.settings.treat_warnings_as_errors, messages
		)
	)

	var toast_severity_level: int = promoted_severity_levels.max()

	GodotDoctorNotifier.push_toast(
		"Found %s validation message(s) in %s." % [num_messages, resource_path],
		toast_severity_level
	)

	for msg in messages:
		_dock.add_resource_validation_message(resource_path, msg)


func teardown() -> void:
	GodotDoctorNotifier.print_debug("Tearing down editor validation reporter.", self)
	GodotDoctorNotifier.print_debug("Removing dock from editor and freeing it.", self)
	GodotDoctorPlugin.instance.remove_control_from_docks(_dock)
	_dock.queue_free()
	_dock = null


## Promotes [param severity_level] to [constant ValidationCondition.Severity.ERROR]
## if [param treat_warnings_as_errors] is [code]true[/code] and the severity is
## [constant ValidationCondition.Severity.WARNING].
## Returns the (possibly promoted) severity level as an [int].
static func promoted_severity_level(
	treat_warnings_as_errors: bool, severity_level: ValidationCondition.Severity
) -> int:
	if treat_warnings_as_errors and severity_level == ValidationCondition.Severity.WARNING:
		return ValidationCondition.Severity.ERROR
	return severity_level
