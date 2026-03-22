## A dock for GodotDoctor that displays validation warnings.
## Warnings can be related to nodes or resources.
## Clicking on a warning will select the node in the scene tree
## or open the resource in the inspector.
## Used by [GodotDoctorEditorValidationReporter] to show validation warnings.
@tool
class_name GodotDoctorDock
extends Control

#gdlint: disable=max-line-length

const DOCK_TITLE: String = "Godot Doctor"

## Path to the info severity icon asset.
const SEVERITY_INFO_ICON_PATH: StringName = "res://addons/godot_doctor/editor/dock/warning/assets/icon/info.png"
## Path to the warning severity icon asset.
const SEVERITY_WARNING_ICON_PATH: StringName = "res://addons/godot_doctor/editor/dock/warning/assets/icon/warning.png"
## Path to the error severity icon asset.
const SEVERITY_ERROR_ICON_PATH: StringName = "res://addons/godot_doctor/editor/dock/warning/assets/icon/error.png"

## A path to the scene used for node validation warnings.
const NODE_WARNING_SCENE_PATH: StringName = "res://addons/godot_doctor/editor/dock/warning/node_validation_warning.tscn"
## A path to the scene used for resource validation warnings.
const RESOURCE_WARNING_SCENE_PATH: StringName = "res://addons/godot_doctor/editor/dock/warning/resource_validation_warning.tscn"
#gdlint: enable=max-line-length

## The "Validate Now" button that triggers manual validation.
@export var _validate_now_button: Button

## The scene root used as reference when resolving node paths for warnings.
var scene_root_for_validations: Node = null

## Whether the dock title needs to be updated
var _title_is_dirty: bool = false

## Internal list of current validation messages,
## used to keep track of the number of messages
## and to filter on the highest severity level.
var _current_messages: Array[GodotDoctorValidationMessage] = []

## The container that holds all warning instances.
@onready var _error_holder: VBoxContainer = $ScrollContainer/ErrorHolder


## Connects the validate-now button signal when the dock enters the scene tree.
func _enter_tree() -> void:
	GodotDoctorNotifier.print_debug(
		"Entering scene tree. Connecting signals and adding dock to editor.", self
	)
	_validate_now_button.pressed.connect(_on_validate_now_button_pressed)

	# Mark title as dirty here to ensure that it updates when dragging to a new dock slot.
	_mark_title_dirty()


## Disconnects the validate-now button signal when the dock exits the scene tree.
func _exit_tree() -> void:
	GodotDoctorNotifier.print_debug(
		"Exiting scene tree. Disconnecting signals and removing dock from editor.", self
	)
	if _validate_now_button.pressed.is_connected(_on_validate_now_button_pressed):
		_validate_now_button.pressed.disconnect(_on_validate_now_button_pressed)


## Triggers validation of the current scene root and edited resource when the button is pressed.
func _on_validate_now_button_pressed() -> void:
	GodotDoctorNotifier.print_debug("Validate Now button pressed. Triggering validation.", self)
	GodotDoctorPlugin.instance.validate_scene_root_and_edited_resource()


## Adds a node-related message to the dock for [param origin_node].
## Displays [param validation_message] with the appropriate severity icon.
## Clicking the entry selects [param origin_node] in the scene tree.
func add_node_validation_message(
	node_ancestor_path: String, validation_message: GodotDoctorValidationMessage
) -> void:
	GodotDoctorNotifier.print_debug(
		(
			"Adding node warning to dock for node: %s, message: %s"
			% [node_ancestor_path, validation_message.message]
		)
	)
	_current_messages.append(validation_message)
	var warning_instance: GodotDoctorNodeValidationWarning = (
		load(NODE_WARNING_SCENE_PATH).instantiate() as GodotDoctorNodeValidationWarning
	)
	var icon_path: String = _get_warning_icon_path_for_severity(validation_message.severity_level)
	warning_instance.icon.texture = load(icon_path) as Texture2D

	var node_ancestors: PackedStringArray = node_ancestor_path.split("/")
	var current_path: String = ""
	for i in range(1, node_ancestors.size()):
		var node_name: String = node_ancestors[i]
		current_path += node_name + "/"
	var relative_path = current_path.trim_suffix("/")

	warning_instance.origin_node = scene_root_for_validations.get_node(relative_path)
	warning_instance.origin_node_root = scene_root_for_validations
	warning_instance.label.text = validation_message.message
	_error_holder.add_child(warning_instance)
	_mark_title_dirty()


