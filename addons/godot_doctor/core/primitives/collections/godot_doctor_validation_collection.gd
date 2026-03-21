## A base class for collections of validation messages.
@abstract class_name GodotDoctorValidationCollection


## Add [param variant_key] mapped to [param variant_value] in [param map].
## Fails if [param variant_key] already has a value in [param map].
func _add_and_fail_if_already_has(
	variant_key: Variant, variant_value: Variant, map: Dictionary
) -> void:
	if map.has(variant_key):
		assert(
			false,
			"Variant %s already has a value in this collection." % variant_key,
		)
		GodotDoctorPlugin.instance.quit_with_fail_early_if_headless()
		return
	map[variant_key] = variant_value
