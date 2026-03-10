class_name GodotDoctorSceneReport

var scene_path: String
var node_reports: Array[GodotDoctorNodeReport]


func _init(scene_path: String, node_reports: Array[GodotDoctorNodeReport]) -> void:
	self.scene_path = scene_path
	self.node_reports = node_reports


func get_node_count() -> int:
	return node_reports.size()
