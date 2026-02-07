## A simple helper script that demonstrates how exported references are used.
## This script is referenced by the `script_with_default_validations.gd` script.
class_name SomeScriptThatWeReferTo
extends Node


## A method that demonstrates why the referring script must have valid exports.
## If `some_script_that_we_refer_to` is null, this method can never be called.
## If `some_string` is empty, this print will show an empty message.
func some_func_that_we_call(some_string_we_pass: String) -> void:
	print("We call this func with: ", some_string_we_pass)
