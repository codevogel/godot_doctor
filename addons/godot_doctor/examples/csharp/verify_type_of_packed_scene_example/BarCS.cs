using Godot;

namespace GodotDoctor.Examples.VerifyTypeOfPackedSceneExample;

/// <summary>
/// A simple script with a class name for demonstrative purposes.
/// Used by GodotDoctor to verify behavior when a scene has a script of an unexpected type.
/// Named <c>BarCS</c> to avoid a global class name conflict with the GDScript version.
/// </summary>
[GlobalClass]
public partial class BarCS : Node { }
