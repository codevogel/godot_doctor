class_name ValidatorCLIOutputWrapper extends ValidatorOutputInterface

# ============================================================================
# PRIVATE PROPERTIES
# ============================================================================

## A Resource that holds the settings for the Godot Doctor plugin.
var _settings: GodotDoctorSettings

# ============================================================================
# INITIALIZATION - Constructor
# ============================================================================

func _init(settings: GodotDoctorSettings) -> void :
	_settings = settings
	
# ============================================================================
# INTERAFACE IMPLMENTATION - Implementation of the function from ValidatorOutputInterface
# ============================================================================

## Prints a debug message to the console if debug printing is enabled in settings.
func print_message(message: String) -> void:
	if _settings.show_debug_prints:
		print("[GODOT DOCTOR] %s" % message)


## Pushes a toast notification to the editor toaster if toasts are enabled in settings.
## [param severity] - 0 for info (default), 1 for warning, 2 for error.
func push_toast(message: String, severity: int = 0) -> void:
	if _settings.show_toasts:
		push_message("[GODOT DOCTOR] %s" % message, severity)
			
func push_message(message : String, severity : ValidationCondition.Severity = ValidationCondition.Severity.INFO) -> void :
	
	if severity == ValidationCondition.Severity.INFO :
		print_rich("[color=blue]%s[/color]" % message)
	elif severity == ValidationCondition.Severity.WARNING :
		print_rich("[color=orange]%s[/color]" % message)
	elif severity == ValidationCondition.Severity.ERROR :
		print_rich("[color=red]%s[/color]" % message)
		
func add_node_warning_to_dock(origin_node: Node, validation_message: ValidationMessage) -> void :
	
	push_message(origin_node.name + " " + validation_message.message, validation_message.severity_level)

	

## Add a resource-related warning to the dock.
## origin_resource: The resource that caused the warning.
## error_message: The warning message to display.
func add_resource_warning_to_dock(origin_resource: Resource, validation_message: ValidationMessage) -> void :
	
	push_message(origin_resource.name + " " + validation_message.message, validation_message.severity_level)
	
	
