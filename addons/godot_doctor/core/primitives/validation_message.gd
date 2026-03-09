class_name ValidationMessage
extends RefCounted

var message: String
var severity_level: ValidationCondition.Severity


func _init(message: String, severity_level: ValidationCondition.Severity) -> void:
	self.message = message
	self.severity_level = severity_level


func to_string() -> String:
	return "%s: %s" % [str(severity_level), message]
