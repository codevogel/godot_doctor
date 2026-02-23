## Main entry point for the Godot Doctor CLI interface. 
## Makes sure the validation process can start and kicks it off.
extends SceneTree


# ============================================================================
# CONSTANTS
# ============================================================================


## An arbitrary amount of iterations we are willing to wait for Engine to start the main loop.
const max_wait_iterations : int = 20


# ============================================================================
# CORE IMPLEMENTATION
# ============================================================================


## Intializes the validation process. Needs to make sure the main loop is running in order
## for the [Validator] to safely process Nodes in the Scene 	Tree.
func _init() -> void:

	# Current wait iteratrion count.
	var iter : int = 0

	# Wait for the main loop to start. We are delaying it a bit to make sure that the Engine 
	# has the time to initialise. Not seen this wait more than 1 iteration.
	while Engine.get_main_loop() == null and iter < max_wait_iterations :
		await create_timer(.01).timeout
		iter += 1

	# If after all the wait, the main loop has not started, return and error.
	if Engine.get_main_loop() == null :
		push_error('Main loop did not start in time.')
		quit(1)
		return

	# Create the Godot Doctor CLI interface and let it run.
	var cli : Node = load("res://addons/godot_doctor/cli/gd_cli.gd").new()
	get_root().add_child(cli)
