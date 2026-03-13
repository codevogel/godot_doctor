## A simple helper script that demonstrates how exported references are used.
## This script is referenced by the `script_with_default_validations.gd` script.
class_name SomeScriptThatWeReferTo
extends Node


## Demonstrates why the referring script must have valid exports.
## If the holding node's reference is null, this method can never be called.
## Prints [param some_string_we_pass]; if it is empty the output will be blank.
func some_func_that_we_call(some_string_we_pass: String) -> void:
	print("We call this func with: ", some_string_we_pass)
