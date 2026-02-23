extends SceneTree

@warning_ignore("unsafe_method_access")
@warning_ignore("inferred_declaration")
func _init() -> void:

	var max_iter := 20
	var iter := 0

	# Not seen this wait more than 1.
	while(Engine.get_main_loop() == null and iter < max_iter):
		await create_timer(.01).timeout
		iter += 1

	if(Engine.get_main_loop() == null):
		push_error('Main loop did not start in time.')
		quit(0)
		return

	var cli : Node = load("res://addons/godot_doctor/cli/gd_cli.gd").new()
	get_root().add_child(cli)
