using Godot;
using Godot.Collections;
using GodotDoctor.Core;
using GodotDoctor.Core.Primitives;

namespace GodotDoctor.Examples.VerifyToolScriptExample;

/// <summary>
/// A simple tool script with exported variables for demonstrative purposes.
/// Used by GodotDoctor to show how to validate exported variables in a tool script.
/// </summary>
[Tool]
public partial class ToolScript : Node, IValidatable
{
	/// <summary>An integer that must be less than <see cref="MyMaxInt"/>.</summary>
	[Export]
	public int MyInt { get; set; } = 0;

	/// <summary>The maximum allowed value for <see cref="MyInt"/>.</summary>
	[Export]
	public int MyMaxInt { get; set; } = 100;

	public Array GetValidationConditions()
	{
		ValidationCondition[] conditions =
		[
			ValidationCondition.Simple(
				MyInt <= MyMaxInt,
				$"my_int must be less than {MyMaxInt} but is {MyInt}"
			),
		];
		return conditions.ToGodotArray();
	}
}
