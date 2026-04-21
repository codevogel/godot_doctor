using Godot;

namespace GodotDoctor.Examples.VerifyArrayMatchesCountByPredicateExample;

public partial class ExampleProductBase : RefCounted
{
	public enum Type
	{
		None = 0,
		A = 1,
		B = 2,
	}

	public Type ProductType { get; protected set; } = Type.None;
}
