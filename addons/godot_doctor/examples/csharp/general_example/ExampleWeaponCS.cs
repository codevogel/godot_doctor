using Godot;
using Godot.Collections;
using GodotDoctor.Core;
using GodotDoctor.Core.Primitives;

namespace GodotDoctor.Examples.GeneralExample;

/// <summary>
/// A simple example weapon resource demonstrating validation on a <see cref="Resource"/>.
/// Used by GodotDoctor to show how to add custom validation conditions to resources.
/// </summary>
[Tool]
[GlobalClass]
public partial class ExampleWeaponCS : Resource, IValidatable // Named "ExampleWeaponCS" to avoid conflict with the GDScript version of this resource.
{
	/// <summary>The amount of damage this weapon deals. Must be greater than zero.</summary>
	[Export]
	public int Damage { get; set; } = -10;

	/// <summary>The sprite texture displayed for this weapon.</summary>
	[Export]
	public Texture2D Sprite { get; set; }

	/// <summary>The effective reach for melee attacks.</summary>
	[Export]
	public float ReachMelee { get; set; } = 15f;

	/// <summary>The effective reach for ranged attacks. Must be greater than or equal to <see cref="ReachMelee"/>.</summary>
	[Export]
	public float ReachRanged { get; set; } = 5f;

	public Array GetValidationConditions()
	{
		ValidationCondition[] conditions =
		[
			ValidationCondition.Simple(Damage > 0, "Damage should be a positive value."),
			ValidationCondition.Simple(
				ReachMelee <= ReachRanged,
				"Melee reach should not be greater than ranged reach."
			),
		];
		return conditions.ToGodotArray();
	}
}
