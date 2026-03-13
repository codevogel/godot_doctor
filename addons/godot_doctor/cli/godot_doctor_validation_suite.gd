@tool
class_name GodotDoctorValidationSuite
extends Resource

## Whether to treat warnings as errors when validating the scenes and resources in this suite.
@export var treat_warnings_as_errors: bool = false

## Set this to true to automatically generate the suite contents
## based on the generative suite content filters below.
## This is useful to avoid having to manually maintain
## the list of scenes and resources to validate in a suite.
@export var generate_suite_contents: bool = false

@export_group("Generate Suite Filters")
## Directories to include when generating the suite contents
## ([member generate_suite_contents] must be enabled).
## If this has at least one directory listed, only scenes and resources in that directory
## (and any of its subdirectories) will be included in the generated suite contents.
## If this is empty, defaults to including the entire project directory.
## NOTE: Scenes and resources in directories listed in [member directories_to_exclude],
## [member scenes_to_exclude], and [member resources_to_exclude] will still be excluded
## from the generated suite contents
@export_dir var directories_to_include: Array[String] = []
## Directories to exclude when generating the suite contents
## ([member generate_suite_contents] must be enabled).
## Scenes and resources in these directories will not be included in the generated suite contents,
## overriding the [member directories_to_include] property.
@export_dir var directories_to_exclude: Array[String] = []
## Specific scenes to exclude when generating the suite contents
## ([member generate_suite_contents] must be enabled).
## Scenes in this list will not be included in the generated suite contents,
## overriding the [member directories_to_include] property.
@export_file("*.tscn", "*.scn") var scenes_to_exclude: Array[String] = []
## Specific resources to exclude when generating the suite contents
## ([member generate_suite_contents] must be enabled).
## Resources in this list will not be included in the generated suite contents,
## overriding the [member directories_to_include] property.
@export_file("*.tres", "*.res") var resources_to_exclude: Array[String] = []

@export_group("Suite Contents")
## The paths to the scenes to validate in this suite.
## NOTE: If [member generate_suite_contents] is enabled, the contents of this list will be ignored
## and the suite contents will be generated based on the
## [member directories_to_include], [member directories_to_exclude],
## [member scenes_to_exclude], and [member resources_to_exclude] properties.
@export_file("*.tscn", "*.scn") var _scenes: Array[String] = []
## The paths to the resources to validate in this suite.
## NOTE: If [member generate_suite_contents] is enabled, the contents of this list will be ignored
## and the suite contents will be generated based on the
## [member directories_to_include], [member directories_to_exclude],
## [member scenes_to_exclude], and [member resources_to_exclude] properties.
@export_file("*.tres", "*.res") var _resources: Array[String] = []


## Get the paths to the scenes to validate in this suite.
func get_scenes() -> Array[String]:
	if generate_suite_contents:
		return _generate_suite_scenes()
	return _scenes


## Get the paths to the resources to validate in this suite.
func get_resources() -> Array[String]:
	if generate_suite_contents:
		return _generate_suite_resources()
	return _resources


## Generates this suite's scenes based on the generative suite content filter properties.
func _generate_suite_scenes() -> Array[String]:
	return _collect_files(["*.tscn", "*.scn"], scenes_to_exclude)


## Generates this suite's resources based on the generative suite content filter properties.
func _generate_suite_resources() -> Array[String]:
	return _collect_files(["*.tres", "*.res"], resources_to_exclude)


## Recursively collects files matching the given [param extensions] (accepting wildcard patterns)
## in all [member directories_to_include], exluding any files in [param files_to_exclude]
## or in any [member directories_to_exclude].
func _collect_files(extensions: Array[String], files_to_exclude: Array[String]) -> Array[String]:
	var result: Array[String] = []
	if directories_to_include.size() == 0:
		directories_to_include.append("res://")
	for dir in directories_to_include:
		_collect_files_recursive(dir, extensions, files_to_exclude, result)
	return result


## Helper method for [method _collect_files] that recursively collects
## any files in [param dir_path] matching [param extensions] (accepting wildcard patterns),
## excluding any files in [param files_to_exclude] or in any [member directories_to_exclude],
## and appends them to [param result].
func _collect_files_recursive(
	dir_path: String,
	extensions: Array[String],
	files_to_exclude: Array[String],
	result: Array[String]
) -> void:
	if directories_to_exclude.any(func(excluded): return dir_path.begins_with(excluded)):
		return
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		push_warning("GodotDoctorValidationSuite: Could not open directory: %s" % dir_path)
		return
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		var full_path: String = dir_path.path_join(file_name)
		if dir.current_is_dir():
			if file_name != "." and file_name != "..":
				_collect_files_recursive(full_path, extensions, files_to_exclude, result)
		else:
			var matches_ext: bool = extensions.any(func(ext): return file_name.match(ext))
			var is_resource: bool = file_name.match("*.tres") or file_name.match("*.res")
			if matches_ext and full_path not in files_to_exclude:
				if not is_resource or _resource_has_script(full_path):
					result.append(full_path)
		file_name = dir.get_next()
	dir.list_dir_end()


## Helper method to check if a resource at [param path] has a script attached.
func _resource_has_script(path: String) -> bool:
	var resource: Resource = ResourceLoader.load(path)
	return resource != null and resource.get_script() != null
