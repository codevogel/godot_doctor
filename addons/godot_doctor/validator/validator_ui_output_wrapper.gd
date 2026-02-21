class_name ValidatorUIOutputWrapper extends ValidatorOutputInterface

var _dock: GodotDoctorDock

## A Resource that holds the settings for the Godot Doctor plugin.
var _settings: GodotDoctorSettings

func _init(dock: GodotDoctorDock, settings: GodotDoctorSettings) -> void :
	_dock = dock
	_settings = settings
	

## Prints a debug message to the console if debug printing is enabled in settings.
func _print_debug(message: String) -> void:
	if _settings.show_debug_prints:
		print("[GODOT DOCTOR] %s" % message)


## Pushes a toast notification to the editor toaster if toasts are enabled in settings.
## [param severity] - 0 for info (default), 1 for warning, 2 for error.
func _push_toast(message: String, severity: int = 0) -> void:
	if _settings.show_toasts:
		EditorInterface.get_editor_toaster().push_toast("Godot Doctor: %s" % message, severity)
		
		
		
func add_node_warning_to_dock(origin_node: Node, validation_message: ValidationMessage) -> void :
	_dock.add_node_warning_to_dock(origin_node, validation_message)

## Add a resource-related warning to the dock.
## origin_resource: The resource that caused the warning.
## error_message: The warning message to display.
func add_resource_warning_to_dock(origin_resource: Resource, validation_message: ValidationMessage) -> void :
	_dock.add_resource_warning_to_dock(origin_resource, validation_message)
