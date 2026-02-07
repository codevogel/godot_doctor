## A simple example script demonstrating Godot Doctor's default validations.
##
## This script has NO custom validation code (_get_validation_conditions method),
## yet Godot Doctor will automatically validate the exported properties:
## - `some_string` must not be empty (default string validation)
## - `some_script_that_we_refer_to` must not be null (default object validation)
##
## To see the default validations in action:
## 1. Open the scene in the editor
## 2. Save the scene (Ctrl+S)
## 3. Check the Godot Doctor dock for validation errors
## 4. Assign values to the properties in the Inspector
## 5. Save again and watch the errors disappear
extends Node

## A string property that should not be empty.
## This will fail default validation if left empty or containing only whitespace.
@export var some_string: String = ""

## An object reference that should be assigned.
## This will fail default validation if left null.
@export var some_script_that_we_refer_to: SomeScriptThatWeReferTo


func _ready() -> void:
	_call_something_on_the_other_script()


## Calls a method on the referred script, demonstrating why both properties need to be assigned.
func _call_something_on_the_other_script():
	some_script_that_we_refer_to.some_func_that_we_call(some_string)
