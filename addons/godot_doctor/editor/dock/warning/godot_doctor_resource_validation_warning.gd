## A warning associated with a [Resource].
## Clicking the warning opens [member origin_resource] in the inspector
## and navigates to it in the FileSystem dock.
## Used by [GodotDoctorDock] to show validation warnings related to resources.
@tool
class_name GodotDoctorResourceValidationWarning
extends GodotDoctorValidationWarning

## The resource that caused the warning.
var origin_resource: Resource


## Opens [member origin_resource] in the inspector and navigates to it in the FileSystem dock.
func _select_origin() -> void:
	EditorInterface.edit_resource(origin_resource)
	EditorInterface.get_file_system_dock().navigate_to_path(origin_resource.resource_path)
