using Godot;
using Godot.Collections;
using GodotDoctor.Core;
using GodotDoctor.Core.Primitives;

namespace GodotDoctor.Examples.VerifyResourceExample;

/// <summary>
/// A simple Resource with exported variables and validation conditions.
/// Used by GodotDoctor to demonstrate resource validation.
/// Named <c>MyResourceCS</c> to avoid a global class name conflict with the GDScript version.
/// </summary>
[Tool]
[GlobalClass]
public partial class MyResourceCS : Resource, IValidatable
{
	/// <summary>A string that must not be empty.</summary>
	[Export]
	public string MyString { get; set; }

	/// <summary>An integer that must be between <see cref="MyMinInt"/> and <see cref="MyMaxInt"/>.</summary>
	[Export]
	public int MyInt { get; set; } = -1;

	/// <summary>The maximum allowed value for <see cref="MyInt"/>.</summary>
	[Export]
	public int MyMaxInt { get; set; } = 10;

	/// <summary>The minimum allowed value for <see cref="MyInt"/>.</summary>
	[Export]
	public int MyMinInt { get; set; } = 0;

	public Array GetValidationConditions()
	{
		ValidationCondition[] conditions =
		[
			// A helper method for the condition below is ValidationCondition.IsInRangeInt,
			// which does the exact same thing, but standardizes the error message.
			ValidationCondition.Simple(
				MyInt >= MyMinInt && MyInt <= MyMaxInt,
				$"my_int must be between {MyMinInt} and {MyMaxInt}, but is {MyInt}."
			),
			ValidationCondition.Simple(
				MyString != null && MyString != "",
				"my_string must not be empty."
			),
			ValidationCondition.Simple(
				MyMaxInt >= MyMinInt,
				"my_max_int must be greater than or equal to my_min_int."
			),
			ValidationCondition.Simple(
				MyMinInt <= MyMaxInt,
				"my_min_int must be less than or equal to my_max_int."
			),
		];
		return conditions.ToGodotArray();
	}
}
