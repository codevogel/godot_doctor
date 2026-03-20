## A utility class for emitting debug prints and editor toast notifications.
## All methods are static; this class is not meant to be instantiated.
class_name GodotDoctorNotifier


## Prints [param message] to the output console, prefixed with [code][GODOT_DOCTOR][/code]
## (or [code][GODOT_DOCTOR->ClassName][/code] when [param caller] is provided),
## if [member GodotDoctorSettings.show_debug_prints] is enabled in the plugin settings.
## [param caller] can be an [Object] (its class name is used) or a plain [String].
static func print_debug(message: String, caller: Variant = null) -> void:
	if GodotDoctorPlugin.instance.settings.show_debug_prints:
		print(_prefix_message(message, _resolve_prefix(caller)))


## Pushes a toast notification to the editor toaster if toasts are enabled in settings.
## Only meaningful in editor mode; no-ops in CLI mode.
## [param severity] controls the toast type: 0 for info (default), 1 for warning, 2 for error.
static func push_toast(message: String, severity: int = 0) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if GodotDoctorPlugin.instance.settings.show_toasts:
		EditorInterface.get_editor_toaster().push_toast(_prefix_message(message, ""), severity)


## Resolves [param caller] to a class-name string.
## If [param caller] is a [Script], its [code]class_name[/code] is returned when available.
## If [param caller] is an [Object], its script [code]class_name[/code] is preferred
## when available; otherwise its built-in class name is returned.
## If [param caller] is a non-empty [String], it is returned as-is.
## Otherwise, an empty string is returned.
static func _resolve_prefix(caller: Variant) -> String:
	if caller is Script:
		var caller_script_global_name: StringName = (caller as Script).get_global_name()
		if not caller_script_global_name.is_empty():
			return String(caller_script_global_name)
	if caller is Object:
		var script: Variant = caller.get_script()
		if script is Script:
			var script_global_name: StringName = (script as Script).get_global_name()
			if not script_global_name.is_empty():
				return String(script_global_name)
		return caller.get_class()
	if caller is String and not (caller as String).is_empty():
		return caller as String
	return ""


## Returns [param message] prefixed with [code][GODOT_DOCTOR][/code],
## or [code][GODOT_DOCTOR->class_prefix][/code] if [param class_prefix] is not empty.
static func _prefix_message(message: String, class_prefix: String) -> String:
	var prefix = (
		"[GODOT_DOCTOR]" if class_prefix.is_empty() else "[GODOT_DOCTOR->%s]" % class_prefix
	)
	return "%s: %s" % [prefix, message]
