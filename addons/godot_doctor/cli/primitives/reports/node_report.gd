class_name NodeReport

var node: Node
var messages: Array[ValidationMessage]


func _init(node: Node, messages: Array[ValidationMessage]) -> void:
	self.node = node
	self.messages = messages
