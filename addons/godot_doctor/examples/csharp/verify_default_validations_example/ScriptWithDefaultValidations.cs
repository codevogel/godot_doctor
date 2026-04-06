using Godot;

namespace GodotDoctor.Examples.VerifyDefaultValidationsExample;

/// <summary>
/// A simple example script demonstrating Godot Doctor's default validations.
///
/// This script has NO custom validation code (<c>GetValidationConditions</c> method),
/// yet Godot Doctor will automatically validate the exported properties:
/// <list type="bullet">
/// <item><description><see cref="SomeString"/> must not be empty (default string validation)</description></item>
/// <item><description><see cref="SomeScriptThatWeReferTo"/> must not be null (default object validation)</description></item>
/// </list>
/// </summary>
public partial class ScriptWithDefaultValidations : Node
{
	/// <summary>A string property that should not be empty.</summary>
	[Export]
	public string SomeString { get; set; } = "";

	/// <summary>An object reference that should be assigned.</summary>
	[Export]
	public SomeScriptThatWeReferTo SomeScriptThatWeReferTo { get; set; }

	public override void _Ready()
	{
		CallSomethingOnTheOtherScript();
	}

	private void CallSomethingOnTheOtherScript()
	{
		SomeScriptThatWeReferTo.SomeFuncThatWeCall(SomeString);
	}
}
