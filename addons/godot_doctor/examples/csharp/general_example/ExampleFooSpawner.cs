using Godot;
using Godot.Collections;
using GodotDoctor.Core;
using GodotDoctor.Core.Primitives;

namespace GodotDoctor.Examples.GeneralExample;

/// <summary>
/// A simple example spawner demonstrating PackedScene type validation.
/// Used by GodotDoctor to show how to validate that an exported <see cref="PackedScene"/>
/// matches a required type.
/// </summary>
public partial class ExampleFooSpawner : Node, IValidatable
{
	/// <summary>The scene to spawn. Must have a root node of type Foo.</summary>
	[Export]
	public PackedScene PackedSceneOfFooType { get; set; }

	public Array GetValidationConditions()
	{
		ValidationCondition[] conditions =
		[
			ValidationCondition.IsSceneOfType<FooCS>(PackedSceneOfFooType),
		];
		return conditions.ToGodotArray();
	}
}
