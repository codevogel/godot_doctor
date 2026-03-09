class_name ResourceReport

var resource: Resource
var messages: Array[ValidationMessage]


func _init(resource: Resource, messages: Array[ValidationMessage]) -> void:
	self.resource = resource
	self.messages = messages
