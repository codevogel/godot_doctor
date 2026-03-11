class_name GodotDoctorNodeReport
var node_path: String
var messages: Array[GodotDoctorValidationMessage]


func _init(node_path: String, messages: Array[GodotDoctorValidationMessage]) -> void:
	self.node_path = node_path
	self.messages = messages


func get_info_messages_count() -> int:
	var info_messages = messages.filter(
		func(m: GodotDoctorValidationMessage) -> bool:
			return m.severity_level == ValidationCondition.Severity.INFO
	)
	return info_messages.size()


func get_warning_messages_count() -> int:
	var warning_messages = messages.filter(
		func(m: GodotDoctorValidationMessage) -> bool:
			return m.severity_level == ValidationCondition.Severity.WARNING
	)
	return warning_messages.size()


func get_hard_error_messages_count() -> int:
	var hard_error_messages = messages.filter(
		func(m: GodotDoctorValidationMessage) -> bool:
			return m.severity_level == ValidationCondition.Severity.ERROR
	)
	return hard_error_messages.size()
