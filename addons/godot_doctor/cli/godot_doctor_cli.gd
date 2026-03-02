@tool
class_name GodotDoctorCLI
extends EditorScript


func _run():
	print("Running Godot Doctor CLI... on instance %s" % GodotDoctorPlugin.instance)
	GodotDoctorPlugin.instance.scene_root_validation_request_completed.connect(
		_on_scene_root_validation_request_completed
	)
	GodotDoctorPlugin.instance.resource_validation_request_completed.connect(
		_on_resource_validation_request_completed
	)
	GodotDoctorPlugin.instance.scene_root_and_edited_resource_validation_requested.emit()

	GodotDoctorPlugin.instance.scene_root_validation_request_completed.disconnect(
		_on_scene_root_validation_request_completed
	)
	GodotDoctorPlugin.instance.resource_validation_request_completed.disconnect(
		_on_resource_validation_request_completed
	)


func _on_scene_root_validation_request_completed(
	validation_messages: Array[ValidationMessage]
) -> void:
	print("Scene root validation completed with %d messages." % validation_messages.size())
	for message in validation_messages:
		print("Scene validation: %s: %s" % [message.severity_level, message.message])


func _on_resource_validation_request_completed(
	validation_messages: Array[ValidationMessage]
) -> void:
	print("Resource validation completed with %d messages." % validation_messages.size())
	for message in validation_messages:
		print("Resource validation: %s: %s" % [message.severity_level, message.message])
