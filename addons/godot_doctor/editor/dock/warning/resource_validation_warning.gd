## A warning that is associated with a `Resource`.
## Clicking on the warning will open the `Resource` in the inspector and navigate to it
## in the FileSystem dock.
## Used by GodotDoctor to show warnings related to resources.
@tool
class_name ResourceValidationWarning
extends ValidationWarning

## The resource that caused the warning.
var origin_resource: Resource


## Select the origin of the warning by opening the resource in the inspector
## and navigating to it in the FileSystem dock.
func _select_origin() -> void:
	EditorInterface.edit_resource(origin_resource)
	EditorInterface.get_file_system_dock().navigate_to_path(origin_resource.resource_path)
