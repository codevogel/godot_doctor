## A dock for GodotDoctor that displays validation warnings.
## Warnings can be related to nodes or resources.
## Clicking on a warning will select the node in the scene tree
## or open the resource in the inspector.
## Used by GodotDoctor to show validation warnings.
@tool
class_name GodotDoctorDock
extends Control

#gdlint: disable=max-line-length

const SEVERITY_INFO_ICON_PATH: StringName = "res://addons/godot_doctor/assets/icon/info.png"
const SEVERITY_WARNING_ICON_PATH: StringName = "res://addons/godot_doctor/assets/icon/warning.png"
const EVERITY_ERROR_ICON_PATH: StringName = "res://addons/godot_doctor/assets/icon/error.png"

## A path to the scene used for node validation warnings.
const NODE_WARNING_SCENE_PATH: StringName = "res://addons/godot_doctor/dock/warning/node_validation_warning.tscn"
## A path to the scene used for resource validation warnings.
const RESOURCE_WARNING_SCENE_PATH: StringName = "res://addons/godot_doctor/dock/warning/resource_validation_warning.tscn"
#gdlint: enable=max-line-length

## The container that holds the error/warning instances.
@onready var error_holder: VBoxContainer = $ErrorHolder
@export var validate_now_button: Button


func _enter_tree() -> void:
	print("GodotDoctorDock entered the scene tree.")
	validate_now_button.pressed.connect(_on_validate_now_button_pressed)


func _exit_tree() -> void:
	print("GodotDoctorDock exiting the scene tree.")
	if validate_now_button.pressed.is_connected(_on_validate_now_button_pressed):
		validate_now_button.pressed.disconnect(_on_validate_now_button_pressed)


func _on_validate_now_button_pressed() -> void:
	GodotDoctorPlugin.instance.validate_scene_root_and_edited_resource()


## Add a node-related warning to the dock.
## origin_node: The node that caused the warning.
## error_message: The warning message to display.
func add_node_warning_to_dock(origin_node: Node, validation_message: ValidationMessage) -> void:
	var warning_instance: NodeValidationWarning = (
		load(NODE_WARNING_SCENE_PATH).instantiate() as NodeValidationWarning
	)
	var icon_path: String = _get_warning_icon_path_for_severity(validation_message.severity_level)
	warning_instance.icon.texture = load(icon_path) as Texture2D
	warning_instance.origin_node = origin_node
	warning_instance.label.text = validation_message.message
	error_holder.add_child(warning_instance)


## Add a resource-related warning to the dock.
## origin_resource: The resource that caused the warning.
## error_message: The warning message to display.
func add_resource_warning_to_dock(
	origin_resource: Resource, validation_message: ValidationMessage
) -> void:
	var warning_instance: ResourceValidationWarning = (
		load(RESOURCE_WARNING_SCENE_PATH).instantiate() as ResourceValidationWarning
	)
	var icon_path: String = _get_warning_icon_path_for_severity(validation_message.severity_level)
	warning_instance.icon.texture = load(icon_path) as Texture2D
	warning_instance.origin_resource = origin_resource
	warning_instance.label.text = validation_message.message
	error_holder.add_child(warning_instance)


## Clear all warnings from the dock.
func clear_errors() -> void:
	var children: Array[Node] = error_holder.get_children()
	for child in children:
		child.queue_free.call_deferred()


## Helper method to get the appropriate scene path for a node warning based on its severity level.
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
