class_name GodotDoctorSuiteReport

var suite: GodotDoctorValidationSuite
var scene_reports: Array
var resource_reports: Array[GodotDoctorResourceReport]


func _init(
	suite: GodotDoctorValidationSuite,
	scene_reports: Array[GodotDoctorSceneReport],
	resource_reports: Array[GodotDoctorResourceReport]
) -> void:
	self.suite = suite
	self.scene_reports = scene_reports
	self.resource_reports = resource_reports


func get_scenes_validated_count() -> int:
	return scene_reports.size()


func get_nodes_validated_count() -> int:
	return scene_reports.reduce(
		func(acc: int, sr: GodotDoctorSceneReport) -> int:
			return acc + sr.get_nodes_validated_count(),
		0
	)


func get_info_messages_count() -> int:
	return (
		scene_reports.reduce(
			func(acc: int, sr: GodotDoctorSceneReport) -> int:
				return acc + sr.get_info_messages_count(),
			0
		)
		+ resource_reports.reduce(
			func(acc: int, rr: GodotDoctorResourceReport) -> int:
				return acc + rr.get_info_messages_count(),
			0
		)
	)


func get_warning_messages_count() -> int:
	return (
		scene_reports.reduce(
			func(acc: int, sr: GodotDoctorSceneReport) -> int:
				return acc + sr.get_warning_messages_count(),
			0
		)
		+ resource_reports.reduce(
			func(acc: int, rr: GodotDoctorResourceReport) -> int:
				return acc + rr.get_warning_messages_count(),
			0
		)
	)


func get_hard_error_messages_count() -> int:
	return (
		scene_reports.reduce(
			func(acc: int, sr: GodotDoctorSceneReport) -> int:
				return acc + sr.get_hard_error_messages_count(),
			0
		)
		+ resource_reports.reduce(
			func(acc: int, rr: GodotDoctorResourceReport) -> int:
				return acc + rr.get_hard_error_messages_count(),
			0
		)
	)


func get_warning_messages_as_errors_count() -> int:
	return get_warning_messages_count() if suite.treat_warnings_as_errors else 0


func get_error_count() -> int:
	return get_hard_error_messages_count() + get_warning_messages_as_errors_count()
