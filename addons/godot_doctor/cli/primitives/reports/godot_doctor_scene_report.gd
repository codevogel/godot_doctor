## Holds all [GodotDoctorNodeReport] collected for a single scene during a CLI validation run.
class_name GodotDoctorSceneReport

## The filesystem path of the scene that the node reports in this scene report correspond to.
var scene_path: String
## The [GodotDoctorNodeReport]s collected during validation of this scene.
var node_reports: Array[GodotDoctorNodeReport]


## Initializes the report with [param scene_path] and [param node_reports].
func _init(scene_path: String, node_reports: Array[GodotDoctorNodeReport]) -> void:
	self.scene_path = scene_path
	self.node_reports = node_reports


## Returns the total number of nodes validated in this scene.
func get_nodes_validated_count() -> int:
	return node_reports.size()


## Returns the total number of messages with severity level
## [constant ValidationCondition.Severity.INFO] across all nodes in this scene.
func get_info_messages_count() -> int:
	return node_reports.reduce(
		func(acc: int, nr: GodotDoctorNodeReport) -> int: return acc + nr.get_info_messages_count(),
		0
	)


## Returns the total number of messages with severity level
## [constant ValidationCondition.Severity.WARNING] across all nodes in this scene.
func get_warning_messages_count() -> int:
	return node_reports.reduce(
		func(acc: int, nr: GodotDoctorNodeReport) -> int:
			return acc + nr.get_warning_messages_count(),
		0
	)


## Returns the total number of messages with severity level
## [constant ValidationCondition.Severity.ERROR] across all nodes in this scene.
func get_hard_error_messages_count() -> int:
	return node_reports.reduce(
		func(acc: int, nr: GodotDoctorNodeReport) -> int:
			return acc + nr.get_hard_error_messages_count(),
		0
	)


func has_errors(treat_warnings_as_errors: bool) -> bool:
	var total_errors = get_hard_error_messages_count()
	if treat_warnings_as_errors:
		total_errors += get_warning_messages_count()
	return total_errors > 0
