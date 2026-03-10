class_name GodotDoctorResourceReport

var resource: Resource
var messages: Array[GodotDoctorValidationMessage]


func _init(resource: Resource, messages: Array[GodotDoctorValidationMessage]) -> void:
	self.resource = resource
	self.messages = messages
