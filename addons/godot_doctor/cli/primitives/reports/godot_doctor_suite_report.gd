## Holds all [GodotDoctorSceneReport] and [GodotDoctorResourceReport] collected for
## a single validation suite during a CLI validation run.
class_name GodotDoctorSuiteReport

## The [GodotDoctorValidationSuite] this report belongs to.
var suite: GodotDoctorValidationSuite
## The [GodotDoctorSceneReport]s collected during validation of this suite.
var scene_reports: Array[GodotDoctorSceneReport]
## The [GodotDoctorResourceReport]s collected during validation of this suite.
var resource_reports: Array[GodotDoctorResourceReport]


## Initializes the report with [param suite], [param scene_reports], and [param resource_reports].
func _init(
	suite: GodotDoctorValidationSuite,
	scene_reports: Array[GodotDoctorSceneReport],
	resource_reports: Array[GodotDoctorResourceReport]
) -> void:
	self.suite = suite
	self.scene_reports = scene_reports
	self.resource_reports = resource_reports


## Returns the number of scenes validated in this suite.
func get_scenes_validated_count() -> int:
	return scene_reports.size()


## Returns the total number of nodes validated across all scenes in this suite.
func get_nodes_validated_count() -> int:
	return scene_reports.reduce(
		func(acc: int, sr: GodotDoctorSceneReport) -> int:
			return acc + sr.get_nodes_validated_count(),
		0
	)


## Returns the total number of messages with severity level
## [constant ValidationCondition.Severity.INFO]
## across all scenes and resources in this suite.
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


## Returns the total number of messages with severity level
## [constant ValidationCondition.Severity.WARNING]
## across all scenes and resources in this suite.
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


## Returns the total number of messages with severity level
## [constant ValidationCondition.Severity.ERROR]
## across all scenes and resources in this suite.
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


## Returns the number of warnings that count as errors because
## [member GodotDoctorValidationSuite.treat_warnings_as_errors] is enabled.
func get_warning_messages_as_errors_count() -> int:
	return get_warning_messages_count() if suite.treat_warnings_as_errors else 0


## Returns the total error count for this suite, including warnings promoted to errors.
func get_error_count() -> int:
	return get_hard_error_messages_count() + get_warning_messages_as_errors_count()
