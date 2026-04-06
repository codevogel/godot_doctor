using Godot;
using Godot.Collections;
using GodotDoctor.Core;
using GodotDoctor.Core.Primitives;

namespace GodotDoctor.Examples.VerifyNodePathExample;

/// <summary>
/// A script that demonstrates how to validate node paths using onready variables.
/// Used by GodotDoctor to show how to validate node paths.
/// </summary>
public partial class ScriptWithNodePath : Node, IValidatable
{
	public Array GetValidationConditions()
	{
		ValidationCondition[] conditions =
		[
			ValidationCondition.Simple(HasNode("MyNodePathNode"), "MyNodePathNode was not found."),
			// The below helper method does the same thing as above, but
			// standardizes the error message.
			ValidationCondition.HasNodePath(this, "MyNodePathNode/MyDeeperNodePathNode"),
		];
		return conditions.ToGodotArray();
	}
}
