## A collection of [GodotDoctorNodeValidationCollection] for scene paths.
class_name GodotDoctorSceneValidationCollection
extends GodotDoctorValidationCollection

## A dictionary mapping scene paths to their [GodotDoctorNodeValidationCollection].
## [code]key[/code] is the scene path as a [String], and [code]value[/code] is
## [code]Array[lb]GodotDoctorNodeValidationCollection[rb][/code].
var _scene_path_to_node_validation_collection_map: Dictionary = {}


## Adds [param node_validation_collection] for [param scene_res_path] to the collection.
## Fails if [param scene_res_path] already has a node validation collection in the collection.
func add_node_validation_collection(
	scene_res_path: String, node_validation_collection: GodotDoctorNodeValidationCollection
) -> void:
	GodotDoctorNotifier.print_debug(
		"Adding node validation collection for scene: %s to collection %s" % [scene_res_path, self],
		self
	)
	_add_and_fail_if_already_has(
		scene_res_path, node_validation_collection, _scene_path_to_node_validation_collection_map
	)


## Returns the map of scene paths to their [GodotDoctorNodeValidationCollection]s.
func get_scene_path_to_node_validation_collection_map() -> Dictionary:
	return _scene_path_to_node_validation_collection_map
