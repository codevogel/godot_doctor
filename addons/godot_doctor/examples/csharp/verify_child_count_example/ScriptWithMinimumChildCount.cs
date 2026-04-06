using Godot;
using Godot.Collections;
using GodotDoctor.Core;
using GodotDoctor.Core.Primitives;

namespace GodotDoctor.Examples.VerifyChildCountExample;

/// <summary>
/// A simple example script demonstrating how to require a minimum number of children.
/// Used by GodotDoctor to show the <see cref="ValidationCondition.HasMinimumChildCount"/> helper.
/// </summary>
public partial class ScriptWithMinimumChildCount : Node, IValidatable
{
	/// <summary>Returns a <see cref="ValidationCondition"/> that fails if this node has fewer than 3 children.</summary>
	public Array GetValidationConditions()
	{
		ValidationCondition[] conditions =
		[
			// Manually pass the variableName here, or else the message will just say 'this' instead of the variable name.
			ValidationCondition.HasMinimumChildCount(this, 3, variableName: Name),
		];
		return conditions.ToGodotArray();
	}
}
