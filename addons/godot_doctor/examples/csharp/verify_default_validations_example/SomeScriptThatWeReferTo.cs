using Godot;

namespace GodotDoctor.Examples.VerifyDefaultValidationsExample;

/// <summary>
/// A simple helper script that demonstrates how exported references are used.
/// This script is referenced by <see cref="ScriptWithDefaultValidations"/>.
/// </summary>
public partial class SomeScriptThatWeReferTo : Node
{
	/// <summary>
	/// Demonstrates why the referring script must have valid exports.
	/// If the holding node's reference is null, this method can never be called.
	/// Prints <paramref name="someStringWePass"/>; if it is empty the output will be blank.
	/// </summary>
	public static void SomeFuncThatWeCall(string someStringWePass)
	{
		GD.Print("We call this func with: ", someStringWePass);
	}
}
