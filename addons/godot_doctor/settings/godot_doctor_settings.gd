## A resource that holds settings for the [GodotDoctorPlugin].
## Used by [GodotDoctorPlugin] to store and access user preferences.
class_name GodotDoctorSettings
extends Resource

## The default position of the GodotDoctor dock in the editor.
@export var default_dock_position: EditorPlugin.DockSlot = EditorPlugin.DockSlot.DOCK_SLOT_LEFT_BR

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
## The delay (in seconds) before running the CLI.
## This can help ensure that the editor is fully initialized before the CLI runs.
@export var delay_before_running_cli: float = 0.5
## The validation suites that should be run when executing the CLI.
@export var validation_suites: Array[GodotDoctorValidationSuite] = []

@export_group("XML Report")
## Whether to export a JUnit-style XML report after CLI validation completes.
@export var export_xml_report: bool = false
## The output filename used for the XML report.
@export var xml_report_filename: String = "godot_doctor_report.xml"
## The directory where the XML report is written.
@export_dir var xml_report_output_dir: String = "res://tests/reports/"
