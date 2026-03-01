## Resource used by the CLI interface. It holds lists of all Scenes and Resources that are to be
## validated when running Godot Doctor from the command line,
## as well as settings on how to treat Warnings in the validation process.
@tool
class_name CLIValidationSettings extends Resource

enum WarningBehaviour { IGNORE_WARNINGS, FAIL_ON_WARNINGS }

@export var warning_behaviour: WarningBehaviour

## List of all Validation Suites to process in batch.
@export var suites: Array[ValidationSuite]

@export_group("Suite Generation Exclusions")
## Directories (e.g. "res://addons/") whose contents are skipped when a suite
## has [member ValidationSuite.include_all_generatively] enabled.
@export_dir var dirs_to_exclude: Array[String]

## Individual scene files to skip during generative discovery.
@export_file("*.tscn", "*.scn") var scenes_to_exclude: Array[String]

## Individual resource files to skip during generative discovery.
## Any resources that do not have scripts attached to them are
## excluded from generative discovery by default.
## (i.e. Materials, Textures, etc.)
@export_file("*.tres", "*.res") var resources_to_exclude: Array[String]


## Returns true if [param path] should be excluded from generative collection,
## based on the exclusion lists on this settings resource.
func is_excluded(path: String) -> bool:
	for entry in scenes_to_exclude:
		if _resolve_uid_to_path(entry) == path:
			return true
	for entry in resources_to_exclude:
		if _resolve_uid_to_path(entry) == path:
			return true
	for dir in dirs_to_exclude:
		var normalized := dir if dir.ends_with("/") else dir + "/"
		if path.begins_with(normalized):
			return true
	return false


## Resolves a UID string (e.g. "uid://abc123") to its corresponding resource path.
## Returns the input unchanged if it is already a plain path.
func _resolve_uid_to_path(uid_or_path: String) -> String:
	if uid_or_path.begins_with("uid://"):
		var uid := ResourceUID.text_to_id(uid_or_path)
		if ResourceUID.has_id(uid):
			return ResourceUID.get_id_path(uid)
	return uid_or_path
