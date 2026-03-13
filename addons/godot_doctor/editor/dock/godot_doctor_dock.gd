## A dock for GodotDoctor that displays validation warnings.
## Warnings can be related to nodes or resources.
## Clicking on a warning will select the node in the scene tree
## or open the resource in the inspector.
## Used by GodotDoctor to show validation warnings.
@tool
class_name GodotDoctorDock
extends Control

#gdlint: disable=max-line-length

const SEVERITY_INFO_ICON_PATH: StringName = "res://addons/godot_doctor/editor/dock/warning/assets/icon/info.png"
const SEVERITY_WARNING_ICON_PATH: StringName = "res://addons/godot_doctor/editor/dock/warning/assets/icon/warning.png"
const EVERITY_ERROR_ICON_PATH: StringName = "res://addons/godot_doctor/editor/dock/warning/assets/icon/error.png"

## A path to the scene used for node validation warnings.
const NODE_WARNING_SCENE_PATH: StringName = "res://addons/godot_doctor/editor/dock/warning/node_validation_warning.tscn"
## A path to the scene used for resource validation warnings.
const RESOURCE_WARNING_SCENE_PATH: StringName = "res://addons/godot_doctor/editor/dock/warning/resource_validation_warning.tscn"
#gdlint: enable=max-line-length

## The container that holds the error/warning instances.
@export var validate_now_button: Button
@onready var error_holder: VBoxContainer = $ErrorHolder


## Connects the validate-now button signal when the dock enters the scene tree.
func _enter_tree() -> void:
	validate_now_button.pressed.connect(_on_validate_now_button_pressed)


## Disconnects the validate-now button signal when the dock exits the scene tree.
func _exit_tree() -> void:
	if validate_now_button.pressed.is_connected(_on_validate_now_button_pressed):
		validate_now_button.pressed.disconnect(_on_validate_now_button_pressed)


## Triggers validation of the current scene root and edited resource when the button is pressed.
func _on_validate_now_button_pressed() -> void:
	GodotDoctorNotifier.print_debug("Validate Now button pressed. Triggering validation.")
	GodotDoctorPlugin.instance.validate_scene_root_and_edited_resource()


## Adds a node-related warning to the dock for [param origin_node].
## Displays [param validation_message] with the appropriate severity icon.
## Clicking the entry selects [param origin_node] in the scene tree.
func add_node_warning_to_dock(
	origin_node: Node, validation_message: GodotDoctorValidationMessage
) -> void:
	GodotDoctorNotifier.print_debug(
		(
			"Adding node warning to dock for node: %s, message: %s"
			% [origin_node.name, validation_message.message]
		)
	)
	var warning_instance: GodotDoctorNodeValidationWarning = (
		load(NODE_WARNING_SCENE_PATH).instantiate() as GodotDoctorNodeValidationWarning
	)
	var icon_path: String = _get_warning_icon_path_for_severity(validation_message.severity_level)
	warning_instance.icon.texture = load(icon_path) as Texture2D
	warning_instance.origin_node = origin_node
	warning_instance.label.text = validation_message.message
	error_holder.add_child(warning_instance)


## Adds a resource-related warning to the dock for [param origin_resource].
## Displays [param validation_message] with the appropriate severity icon.
## Clicking the entry opens [param origin_resource] in the inspector.
func add_resource_warning_to_dock(
	origin_resource: Resource, validation_message: GodotDoctorValidationMessage
) -> void:
	GodotDoctorNotifier.print_debug(
		(
			"Adding resource warning to dock for resource: %s, message: %s"
			% [origin_resource.resource_path, validation_message.message]
		)
	)
	var warning_instance: GodotDoctorResourceValidationWarning = (
		load(RESOURCE_WARNING_SCENE_PATH).instantiate() as GodotDoctorResourceValidationWarning
	)
	var icon_path: String = _get_warning_icon_path_for_severity(validation_message.severity_level)
	warning_instance.icon.texture = load(icon_path) as Texture2D
	warning_instance.origin_resource = origin_resource
	warning_instance.label.text = validation_message.message
	error_holder.add_child(warning_instance)


## Clear all warnings from the dock.
func clear_errors() -> void:
	GodotDoctorNotifier.print_debug("Clearing all warnings from the dock.")
	var children: Array[Node] = error_holder.get_children()
	for child in children:
		child.free()


## Returns the icon asset path corresponding to [param severity_level].
func _get_warning_icon_path_for_severity(
	severity_level: ValidationCondition.Severity
) -> StringName:
	match severity_level:
		ValidationCondition.Severity.INFO:
			return SEVERITY_INFO_ICON_PATH
		ValidationCondition.Severity.WARNING:
			return SEVERITY_WARNING_ICON_PATH
		ValidationCondition.Severity.ERROR:
			return EVERITY_ERROR_ICON_PATH
		_:
			push_error(
				"No scene defined for node warning with severity level: " + str(severity_level)
			)
			return ""
