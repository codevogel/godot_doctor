using Godot;

namespace GodotDoctor.Examples;

/// <summary>
/// A simple example node with no validation conditions.
/// Used by GodotDoctor to show how nodes without validation conditions are displayed.
/// </summary>
[GlobalClass]
public partial class FooCS : Node
{
	// Called when the node enters the scene tree for the first time.
	public override void _Ready() { }

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta) { }
}
