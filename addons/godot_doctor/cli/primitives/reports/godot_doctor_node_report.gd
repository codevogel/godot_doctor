## Holds the validation _messages collected for a single node during a CLI validation run.
class_name GodotDoctorNodeReport
extends GodotDoctorReport

## The [GodotDoctorValidationSuite] this report belongs to.
var _suite_report: GodotDoctorSuiteReport

## The name of the node this report belongs to.
var _node_name: String
## The ancestor path of the node this report belongs to,
## e.g. "Node2D/Node3D/Node" for a node named "Node" with parent "Node3D" and grandparent "Node2D".
var _node_ancestor_path: String


## Initializes the report with [param _node_ancestor_path] and [param _messages].
func _init(
	suite_report: GodotDoctorSuiteReport,
	messages: Array[GodotDoctorValidationMessage],
	node_name: String,
	node_ancestor_path: String,
) -> void:
	_suite_report = suite_report
	_messages = messages
	_node_name = node_name
	_node_ancestor_path = node_ancestor_path


#region Abstract Method Implementations


func _collect_messages() -> Array[GodotDoctorValidationMessage]:
	return _messages


func get_effective_error_count() -> int:
	return _get_effective_error_count(_suite_report.get_suite().treat_warnings_as_errors)


func get_warnings_treated_as_errors_count() -> int:
	return _get_warnings_treated_as_errors_count(_suite_report.get_suite().treat_warnings_as_errors)


#endregion


## Getter for the node name this report belongs to.
func get_node_name() -> String:
	return _node_name


## Getter for the ancestor path of the node this report belongs to.
## e.g. "Node2D/Node3D/Node" for a node named "Node" with parent "Node3D" and grandparent "Node2D".
func get_node_ancestor_path() -> String:
	return _node_ancestor_path


func teardown() -> void:
	super.teardown()
	_suite_report = null
	_node_name = ""
	_node_ancestor_path = ""
