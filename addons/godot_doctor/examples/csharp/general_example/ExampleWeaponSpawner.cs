using Godot;
using Godot.Collections;
using GodotDoctor.Core;
using GodotDoctor.Core.Primitives;

namespace GodotDoctor.Examples.GeneralExample;

/// <summary>
/// A simple example weapon spawner demonstrating nested resource validation.
/// Used by GodotDoctor to show how to delegate to a resource's own validation conditions.
/// </summary>
public partial class ExampleWeaponSpawner : Node, IValidatable
{
	/// <summary>The weapon resource to spawn. Its own validation conditions will also be checked.</summary>
	[Export]
	public ExampleWeaponCS WeaponResource { get; set; }

	public Array GetValidationConditions()
	{
		if (WeaponResource != null)
			return WeaponResource.GetValidationConditions();

		ValidationCondition[] conditions =
		[
			ValidationCondition.Simple(false, "Weapon resource must be assigned."),
		];
		return conditions.ToGodotArray();
	}
}
