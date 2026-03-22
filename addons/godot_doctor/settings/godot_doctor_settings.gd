@tool
## A resource that holds settings for the [GodotDoctorPlugin].
## Used by [GodotDoctorPlugin] to store and access user preferences.
class_name GodotDoctorSettings
extends Resource

## The default position of the GodotDoctor dock in the editor.
@export var default_dock_position: EditorPlugin.DockSlot = EditorPlugin.DockSlot.DOCK_SLOT_RIGHT_BL

## Whether to automatically check for plugin updates on plugin startup.
@export var check_for_updates_on_startup: bool = true

## Whether to automatically run validations when saving a script.
## If this is set to [code]false[/code], users will need to manually trigger validations.
@export var validate_on_save: bool = true

@export_group("Notification settings")
## Whether to show the welcome dialog when enabling the plugin.
@export var show_welcome_dialog: bool = true
## Whether to show debug prints in the output console.
@export var show_debug_prints: bool = false
## Whether to show toast notifications for important events.
@export var show_toasts: bool = true
## Whether to show a severity glyph (info, warning, error) in
## the dock title.
@export var show_severity_glyph_in_dock_title: bool = true

@export_group("Validation settings")
## Whether to treat warnings as errors in validation results.
## (Has no effect on the CLI; see
## [member GodotDoctorValidationSuite.treat_warnings_as_errors] instead).
@export var treat_warnings_as_errors: bool = false
## Use default validations on [code]@export[/code] variables
## (instance validity and non-empty strings).
@export var use_default_validations: bool = true
## A list of scripts that should be ignored by Godot Doctor's default validations.
@export var default_validation_ignore_list: Array[Script] = []

@export_group("CLI settings")

## The validation suites that should be run when executing the CLI.
@export var validation_suites: Array[GodotDoctorValidationSuite] = []:
	set(value):
		validation_suites = value
		if not _has_validation_suites() and export_xml_report:
			export_xml_report = false
		notify_property_list_changed()
## Maximum time (in seconds) to wait for the editor to signal readiness before
## starting the CLI runner anyway. This is a temporary workaround which is required
## because there currently is no surefire way to detect when the editor is ready.
## Recommended is to leave this on the default value, but it can be increased
## depending on your running environment.
## Set to [code]0[/code] to disable.
@export_range(0, 120, 1, "suffix:seconds") var fallback_cli_delay_before_start: float = 5.0
## Maximum time (in seconds) to allow the CLI runner to execute before force-quitting
## with exit code [code]1[/code]. This prevents the process from hanging indefinitely
## if validation gets stuck. Set to [code]0[/code] to disable.
@export_range(0, 300, 1, "suffix:seconds") var fallback_cli_delay_before_quit: float = 30.0
## Whether to export a JUnit-style XML report after CLI validation completes.
@export var export_xml_report: bool = false:
	set(value):
		if value and not _has_validation_suites():
			value = false
		if export_xml_report == value:
			return
		export_xml_report = value
		notify_property_list_changed()
## The output filename used for the XML report.
@export var xml_report_filename: String = "godot_doctor_report.xml"
## The directory where the XML report is written.
@export_dir var xml_report_output_dir: String = "res://tests/reports/"


## Returns whether any non-null validation suites are assigned to [member validation_suites].
func _has_validation_suites() -> bool:
	return validation_suites.any(func(suite): return suite != null)


## Editor callback that validates property values and updates their usage flags.
## This is used to disable the [member export_xml_report], [member xml_report_filename],
## and [member xml_report_output_dir] properties when they are not applicable
## based on the current settings.
func _validate_property(property: Dictionary) -> void:
	var property_name: String = property.name
	if (
		(
			property_name
			in [
				"export_xml_report",
				"fallback_cli_delay_before_start",
				"fallback_cli_delay_before_quit"
			]
		)
		and not _has_validation_suites()
	):
		property.usage = property.usage | PROPERTY_USAGE_READ_ONLY
	elif (
		property_name in ["xml_report_filename", "xml_report_output_dir"] and not export_xml_report
	):
		property.usage = property.usage | PROPERTY_USAGE_READ_ONLY
	else:
		property.usage = property.usage & ~PROPERTY_USAGE_READ_ONLY
