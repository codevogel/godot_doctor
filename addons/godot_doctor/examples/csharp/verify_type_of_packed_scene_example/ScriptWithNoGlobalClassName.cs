using Godot;

namespace GodotDoctor.Examples.VerifyTypeOfPackedSceneExample;

/// <summary>
/// A C# script without a global class name, for demonstrative purposes.
/// Used by GodotDoctor to verify behavior when a scene's script has no globally registered type.
/// Without the <c>[GlobalClass]</c> attribute, this class is not accessible by name from GDScript
/// and has no <c>[ScriptPath]</c> attribute, which is analogous to a GDScript without a
/// <c>class_name</c> declaration.
/// </summary>
public partial class ScriptWithNoGlobalClassName : Node { }
