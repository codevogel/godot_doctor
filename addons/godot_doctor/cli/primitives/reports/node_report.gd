class_name NodeReport

var node_path: String
var messages: Array[ValidationMessage]


func _init(node_path: String, messages: Array[ValidationMessage]) -> void:
	self.node_path = node_path
	self.messages = messages
