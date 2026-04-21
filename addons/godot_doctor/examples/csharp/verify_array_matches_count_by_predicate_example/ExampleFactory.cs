using Godot;

namespace GodotDoctor.Examples.VerifyArrayMatchesCountByPredicateExample;

public partial class ExampleFactory : Node
{
	[Export]
	public ExampleProductBase.Type TypeToSpawn { get; set; } = ExampleProductBase.Type.A;

	public ExampleProductBase SpawnProduct() => null;
}
