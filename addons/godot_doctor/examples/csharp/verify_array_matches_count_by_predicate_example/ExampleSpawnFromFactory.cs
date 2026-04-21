using Godot;
using Godot.Collections;
using GodotDoctor.Core;
using GodotDoctor.Core.Primitives;

namespace GodotDoctor.Examples.VerifyArrayMatchesCountByPredicateExample;

public partial class ExampleSpawnFromFactory : Node, IValidatable
{
	[Export]
	public Array<ExampleFactory> Factories { get; set; } = [];

	[Export]
	public int NumProductsForTypeA { get; set; } = 2;

	[Export]
	public int NumProductsForTypeB { get; set; } = 1;

	public Array GetValidationConditions()
	{
		ValidationCondition[] conditions =
		[
			ValidationCondition.ArrayMatchesCountByPredicate(
				Factories,
				NumProductsForTypeA,
				factory => factory != null && factory.TypeToSpawn == ExampleProductBase.Type.A,
				predicateDescription: "TypeToSpawn is Type A",
				variableName: nameof(Factories)
			),
			ValidationCondition.ArrayMatchesCountByPredicate(
				Factories,
				NumProductsForTypeB,
				factory => factory != null && factory.TypeToSpawn == ExampleProductBase.Type.B,
				predicateDescription: "TypeToSpawn is Type B",
				variableName: nameof(Factories)
			),
		];

		return conditions.ToGodotArray();
	}
}
