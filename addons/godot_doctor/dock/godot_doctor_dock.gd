## A dock for GodotDoctor that displays validation warnings.
## Warnings can be related to nodes or resources.
## Clicking on a warning will select the node in the scene tree or open the resource in the inspector.
## Used by GodotDoctor to show validation warnings.
@tool
extends Control
class_name GodotDoctorDock

## The container that holds the error/warning instances.
@onready var error_holder: VBoxContainer = $ErrorHolder

## A path to the scene used for node validation warnings.
const node_warning_scene_path: StringName = "res://addons/godot_doctor/dock/warning/node_validation_warning.tscn"
## A path to the scene used for resource validation warnings.
const resource_warning_scene_path: StringName = "res://addons/godot_doctor/dock/warning/resource_validation_warning.tscn"

## Add a node-related warning to the dock.
## origin_node: The node that caused the warning.
## error_message: The warning message to display.
func add_node_warning_to_dock(origin_node: Node, error_message: String) -> void:
	var warning_instance: NodeValidationWarning = (
		load(node_warning_scene_path).instantiate() as NodeValidationWarning
	)
	warning_instance.origin_node = origin_node
	warning_instance.label.text = error_message
	error_holder.add_child(warning_instance)

## Add a resource-related warning to the dock.
## origin_resource: The resource that caused the warning.
## error_message: The warning message to display.
func add_resource_warning_to_dock(origin_resource: Resource, error_message: String) -> void:
	var warning_instance: ResourceValidationWarning = (
		load(resource_warning_scene_path).instantiate() as ResourceValidationWarning
	)
	warning_instance.origin_resource = origin_resource
	warning_instance.label.text = error_message
	error_holder.add_child(warning_instance)

## Clear all warnings from the dock.
func clear_errors() -> void:
	var children: Array[Node] = error_holder.get_children()
	for child in children:
		child.queue_free.call_deferred()
