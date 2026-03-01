## Main entry point for the Godot Doctor CLI interface.
## Makes sure the validation process can start and kicks it off.
extends SceneTree

# ============================================================================
# CONSTANTS
# ============================================================================

## An arbitrary amount of iterations we are willing to wait for Engine to start the main loop.
const MAX_WAIT_ITERATIONS: int = 20
const GODOT_DOCTOR_CLI_PATH: String = "res://addons/godot_doctor/cli/godot_doctor_cli.gd"

# ============================================================================
# CORE IMPLEMENTATION
# ============================================================================


## Intializes the validation process. Needs to make sure the main loop is running in order
## for the [Validator] to safely process Nodes in the SceneTree.
func _init() -> void:
	# Current wait iteratrion count.
	var iter: int = 0

	# Wait for the main loop to start. We are delaying it a bit to make sure that the Engine
	# has the time to initialise. Not seen this wait more than 1 iteration.
	while Engine.get_main_loop() == null and iter < MAX_WAIT_ITERATIONS:
		await create_timer(.01).timeout
		iter += 1

	# If after all the wait, the main loop has not started, return and error.
	if Engine.get_main_loop() == null:
		push_error("Main loop did not start in time.")
		var exit_code: int = 1  # A non-zero exit code indicates an error.
		quit(exit_code)
		return

	# Create the Godot Doctor CLI interface and let it run.
	var cli_node: Node = load(GODOT_DOCTOR_CLI_PATH).new()
	assert(is_instance_valid(cli_node))
	assert(cli_node is GodotDoctorCLI)
	var godot_doctor_cli: GodotDoctorCLI = cli_node as GodotDoctorCLI
	get_root().add_child(godot_doctor_cli)
