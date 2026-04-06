using Godot;
using Godot.Collections;
using GodotDoctor.Core;
using GodotDoctor.Core.Primitives;

namespace GodotDoctor.Examples.VerifyExportsExample;

/// <summary>
/// A script that demonstrates how to validate exported variables.
/// Used by GodotDoctor to show how to validate exported variables.
/// </summary>
public partial class ScriptWithExportsExample : Node, IValidatable
{
	/// <summary>A string that must not be empty.</summary>
	[Export]
	public string MyString { get; set; } = "";

	/// <summary>An integer that must be greater than zero.</summary>
	[Export]
	public int MyInt { get; set; } = -42;

	/// <summary>A Node that must be valid and named "ExpectedNodeName".</summary>
	[Export]
	public Node MyNode { get; set; }

	public Array GetValidationConditions()
	{
		ValidationCondition[] conditions =
		[
			// The string not empty check is handled by the default validation conditions
			// and thus does not need a validation condition here.
			ValidationCondition.Simple(MyInt > 0, "my_int must be greater than zero"),
			new ValidationCondition(
				() => IsInstanceValid(MyNode) && MyNode.Name == "ExpectedNodeName",
				"my_node must be valid and named 'ExpectedNodeName'",
				ValidationCondition.Severity.Error
			),
		];
		return conditions.ToGodotArray();
	}
}
