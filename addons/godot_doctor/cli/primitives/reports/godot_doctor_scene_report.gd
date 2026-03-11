class_name GodotDoctorSceneReport

var scene_path: String
var node_reports: Array[GodotDoctorNodeReport]


func _init(scene_path: String, node_reports: Array[GodotDoctorNodeReport]) -> void:
	self.scene_path = scene_path
	self.node_reports = node_reports


func get_nodes_validated_count() -> int:
	return node_reports.size()


func get_info_messages_count() -> int:
	return node_reports.reduce(
		func(acc: int, nr: GodotDoctorNodeReport) -> int: return acc + nr.get_info_messages_count(),
		0
	)


func get_warning_messages_count() -> int:
	return node_reports.reduce(
		func(acc: int, nr: GodotDoctorNodeReport) -> int:
			return acc + nr.get_warning_messages_count(),
		0
	)


func get_hard_error_messages_count() -> int:
	return node_reports.reduce(
		func(acc: int, nr: GodotDoctorNodeReport) -> int:
			return acc + nr.get_hard_error_messages_count(),
		0
	)
