using Godot;

namespace GodotDoctor.Examples.VerifyDefaultValidationsExample;

/// <summary>
/// A simple example script demonstrating how to suppress default validations for a script.
/// Add this script to <c>GodotDoctorSettings.default_validation_ignore_list</c>
/// to prevent GodotDoctor from flagging its exported properties.
/// </summary>
public partial class ScriptIgnoredByDefaultValidations : Node
{
	/// <summary>An exported string that would normally trigger a default empty-string warning.</summary>
	[Export]
	public string SomeExportedString { get; set; } = "";

	/// <summary>An exported node that would normally trigger a default null-instance warning.</summary>
	[Export]
	public Node SomeExportedNode { get; set; } = null;
}
