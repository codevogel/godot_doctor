using Godot;
using Godot.Collections;
using GodotDoctor.Core;
using GodotDoctor.Core.Primitives;

namespace GodotDoctor.Examples.VerifyChildCountExample;

/// <summary>
/// A simple example script demonstrating how to require that a node has no children.
/// Used by GodotDoctor to show the <see cref="ValidationCondition.HasNoChildren"/> helper.
/// </summary>
public partial class ScriptWithNoChildrenAllowed : Node, IValidatable
{
	/// <summary>Returns a <see cref="ValidationCondition"/> that fails if this node has any children.</summary>
	public Array GetValidationConditions()
	{
		ValidationCondition[] conditions =
		[
			// Manually pass the variableName here, or else the message will just say 'this' instead of the variable name.
			ValidationCondition.HasNoChildren(this, variableName: Name),
		];
		return conditions.ToGodotArray();
	}
}
