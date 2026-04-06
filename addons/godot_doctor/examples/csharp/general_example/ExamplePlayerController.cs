using Godot;

namespace GodotDoctor.Examples.GeneralExample;

/// <summary>
/// A simple example player controller demonstrating default export validation.
/// Used by GodotDoctor to show how default validations catch unassigned exported nodes.
/// </summary>
public partial class ExamplePlayerController : Node
{
	/// <summary>The player node this controller acts upon. Must be assigned before play.</summary>
	[Export]
	public Node Player { get; set; }
}
