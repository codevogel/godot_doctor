@tool
extends ValidationWarning
class_name ResourceValidationWarning

var origin_resource: Resource


func _select_origin() -> void:
	EditorInterface.edit_resource(origin_resource)
	EditorInterface.get_file_system_dock().navigate_to_path(origin_resource.resource_path)
