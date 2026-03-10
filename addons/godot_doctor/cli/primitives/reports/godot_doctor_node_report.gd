class_name GodotDoctorNodeReport

var node_path: String
var messages: Array[GodotDoctorValidationMessage]


func _init(node_path: String, messages: Array[GodotDoctorValidationMessage]) -> void:
	self.node_path = node_path
	self.messages = messages
