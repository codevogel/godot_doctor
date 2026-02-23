## UI based implmentatio of the [ValidatorOutputInterface]. Displays errors in the Godot Editor UI.
class_name ValidatorUIOutputWrapper extends ValidatorOutputInterface


# ============================================================================
# PRIVATE PROPERTIES
# ============================================================================


## Reference to the dock that will display information in the editor UI.
var _dock: GodotDoctorDock

# ============================================================================
# INITIALIZATION - Constructor
# ============================================================================


func _init(dock: GodotDoctorDock, settings: GodotDoctorSettings) -> void :
	_dock = dock
	_settings = settings
	
# ============================================================================
# ABSTRACT INTERAFACE IMPLMENTATION - Implementation of the functions from ValidatorOutputInterface
# ============================================================================


## Pushes a toast notification to the editor toaster if toasts are enabled in settings.
## [param severity] - 0 for info (default), 1 for warning, 2 for error.
func push_toast(message: String, severity: int = 0) -> void:
	if _settings.show_toasts:
		EditorInterface.get_editor_toaster().push_toast("Godot Doctor: %s" % message, severity)
		
		
## Add a node-related warning to the dock.
## origin_node: The node that caused the warning.
## error_message: The warning message to display.
func add_node_warning_to_dock(origin_node: Node, validation_message: ValidationMessage) -> void :
	_dock.add_node_warning_to_dock(origin_node, validation_message)


## Add a resource-related warning to the dock.
## origin_resource: The resource that caused the warning.
## error_message: The warning message to display.
func add_resource_warning_to_dock(origin_resource: Resource, validation_message: ValidationMessage) -> void :
	_dock.add_resource_warning_to_dock(origin_resource, validation_message)
