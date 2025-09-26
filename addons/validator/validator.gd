@tool
extends EditorPlugin

const VALIDATION_GLOBAL_NAME := "Validation"
const VALIDATION_GLOBAL_PATH := "res://addons/validator/validation.gd"


func _enable_plugin() -> void:
	# Add autoloads here.
	add_autoload_singleton(VALIDATION_GLOBAL_NAME, VALIDATION_GLOBAL_PATH)


func _disable_plugin() -> void:
	# Remove autoloads here.
	remove_autoload_singleton(VALIDATION_GLOBAL_NAME)


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	pass


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	pass
