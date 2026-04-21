using Godot;

namespace GodotDoctor.Examples.VerifyArrayMatchesCountByPredicateExample;

public partial class ExampleFactory : Node
{
	[Export]
	public ExampleProductBase.Type TypeToSpawn { get; set; }

	public static ExampleProductBase SpawnProduct(ExampleProductBase.Type type)
	{
		ExampleProductBase spawnedProduct = null;
		switch (type)
		{
			case ExampleProductBase.Type.A:
				spawnedProduct = new ExampleProductA();
				break;
			case ExampleProductBase.Type.B:
				spawnedProduct = new ExampleProductB();
				break;
			default:
				GD.PushError($"Unknown product type: {type}");
				break;
		}

		return spawnedProduct;
	}
}
