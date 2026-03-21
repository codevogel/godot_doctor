## Base class for collecting and organising validation messages produced during a run.
## Maintains collections of scene, node, and resource validation results as signals
## arrive from the active [GodotDoctorRunner] and [GodotDoctorValidator].
@abstract class_name GodotDoctorValidationCollector

## The resource path of the scene currently being validated.
var _current_scene_res_path: String = ""

## The resource currently being validated.
var _current_resource: Resource = null

## The scene validation collection being built during the current scene collection pass.
var _current_scene_validation_collection: GodotDoctorSceneValidationCollection = null
## The node validation collection being built during the current node collection pass.
var _current_node_validation_collection: GodotDoctorNodeValidationCollection = null
## The resource validation collection being built during the current resource collection pass.
var _current_resource_validation_collection: GodotDoctorResourceValidationCollection = null


## Called when a scene collection pass begins; creates a new [GodotDoctorSceneValidationCollection].
func on_started_scene_collection() -> void:
	_current_scene_validation_collection = GodotDoctorSceneValidationCollection.new()
	GodotDoctorNotifier.print_debug(
		"Created new scene validation collection %s." % _current_scene_validation_collection, self
	)


## Called when a scene collection pass ends; clears the current node collection.
func on_finished_scene_collection() -> void:
	GodotDoctorNotifier.print_debug(
		(
			"Clearing current node validation collection (was %s)"
			% _current_node_validation_collection
		),
		self
	)
	_current_node_validation_collection = null


## Called when a resource collection pass begins; creates a new
## [GodotDoctorResourceValidationCollection].
func on_started_resource_collection() -> void:
	_current_resource_validation_collection = GodotDoctorResourceValidationCollection.new()
	GodotDoctorNotifier.print_debug(
		"Created new resource validation collection %s." % _current_resource_validation_collection,
		self
	)


## Called when a resource collection pass ends.
func on_finished_resource_collection() -> void:
	pass


## Called when a node collection pass begins; creates a new [GodotDoctorNodeValidationCollection].
func on_started_node_collection() -> void:
	_current_node_validation_collection = GodotDoctorNodeValidationCollection.new()
	GodotDoctorNotifier.print_debug(
		"Created new node validation collection %s." % _current_node_validation_collection, self
	)


## Called when a node collection pass ends.
func on_finished_node_collection() -> void:
	pass


## Called when validation starts for the scene at [param scene_res_path].
func on_started_run_for_scene_res_path(scene_res_path: String) -> void:
	GodotDoctorNotifier.print_debug("Setting current scene_res_path to %s" % scene_res_path, self)
	_current_scene_res_path = scene_res_path


## Called when validation finishes for [param _scene_res_path].
## Adds the current [GodotDoctorNodeValidationCollection] to the scene collection.
func on_finished_run_for_scene_res_path(_scene_res_path: String) -> void:
	GodotDoctorNotifier.print_debug(
		"Clearing current scene_res_path (was %s)" % _current_scene_res_path, self
	)
	GodotDoctorNotifier.print_debug(
		(
			"Adding node validation collection %s to scene collection %s"
			% [_current_node_validation_collection, _current_scene_validation_collection]
		),
		self
	)
	_current_scene_validation_collection.add_node_validation_collection(
		_current_scene_res_path, _current_node_validation_collection
	)
	_current_scene_res_path = ""


## Called when validation starts for [param resource].
func on_started_run_for_resource(resource: Resource) -> void:
	GodotDoctorNotifier.print_debug("Setting current resource to %s" % resource, self)
	_current_resource = resource


## Called when validation finishes for [param _resource].
func on_finished_run_for_resource(_resource: Resource) -> void:
	GodotDoctorNotifier.print_debug("Clearing current resource (was %s)" % _current_resource, self)
	_current_resource = null


## Called when [param node] has been validated; stores [param messages] in the current
## node collection.
func on_validated_node(node: Node, messages: Array[GodotDoctorValidationMessage]) -> void:
	GodotDoctorNotifier.print_debug(
		(
			"Adding validation for node %s to current node validation collection %s"
			% [node, _current_node_validation_collection]
		),
		self
	)
	var node_ancestor_path: String = _get_node_ancestor_path(node)
	_current_node_validation_collection.add_node_validation(node_ancestor_path, messages)


## Returns a human-readable path string for [param node] by walking up its ancestor chain.
static func _get_node_ancestor_path(node: Node) -> String:
	var names: Array[String] = []
	var current: Node = node

	while current != null:
		names.push_front(current.name)

		if current.owner == null:
			break

		current = current.get_parent()

	return "/".join(names)


## Called when [param resource] has been validated; stores [param messages] in the current
## resource collection.
func on_validated_resource(
	resource: Resource, messages: Array[GodotDoctorValidationMessage]
) -> void:
	GodotDoctorNotifier.print_debug(
		(
			"Adding validation for resource %s to current resource validation collection %s"
			% [resource, _current_resource_validation_collection]
		),
		self
	)
	var resource_path: String = resource.resource_path
	_current_resource_validation_collection.add_resource_validation(resource_path, messages)


## Clears all active validation collections.
func clear_collections() -> void:
	_current_scene_validation_collection = null
	_current_node_validation_collection = null
	_current_resource_validation_collection = null
	_current_scene_validation_collection = null


## Returns the current [GodotDoctorSceneValidationCollection], or [code]null[/code] if none exists.
func get_scene_validation_collection() -> GodotDoctorSceneValidationCollection:
	return _current_scene_validation_collection


## Returns the current [GodotDoctorResourceValidationCollection], or [code]null[/code]
## if none exists.
func get_resource_validation_collection() -> GodotDoctorResourceValidationCollection:
	return _current_resource_validation_collection
