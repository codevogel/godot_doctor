## A utility class for emitting debug prints and editor toast notifications.
## All methods are static; this class is not meant to be instantiated.
class_name GodotDoctorNotifier

## The preix used for all debug prints and toast notifications emitted by Godot Doctor.
const GODOT_DOCTOR_PREFIX: String = "[GODOT DOCTOR]"


## Prints [param message] to the output console, prefixed with [constant GODOT_DOCTOR_PREFIX],
## if [member GodotDoctorSettings.show_debug_prints] is enabled in the plugin settings.
static func print_debug(message: String) -> void:
	if GodotDoctorPlugin.instance.settings.show_debug_prints:
		print(_prefix_message(message))


## Pushes a toast notification to the editor toaster if toasts are enabled in settings.
## [param severity] controls the toast type: 0 for info (default), 1 for warning, 2 for error.
static func push_toast(message: String, severity: int = 0) -> void:
	if GodotDoctorPlugin.instance.settings.show_toasts:
		EditorInterface.get_editor_toaster().push_toast(_prefix_message(message), severity)


## Returns a string with [param message] prefixed by [constant GODOT_DOCTOR_PREFIX].
static func _prefix_message(message: String) -> String:
	return "%s: %s" % [GODOT_DOCTOR_PREFIX, message]
