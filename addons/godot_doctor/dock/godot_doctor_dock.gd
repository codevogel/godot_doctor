@tool
extends Control
class_name GodotDoctorDock

@onready var error_holder: VBoxContainer = $ErrorHolder

const warning_scene_path: StringName = "res://addons/godot_doctor/dock/warning/validation_warning.tscn"


func add_to_dock(origin_node: Node, error_message: String) -> void:
	var warning_instance: ValidationWarning = (
		load(warning_scene_path).instantiate() as ValidationWarning
	)
	warning_instance.origin_node = origin_node
	warning_instance.label.text = error_message
	error_holder.add_child(warning_instance)


func clear_errors() -> void:
	var children: Array[Node] = error_holder.get_children()
	for child in children:
		child.queue_free.call_deferred()
