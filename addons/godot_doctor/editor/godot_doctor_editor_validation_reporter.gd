## Validation reporter for the Godot Editor.
## Displays results as toasts and pushes them to the Godot Doctor dock.
class_name GodotDoctorEditorValidationReporter
extends GodotDoctorValidationReporter

## The [GodotDoctorDock] that validation messages are pushed to.
var _dock: GodotDoctorDock


## Initializes the reporter with [param dock] as the target [GodotDoctorDock].
func _init(dock: GodotDoctorDock) -> void:
	_dock = dock


## Pushes a toast notification and adds each message in [param messages] to the dock
## as a node warning associated with [param node].
func report_node_messages(node: Node, messages: Array[GodotDoctorValidationMessage]) -> void:
	if messages.is_empty():
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
		"Found %s validation message(s) in %s." % [num_messages, node.name], toast_severity_level
	)

	for msg in messages:
		_dock.add_node_warning_to_dock(node, msg)


## Pushes a toast notification and adds each message in [param messages] to the dock
## as a resource warning associated with [param resource].
func report_resource_messages(
	resource: Resource, messages: Array[GodotDoctorValidationMessage]
) -> void:
	if messages.is_empty():
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
		"Found %s validation message(s) in %s." % [num_messages, resource.resource_path],
		toast_severity_level
	)

	for msg in messages:
		_dock.add_resource_warning_to_dock(resource, msg)


## No special action is needed on completion for the editor reporter.
func on_validation_complete() -> void:
	pass
