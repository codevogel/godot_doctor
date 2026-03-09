class_name SuiteReport

var suite: ValidationSuite
var scene_reports: Array
var resource_reports: Array[ResourceReport]


func _init(
	suite: ValidationSuite, scene_reports: Array, resource_reports: Array[ResourceReport]
) -> void:
	self.suite = suite
	self.scene_reports = scene_reports
	self.resource_reports = resource_reports


func get_message_counts() -> MessageCounts:
	var counts: MessageCounts = MessageCounts.new()
	var messages: Array = _collect_messages()
	counts.info = SuiteReport.get_message_count(messages, ValidationCondition.Severity.INFO)
	counts.warning = SuiteReport.get_message_count(messages, ValidationCondition.Severity.WARNING)
	counts.hard_error = SuiteReport.get_message_count(messages, ValidationCondition.Severity.ERROR)
	if suite.treat_warnings_as_errors:
		counts.warnings_as_errors = counts.warning
	return counts


func get_error_count() -> int:
	var c: int = 0
	for msg in _collect_messages():
		if counts_as_error(msg):
			c += 1
	return c


func counts_as_error(msg: ValidationMessage) -> bool:
	return (
		msg.severity_level == ValidationCondition.Severity.ERROR
		or (
			suite.treat_warnings_as_errors
			and msg.severity_level == ValidationCondition.Severity.WARNING
		)
	)


static func get_message_count(messages: Array, severity: ValidationCondition.Severity) -> int:
	var acc: int = 0
	for msg in messages:
		if msg.severity_level == severity:
			acc += 1
	return acc


func _collect_messages() -> Array:
	var messages: Array = []
	for scene_report in scene_reports:
		for node_report in scene_report.node_reports:
			messages.append_array(node_report.messages)
	for resource_report in resource_reports:
		messages.append_array(resource_report.messages)
	return messages