## Adds a resource-related message to the dock for [param origin_resource].
## Displays [param validation_message] with the appropriate severity icon.
## Clicking the entry opens [param origin_resource] in the inspector.
func add_resource_validation_message(
	resource_path: String, validation_message: GodotDoctorValidationMessage
) -> void:
	GodotDoctorNotifier.print_debug(
		(
			"Adding resource warning to dock for resource: %s, message: %s"
			% [resource_path, validation_message.message]
		)
	)
	_current_messages.append(validation_message)
	var warning_instance: GodotDoctorResourceValidationWarning = (
		load(RESOURCE_WARNING_SCENE_PATH).instantiate() as GodotDoctorResourceValidationWarning
	)
	var icon_path: String = _get_warning_icon_path_for_severity(validation_message.severity_level)
	warning_instance.icon.texture = load(icon_path) as Texture2D
	warning_instance.origin_resource = ResourceLoader.load(resource_path) as Resource
	warning_instance.label.text = validation_message.message
	_error_holder.add_child(warning_instance)
	_mark_title_dirty()


## Removes all warnings from the dock.
func clear_errors() -> void:
	GodotDoctorNotifier.print_debug("Clearing all warnings from the dock.", self)
	var children: Array[Node] = _error_holder.get_children()
	for child in children:
		child.free()
	_mark_title_dirty()
	_current_messages.clear()


## Updates the dock title on next idle frame to indicate the current number of messages.
## Does nothing if the title is already marked dirty to avoid redundant updates.
func _mark_title_dirty() -> void:
	if _title_is_dirty:
		return
	GodotDoctorNotifier.print_debug("Marking title as dirty for update.", self)
	_title_is_dirty = true
	# Call deffered to ensure that multiple calls to _mark_title_dirty
	# in the same frame only trigger one title update.
	_update_title.call_deferred()


## Updates the dock title to include the current number of messages.
func _update_title() -> void:
	var editor_dock := get_parent() as EditorDock
	if not editor_dock:
		GodotDoctorNotifier.print_debug(
			"Could not find parent EditorDock for new_title update.", self
		)
		return
	var tab_container := editor_dock.get_parent() as TabContainer
	if not tab_container:
		GodotDoctorNotifier.print_debug(
			"Could not find parent TabContainer for new_title update.", self
		)
		return
	var tab_index: int = tab_container.get_tab_idx_from_control(editor_dock)

	var new_title: String = (
		"%s %s (%s)" % [_get_indicator_glyph(), DOCK_TITLE, _current_messages.size()]
	)
	tab_container.set_tab_title(tab_index, new_title)
	_title_is_dirty = false


func _get_indicator_glyph() -> String:
	var settings: GodotDoctorSettings = GodotDoctorPlugin.instance.settings

	if not settings.show_severity_glyph_in_dock_title:
		return ""

	if _current_messages.is_empty():
		return "✅"

	var promoted_severity_levels: Array[ValidationCondition.Severity] = (
		GodotDoctorValidationMessage
		. map_to_promoted_severity_levels(settings.treat_warnings_as_errors, _current_messages)
	)
	var highest_severity_level: int = promoted_severity_levels.max()
	match highest_severity_level:
		ValidationCondition.Severity.INFO:
			return "ℹ️"
		ValidationCondition.Severity.WARNING:
			return "⚠️"
		ValidationCondition.Severity.ERROR:
			return "❌"
		_:
			push_error(
				(
					"No indicator glyph defined for severity level: "
					+ ValidationCondition.Severity.keys()[highest_severity_level]
				)
			)
			return ""


## Returns the icon asset path corresponding to [param severity_level].
func _get_warning_icon_path_for_severity(
	severity_level: ValidationCondition.Severity
) -> StringName:
	match severity_level:
		ValidationCondition.Severity.INFO:
			return SEVERITY_INFO_ICON_PATH
		ValidationCondition.Severity.WARNING:
			if GodotDoctorPlugin.instance.settings.treat_warnings_as_errors:
				return SEVERITY_ERROR_ICON_PATH
			return SEVERITY_WARNING_ICON_PATH
		ValidationCondition.Severity.ERROR:
			return SEVERITY_ERROR_ICON_PATH
		_:
			push_error(
				(
					"No scene defined for node warning with severity level: "
					+ ValidationCondition.Severity.keys()[severity_level]
				)
			)
			return ""
