## Validation reporter for the Godot Editor.
## Displays results as toasts and pushes them to the Godot Doctor dock.
class_name EditorValidationReporter
extends ValidationReporter

var _dock: GodotDoctorDock


func _init(dock: GodotDoctorDock) -> void:
	_dock = dock


func report_node_messages(node: Node, messages: Array[ValidationMessage]) -> void:
	if messages.is_empty():
		return

	var effective_messages := messages
	if GodotDoctorPlugin.instance.settings.treat_warnings_as_errors:
		effective_messages = _apply_warnings_as_errors(messages)

	var severity_level: int = (
		effective_messages.map(func(msg: ValidationMessage) -> int: return msg.severity_level).max()
	)

	GodotDoctorNotifier.push_toast(
		"Found %s configuration warning(s) in %s." % [effective_messages.size(), node.name],
		severity_level
	)

	for msg in effective_messages:
		_dock.add_node_warning_to_dock(node, msg)


func report_resource_messages(resource: Resource, messages: Array[ValidationMessage]) -> void:
	if messages.is_empty():
		return

	var effective_messages := messages
	if GodotDoctorPlugin.instance.settings.treat_warnings_as_errors:
		effective_messages = _apply_warnings_as_errors(messages)

	var severity_level: int = (
		effective_messages.map(func(msg: ValidationMessage) -> int: return msg.severity_level).max()
	)

	GodotDoctorNotifier.push_toast(
		(
			"Found %s configuration warning(s) in %s."
			% [effective_messages.size(), resource.resource_path]
		),
		severity_level
	)

	for msg in effective_messages:
		_dock.add_resource_warning_to_dock(resource, msg)


func on_validation_complete() -> void:
	# No special action needed on completion for the editor reporter.
	pass
