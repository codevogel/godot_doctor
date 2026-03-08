class_name GodotDoctorNotifier

const GODOT_DOCTOR_PREFIX: String = "[GODOT DOCTOR]"


static func print_debug(message: String) -> void:
	if GodotDoctorPlugin.instance.settings.show_debug_prints:
		_print(message)


## Pushes a toast notification to the editor toaster if toasts are enabled in settings.
## Only meaningful in editor mode; no-ops in CLI mode.
## [param severity] - 0 for info (default), 1 for warning, 2 for error.
static func push_toast(message: String, severity: int = 0) -> void:
	if GodotDoctorPlugin.instance.settings.show_toasts:
		EditorInterface.get_editor_toaster().push_toast(
			"%s: %s" % [GODOT_DOCTOR_PREFIX, message], severity
		)


static func _print(message: String) -> void:
	print("%s: %s" % [GODOT_DOCTOR_PREFIX, message])
