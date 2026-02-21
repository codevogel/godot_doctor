@abstract class_name ValidatorOutputInterface extends RefCounted


## Prints a debug message to the console if debug printing is enabled in settings.
@abstract func print_message(message: String) -> void

## Pushes a toast notification to the editor toaster if toasts are enabled in settings.
## [param severity] - 0 for info (default), 1 for warning, 2 for error.
@abstract func push_toast(message: String, severity: int = 0) -> void


@abstract func add_node_warning_to_dock(origin_node: Node, validation_message: ValidationMessage) -> void

## Add a resource-related warning to the dock.
## origin_resource: The resource that caused the warning.
## error_message: The warning message to display.
@abstract func add_resource_warning_to_dock(origin_resource: Resource, validation_message: ValidationMessage) -> void
