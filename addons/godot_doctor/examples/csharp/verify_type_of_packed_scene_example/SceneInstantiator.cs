using Godot;
using Godot.Collections;
using GodotDoctor.Core;
using GodotDoctor.Core.Primitives;
using GodotDoctor.Examples;

namespace GodotDoctor.Examples.VerifyTypeOfPackedSceneExample;

/// <summary>
/// A node that instantiates a PackedScene and verifies its type.
/// Used by GodotDoctor to demonstrate type verification of PackedScenes.
/// </summary>
public partial class SceneInstantiator : Node, IValidatable
{
	/// <summary>This is a PackedScene that should have a root node of type <see cref="FooCS"/>.</summary>
	[Export]
	public PackedScene SceneOfFooType { get; set; }

	public Array GetValidationConditions()
	{
		ValidationCondition[] conditions = [ValidationCondition.IsSceneOfType<FooCS>(SceneOfFooType)];
		return conditions.ToGodotArray();
	}
}
