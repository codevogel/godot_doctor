using Godot;
using Godot.Collections;
using GodotDoctor.Core;
using GodotDoctor.Core.Primitives;

namespace GodotDoctor.Examples.GeneralExample;

/// <summary>
/// A simple example enemy node demonstrating cross-property validation.
/// Used by GodotDoctor to show how to validate relationships between exported properties.
/// </summary>
public partial class ExampleMyEnemy : Node, IValidatable
{
	/// <summary>The health value the enemy starts with.</summary>
	[Export]
	public int InitialHealth { get; set; } = 120;

	/// <summary>The maximum health value the enemy can have.</summary>
	[Export]
	public int MaxHealth { get; set; } = 100;

	public Array GetValidationConditions()
	{
		ValidationCondition[] conditions =
		[
			ValidationCondition.Simple(
				InitialHealth <= MaxHealth,
				"Initial health should not be greater than max health."
			),
		];
		return conditions.ToGodotArray();
	}
}
