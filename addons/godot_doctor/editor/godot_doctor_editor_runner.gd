## Handles all editor-mode setup, dock management, and editor-triggered validation.
## Creates an EditorValidationReporter and GodotDoctorValidator.
## Accesses settings and editor API via the GodotDoctorPlugin singleton.
class_name GodotDoctorEditorRunner

#gdlint: disable=max-line-length
const VALIDATOR_DOCK_SCENE_PATH: String = "res://addons/godot_doctor/editor/dock/godot_doctor_dock.tscn"
const PLUGIN_WELCOME_MESSAGE: String = "Godot Doctor is ready! 👨🏻‍⚕️🩺\nThe plugin has succesfully been enabled. You'll now see the Godot Doctor dock in your editor.\nYou can change its default position in the settings resource (addons/godot_doctor/settings).\nYou can also disable this dialog there.\nBasic usage instructions are available in the README or on the GitHub repository.\nPlease report any issues, bugs, or feature requests on GitHub.\nHappy developing!\n- CodeVogel 🐦"
const PLUGIN_REPOSITORY_URL: String = "https://github.com/codevogel/godot_doctor"
#gdlint: enable=max-line-length

var dock: GodotDoctorDock
var reporter: EditorValidationReporter
var validator: GodotDoctorValidator

# ============================================================================
# LIFECYCLE - Dock setup and teardown
# ============================================================================


## Adds the dock to the editor and creates the reporter and validator.
func _init() -> void:
	GodotDoctorNotifier.print_debug("Adding dock to editor...")
	dock = preload(VALIDATOR_DOCK_SCENE_PATH).instantiate() as GodotDoctorDock
	GodotDoctorPlugin.instance.add_control_to_dock(
		_settings_dock_slot_to_editor_dock_slot(
			GodotDoctorPlugin.instance.settings.default_dock_position
		),
		dock
	)
	reporter = EditorValidationReporter.new(dock)
	validator = GodotDoctorValidator.new(reporter)


## Removes the dock from the editor and frees it.
func teardown() -> void:
	GodotDoctorNotifier.print_debug("Removing dock from editor...")
	GodotDoctorPlugin.instance.remove_control_from_docks(dock)
	dock.free()
	dock = null


# ============================================================================
# VALIDATION - Editor-triggered validation entry point
# ============================================================================


## Validates the current scene root and any edited resource, then emits validation_complete.
## NOTE: This should not be used in headless mode; use GodotDoctorCliRunner instead.
func validate_scene_root_and_edited_resource() -> void:
	GodotDoctorNotifier.print_debug("Validating scene root and edited resource...")

	dock.clear_errors()

	var current_edited_scene_root: Node = EditorInterface.get_edited_scene_root()
	if current_edited_scene_root != null:
		validator.validate_scene_root(current_edited_scene_root)
	else:
		GodotDoctorNotifier.print_debug("No current edited scene root. Skipping scene validation.")

	var edited_object: Object = EditorInterface.get_inspector().get_edited_object()
	if edited_object is Resource:
		var resource_script: Script = edited_object.get_script()
		if resource_script != null:
			validator.validate_resource(edited_object as Resource)
		else:
			GodotDoctorNotifier.print_debug(
				"Edited resource %s has no script. Skipping resource validation." % edited_object
			)

	GodotDoctorNotifier.print_debug("Emitting validation complete signal...")
	GodotDoctorPlugin.instance.validation_complete.emit()


# ============================================================================
# UI - Welcome dialog
# ============================================================================


## Shows the welcome dialog on first plugin enable.
func show_welcome_dialog() -> void:
	GodotDoctorNotifier.print_debug("Showing welcome dialog...")
	var dialog: AcceptDialog = AcceptDialog.new()
	dialog.title = "Godot Doctor"
	dialog.dialog_text = ""
	var vbox: VBoxContainer = VBoxContainer.new()
	dialog.add_child(vbox)
	var label: Label = Label.new()
	label.text = PLUGIN_WELCOME_MESSAGE
	vbox.add_child(label)
	var link_button: LinkButton = LinkButton.new()
	link_button.text = "GitHub Repository"
	link_button.uri = PLUGIN_REPOSITORY_URL
	vbox.add_child(link_button)

	EditorInterface.get_base_control().add_child(dialog)
	dialog.exclusive = false
	dialog.popup_centered()


# ============================================================================
# UTILITY - Dock slot mapping
# ============================================================================


## Converts the custom DockSlot enum from settings to the EditorPlugin.DockSlot enum.
#gdlint:disable = max-returns
func _settings_dock_slot_to_editor_dock_slot(
	dock_slot: GodotDoctorSettings.DockSlot
) -> EditorPlugin.DockSlot:
	match dock_slot:
		GodotDoctorSettings.DockSlot.DOCK_SLOT_LEFT_UL:
			return EditorPlugin.DockSlot.DOCK_SLOT_LEFT_UL
		GodotDoctorSettings.DockSlot.DOCK_SLOT_LEFT_BL:
			return EditorPlugin.DockSlot.DOCK_SLOT_LEFT_BL
		GodotDoctorSettings.DockSlot.DOCK_SLOT_LEFT_UR:
			return EditorPlugin.DockSlot.DOCK_SLOT_LEFT_UR
		GodotDoctorSettings.DockSlot.DOCK_SLOT_LEFT_BR:
			return EditorPlugin.DockSlot.DOCK_SLOT_LEFT_BR
		GodotDoctorSettings.DockSlot.DOCK_SLOT_RIGHT_UL:
			return EditorPlugin.DockSlot.DOCK_SLOT_RIGHT_UL
		GodotDoctorSettings.DockSlot.DOCK_SLOT_RIGHT_BL:
			return EditorPlugin.DockSlot.DOCK_SLOT_RIGHT_BL
		GodotDoctorSettings.DockSlot.DOCK_SLOT_RIGHT_UR:
			return EditorPlugin.DockSlot.DOCK_SLOT_RIGHT_UR
		GodotDoctorSettings.DockSlot.DOCK_SLOT_RIGHT_BR:
			return EditorPlugin.DockSlot.DOCK_SLOT_RIGHT_BR
		_:
			return EditorPlugin.DockSlot.DOCK_SLOT_RIGHT_BL  # Default fallback
#gdlint:enable = max-returns
