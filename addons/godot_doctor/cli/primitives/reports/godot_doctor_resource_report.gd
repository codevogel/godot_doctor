## Holds the validation _messages collected for a single _resource during a CLI validation run.
class_name GodotDoctorResourceReport
extends GodotDoctorSuiteItemReport
## The validated [Resource].
var _resource: Resource


## Initializes the report with [param _resource] and [param _messages].
func _init(
	suite_report: GodotDoctorSuiteReport,
	resource: Resource,
	messages: Array[GodotDoctorValidationMessage]
) -> void:
	super._init(suite_report, messages)
	_resource = resource


func get_resource() -> Resource:
	return _resource


func teardown() -> void:
	super.teardown()
	_resource = null
