## Holds the validation _messages collected for a single node during a CLI validation run.
class_name GodotDoctorNodeReport
extends GodotDoctorSuiteItemReport

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
	super._init(suite_report, messages)
	_node_name = node_name
	_node_ancestor_path = node_ancestor_path


## Getter for the node name this report belongs to.
func get_node_name() -> String:
	return _node_name


## Getter for the ancestor path of the node this report belongs to.
## e.g. "Node2D/Node3D/Node" for a node named "Node" with parent "Node3D" and grandparent "Node2D".
func get_node_ancestor_path() -> String:
	return _node_ancestor_path


func teardown() -> void:
	super.teardown()
	_node_name = ""
	_node_ancestor_path = ""
