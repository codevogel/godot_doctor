## A resource that holds settings for GodotDoctor.
## Used by GodotDoctor to store user preferences.
class_name GodotDoctorSettings
extends Resource

## Enum for dock positions in the Godot editor.
## These correspond to the dock slots available in the Godot editor.
## Reference:
## https://docs.godotengine.org/en/4.5/classes/class_editorplugin.html#enum-editorplugin-dockslot
enum DockSlot {
	DOCK_SLOT_LEFT_UL = 0,
	DOCK_SLOT_LEFT_BL = 1,
	DOCK_SLOT_LEFT_UR = 2,
	DOCK_SLOT_LEFT_BR = 3,
	DOCK_SLOT_RIGHT_UL = 4,
	DOCK_SLOT_RIGHT_BL = 5,
	DOCK_SLOT_RIGHT_UR = 6,
	DOCK_SLOT_RIGHT_BR = 7,
}

## The default position of the GodotDoctor dock in the editor.
@export var default_dock_position: DockSlot = DockSlot.DOCK_SLOT_LEFT_BR

## Whether to automatically run validations when saving a script.
## If this is set to [false], users will need to manually trigger validations.
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
## (This has no effect on the CLI, see
## [GodotDoctorValidationSuite.treat_warnings_as_errors] instead).
@export var treat_warnings_as_errors: bool = false
## Use default validations on `@export` variables (is instance valid, and non-empty strings)
@export var use_default_validations: bool = true
## A list of scripts that should be ignored by Godot Doctor's default validations.
@export var default_validation_ignore_list: Array[Script] = []

@export_group("CLI settings")
## The delay (in seconds) before running the CLI.
## This can help ensure that the editor is fully initialized before the CLI runs.
@export var delay_before_running_cli: float = 0.5
## The validation suites that should be run when executing the CLI.
@export var validation_suites: Array[GodotDoctorValidationSuite] = []
