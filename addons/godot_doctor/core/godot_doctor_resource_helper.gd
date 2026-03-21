## A utility class providing helpers for resolving resource paths.
## Converts [code]uid://[/code] paths to [code]res://[/code] paths when needed.
class_name GodotDoctorResourceHelper


## Converts [param path] from a uid:// path to a res:// path if needed,
## otherwise returns it as-is if it's already a res:// path.
## If the path is not valid, logs an error and exits with failure if in headless mode.
static func to_res_path(path: String) -> String:
	if path.begins_with("res://"):
		return path
	if not path.begins_with("uid://"):
		push_error("Path is not a valid res:// or uid:// path: %s. Cannot load resource." % path)
		GodotDoctorPlugin.instance.quit_with_fail_early_if_headless()
		return ""

	var resolved_path: String = ResourceUID.get_id_path(ResourceUID.text_to_id(path))
	if resolved_path == null:
		push_error("Failed to resolve uid path: %s" % path)
		GodotDoctorPlugin.instance.quit_with_fail_early_if_headless()
		return ""
	return resolved_path
