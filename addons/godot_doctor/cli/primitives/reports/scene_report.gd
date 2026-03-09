class_name SceneReport

var scene_path: String
var node_reports: Array[NodeReport]


func _init(scene_path: String, node_reports: Array[NodeReport]) -> void:
	self.scene_path = scene_path
	self.node_reports = node_reports


func get_node_count() -> int:
	return node_reports.size()
