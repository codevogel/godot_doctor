## Abstract class used by the [Validator] to output information.
@abstract class_name ValidatorOutputInterface extends RefCounted

# ============================================================================
# PRIVATE PROPERTIES
# ============================================================================


## A Resource that holds the settings for the Godot Doctor plugin.
var _settings: GodotDoctorSettings


# ============================================================================
# CORE INTERFACE
# ============================================================================


## Prints a debug message to the console if debug printing is enabled in settings.
func push_debug(message: String) -> void:
	if _settings.show_debug_prints:
		print("[GODOT DOCTOR] %s" % message)
	
	
# ============================================================================
# ABSTRACT INTERFACE
# ============================================================================


## Pushes a toast notification to the editor toaster if toasts are enabled in settings.
## [param severity] - 0 for info (default), 1 for warning, 2 for error.
@abstract func push_toast(message: String, severity: int = 0) -> void


## Add a node-related warning to the output where [param origin_node] is the node that caused
## the warning and [param validation_message] is the warning message to display.
@abstract func add_node_warning(origin_node: Node, validation_message: ValidationMessage) -> void


## Add a resource-related error to the output where [param origin_node] is the node that caused
## the warning and [param validation_message] is the warning message to display.
@abstract func add_resource_warning(origin_resource: Resource, validation_message: ValidationMessage) -> void
