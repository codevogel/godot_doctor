## A dock for GodotDoctor that displays validation warnings.
## Warnings can be related to nodes or resources.
## Clicking on a warning will select the node in the scene tree
## or open the resource in the inspector.
## Used by GodotDoctor to show validation warnings.
@tool
class_name GodotDoctorDock
extends Control

#gdlint: disable=max-line-length
## A path to the scene used for node validation warnings.
const NODE_WARNING_SCENE_PATH: StringName = "res://addons/godot_doctor/dock/warning/node_validation_warning.tscn"
## A path to the scene used for resource validation warnings.
const RESOURCE_WARNING_SCENE_PATH: StringName = "res://addons/godot_doctor/dock/warning/resource_validation_warning.tscn"
#gdlint: enable=max-line-length

## The container that holds the error/warning instances.
@onready var error_holder: VBoxContainer = $ErrorHolder


## Add a node-related warning to the dock.
## origin_node: The node that caused the warning.
## error_message: The warning message to display.
func add_node_warning_to_dock(origin_node: Node, error_message: String) -> void:
	var warning_instance: NodeValidationWarning = (
		load(NODE_WARNING_SCENE_PATH).instantiate() as NodeValidationWarning
	)
	warning_instance.origin_node = origin_node
	warning_instance.label.text = error_message
	error_holder.add_child(warning_instance)


## Add a resource-related warning to the dock.
## origin_resource: The resource that caused the warning.
## error_message: The warning message to display.
func add_resource_warning_to_dock(origin_resource: Resource, error_message: String) -> void:
	var warning_instance: ResourceValidationWarning = (
		load(RESOURCE_WARNING_SCENE_PATH).instantiate() as ResourceValidationWarning
	)
	warning_instance.origin_resource = origin_resource
	warning_instance.label.text = error_message
	error_holder.add_child(warning_instance)


## Clear all warnings from the dock.
func clear_errors() -> void:
	var children: Array[Node] = error_holder.get_children()
	for child in children:
		child.queue_free.call_deferred()
