using Godot;
using Godot.Collections;
using GodotDoctor.Core;
using GodotDoctor.Core.Primitives;

namespace GodotDoctor.Examples.VerifyChildCountExample;

/// <summary>
/// A simple example script demonstrating how to require an exact child count.
/// Used by GodotDoctor to show the <see cref="ValidationCondition.HasChildCount"/> helper.
/// </summary>
public partial class ScriptWithChildCount : Node, IValidatable
{
	/// <summary>Returns a <see cref="ValidationCondition"/> that fails if this node does not have exactly 3 children.</summary>
	public Array GetValidationConditions()
	{
		ValidationCondition[] conditions =
		[
			// Manually pass the variableName here, or else the message will just say 'this' instead of the variable name.
			ValidationCondition.HasChildCount(this, 3, variableName: Name),
		];
		return conditions.ToGodotArray();
	}
}
