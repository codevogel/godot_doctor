## A class representing a range of floating-point numbers with
## customizable inclusivity for the start and end points.
class_name RangeFloat
extends RefCounted

const EPSILON_DEFAULT: float = 0.00001

## The start of the range.
var start: float = NAN
## The end of the range.
var end: float = NAN
## Whether the end of the range is included in the range.
## If true, the range includes the end value.
var inclusive: bool = false
## The tolerance for floating-point comparisons.
var epsilon: float = EPSILON_DEFAULT


## Initializes the RangeFloat with the given parameters.
## `start` is the start of the range. `end` is the end of the range.
## `inclusive` determines if the range contains `end`.
## `epsilon` is the tolerance for floating-point comparisons.
## By default, the range is exclusive.
## e.g.
## RangeFloat(1.0, 10.0) will contain [1 ... (10 - epsilon) +/- epsilon].
## RangeFloat(1.0, 10.0, true) will contain [1 ... 10 +/- epsilon].
func _init(
	start: float = 0.0,
	end: float = 0.0,
	inclusive_end: bool = false,
	epsilon: float = EPSILON_DEFAULT
) -> void:
	if start > end:
		push_error("End of RangeFloat must be greater than or equal to start.")
		return
	self.start = start
	self.end = end
	self.inclusive = inclusive_end
	self.epsilon = epsilon


## Returns true if the value is within the range, false otherwise.
func contains(value: float) -> bool:
	if inclusive:
		return value >= start and (value <= end or GodotDoctor.is_equal_approx(value, end, epsilon))
	return value >= start and (value < end or GodotDoctor.is_equal_approx(value, end, epsilon))


## Returns true if the other RangeFloat is completely within this range, false otherwise.
func contains_range(other: RangeFloat) -> bool:
	if other.start < start and not GodotDoctor.is_equal_approx(other.start, start, epsilon):
		return false
	if other.end > end and not GodotDoctor.is_equal_approx(other.end, end, epsilon):
		return false
	if GodotDoctor.is_equal_approx(other.end, end, epsilon) and not inclusive and other.inclusive:
		return false
	return true
