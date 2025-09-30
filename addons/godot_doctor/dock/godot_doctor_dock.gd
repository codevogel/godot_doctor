@tool
extends Control
class_name GodotDoctorDock

@onready var error_holder: VBoxContainer = $ErrorHolder

const node_warning_scene_path: StringName = "res://addons/godot_doctor/dock/warning/node_validation_warning.tscn"
const resource_warning_scene_path: StringName = "res://addons/godot_doctor/dock/warning/resource_validation_warning.tscn"


func add_node_warning_to_dock(origin_node: Node, error_message: String) -> void:
	var warning_instance: NodeValidationWarning = (
		load(node_warning_scene_path).instantiate() as NodeValidationWarning
	)
	warning_instance.origin_node = origin_node
	warning_instance.label.text = error_message
	error_holder.add_child(warning_instance)


func add_resource_warning_to_dock(origin_resource: Resource, error_message: String) -> void:
	var warning_instance: ResourceValidationWarning = (
		load(resource_warning_scene_path).instantiate() as ResourceValidationWarning
	)
	warning_instance.origin_resource = origin_resource
	warning_instance.label.text = error_message
	error_holder.add_child(warning_instance)


func clear_errors() -> void:
	var children: Array[Node] = error_holder.get_children()
	for child in children:
		child.queue_free.call_deferred()
