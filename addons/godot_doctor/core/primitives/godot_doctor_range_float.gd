## A class representing a range of floating-point numbers with
## customizable inclusivity for the start and end points.
class_name GodotDoctorRangeFloat
extends RefCounted

## The default tolerance for floating-point comparisons.
const EPSILON_DEFAULT: float = 0.00001

## The start of the range.
var start: float = NAN
## The end of the range.
var end: float = NAN
## Whether the end of the range is included in the range.
## If [code]true[/code], the range includes the end value.
var inclusive: bool = false
## The tolerance for floating-point comparisons.
var epsilon: float = EPSILON_DEFAULT


## Initializes the [GodotDoctorRangeFloat] with the given parameters.
## [param start] is the start of the range. [param end] is the end of the range.
## [param inclusive_end] determines whether [param end] is included in the range.
## [param epsilon] is the tolerance for floating-point comparisons.
## By default, the range is exclusive.
## [br][br]
## Example:
## [codeblock]
## GodotDoctorRangeFloat.new(1.0, 10.0)        # contains [1 ... (10 - epsilon) +/- epsilon]
## GodotDoctorRangeFloat.new(1.0, 10.0, true)  # contains [1 ... 10 +/- epsilon]
## [/codeblock]
func _init(
	start: float = 0.0,
	end: float = 0.0,
	inclusive_end: bool = false,
	epsilon: float = EPSILON_DEFAULT
) -> void:
	if start > end:
		push_error("End of GodotDoctorRangeFloat must be greater than or equal to start.")
		GodotDoctorPlugin.instance.quit_with_fail_early_if_headless()
		return
	self.start = start
	self.end = end
	self.inclusive = inclusive_end
	self.epsilon = epsilon


## Returns [code]true[/code] if [param value] is within this range,
## [code]false[/code] otherwise.
func contains(value: float) -> bool:
	if inclusive:
		return value >= start and (value <= end or _is_equal_approx(value, end, epsilon))
	return value >= start and (value < end or _is_equal_approx(value, end, epsilon))


## Returns [code]true[/code] if [param other] is completely within this range,
## [code]false[/code] otherwise.
func contains_range(other: GodotDoctorRangeFloat) -> bool:
	if other.start < start and not _is_equal_approx(other.start, start, epsilon):
		return false
	if other.end > end and not _is_equal_approx(other.end, end, epsilon):
		return false
	if _is_equal_approx(other.end, end, epsilon) and not inclusive and other.inclusive:
		return false
	return true


## Returns [code]true[/code] if [param a] and [param b] differ by at most [param epsilon].
static func _is_equal_approx(a: float, b: float, epsilon: float = 0.0001) -> bool:
	return abs(a - b) <= epsilon
