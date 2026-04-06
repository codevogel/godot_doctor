using Godot;
using Godot.Collections;
using GodotDoctor.Core;
using GodotDoctor.Core.Primitives;

namespace GodotDoctor.Examples.GeneralExample;

/// <summary>
/// A simple example player node demonstrating custom validation conditions.
/// Used by GodotDoctor to show how to validate exported properties with custom rules.
/// </summary>
public partial class ExamplePlayer : Node, IValidatable
{
	/// <summary>The display name of the player. Names longer than 12 characters may cause UI issues.</summary>
	[Export]
	public string PlayerName { get; set; } = "Godot Doctor Enjoyer";

	public Array GetValidationConditions()
	{
		ValidationCondition[] conditions =
		[
			ValidationCondition.Simple(
				PlayerName.Length <= 12,
				"Player name longer than 12 characters may cause UI issues.",
				ValidationCondition.Severity.Info
			),
		];
		return conditions.ToGodotArray();
	}
}
