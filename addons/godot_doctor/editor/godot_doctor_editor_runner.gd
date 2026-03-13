## Handles all editor-mode setup, _dock management, and editor-triggered validation.
## Creates an GodotDoctorEditorValidationReporter and GodotDoctorValidator.
## Accesses settings and editor API via the GodotDoctorPlugin singleton.
class_name GodotDoctorEditorRunner

#gdlint: disable=max-line-length
const VALIDATOR_DOCK_SCENE_PATH: String = "res://addons/godot_doctor/editor/dock/godot_doctor_dock.tscn"
#gdlint: enable=max-line-length

## The dock instance added to the editor for displaying validation results.
var _dock: GodotDoctorDock
## The reporter responsible for receiving validation messages and updating the _dock UI accordingly.
var _reporter: GodotDoctorEditorValidationReporter
## The validator responsible for performing validation on scenes
## and resources and reporting results via the _reporter.
var _validator: GodotDoctorValidator


## Adds the _dock to the editor and creates the _reporter and _validator.
func _init() -> void:
	GodotDoctorNotifier.print_debug("Adding _dock to editor...")
	_dock = preload(VALIDATOR_DOCK_SCENE_PATH).instantiate() as GodotDoctorDock
	GodotDoctorPlugin.instance.add_control_to_dock(
		_settings_dock_slot_to_editor_dock_slot(
			GodotDoctorPlugin.instance.settings.default_dock_position
		),
		_dock
	)
	_reporter = GodotDoctorEditorValidationReporter.new(_dock)
	_validator = GodotDoctorValidator.new(_reporter)


## Removes the _dock from the editor and frees it.
func teardown() -> void:
	GodotDoctorNotifier.print_debug("Removing _dock from editor...")
	GodotDoctorPlugin.instance.remove_control_from_docks(_dock)
	_dock.free()
	_dock = null


## Validates the current scene root and any edited resource, then emits
## [GodotDoctorPlugin.validation_complete]
func validate_scene_root_and_edited_resource() -> void:
	GodotDoctorNotifier.print_debug("Validating scene root and edited resource...")

	_dock.clear_errors()

	# Grab the current edited scene root and validate it
	var current_edited_scene_root: Node = EditorInterface.get_edited_scene_root()
	if current_edited_scene_root != null:
		_validator.validate_scene_root(current_edited_scene_root)
	else:
		GodotDoctorNotifier.print_debug("No current edited scene root. Skipping scene validation.")

	# Grab the current edited resource and validate it if it's a Resource with a script
	var edited_object: Object = EditorInterface.get_inspector().get_edited_object()
	if edited_object is Resource:
		var resource_script: Script = edited_object.get_script()
		if resource_script != null:
			_validator.validate_resource(edited_object as Resource)
		else:
			GodotDoctorNotifier.print_debug(
				"Edited resource %s has no script. Skipping resource validation." % edited_object
			)

	GodotDoctorNotifier.print_debug("Emitting validation complete signal...")
	GodotDoctorPlugin.instance.validation_complete.emit()


## Converts [param dock_slot] from the [GodotDoctorSettings.DockSlot] enum
## to the corresponding [EditorPlugin.DockSlot] value.
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
