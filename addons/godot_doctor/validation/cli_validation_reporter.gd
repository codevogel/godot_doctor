## Validation reporter for headless / CLI mode.
## Prints results to stdout and exits the process when validation is complete.
## Each ValidationSuite controls whether warnings count as errors for that suite.
class_name CLIValidationReporter
extends ValidationReporter

## Whether warnings should be treated as errors for the current suite.
## Set this before each suite runs.
var treat_warnings_as_errors: bool = false

## The number of errors found across all suites. Updated as messages are reported.
var _num_errors: int = 0
## The SceneTree, used to quit the application when validation is complete.
var _scene_tree: SceneTree


func _init(scene_tree: SceneTree) -> void:
	_scene_tree = scene_tree


func report_node_messages(node: Node, messages: Array[ValidationMessage]) -> void:
	for msg in messages:
		print("  [%s] %s: %s" % [msg.severity_level, node.name, msg.message])
		if _counts_as_error(msg):
			_num_errors += 1


func report_resource_messages(resource: Resource, messages: Array[ValidationMessage]) -> void:
	print("Resource: %s" % resource.resource_path)
	for msg in messages:
		print("  [%s] %s" % [msg.severity_level, msg.message])
		if _counts_as_error(msg):
			_num_errors += 1


func on_validation_complete() -> void:
	_scene_tree.quit(0 if _num_errors == 0 else 1)


## Returns true if this message should increment the error count.
func _counts_as_error(msg: ValidationMessage) -> bool:
	if msg.severity_level == ValidationCondition.Severity.ERROR:
		return true
	if treat_warnings_as_errors and msg.severity_level == ValidationCondition.Severity.WARNING:
		return true
	return false
