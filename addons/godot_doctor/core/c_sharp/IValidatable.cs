using Godot.Collections;

namespace GodotDoctor.Core;

public interface IValidatable
{
	/// <summary>
	/// Gets a Godot array of validation conditions to check for this object.
	/// Used by GodotDoctor to determine if this object is in a valid state, and to provide feedback to the user if it is not.
	/// You can create normal C# arrays containing <see cref="Primitives.ValidationCondition"/> objects and
	/// return them as a Godot array using the <c>ToGodotArray()</c> extension method.
	/// </summary>
	/// <remarks>
	/// <b>Important:</b> Implement this as a public method, not an explicit interface implementation.
	/// GDScript relies on reflection to discover this method at runtime. Explicit implementations
	/// (e.g. <c>Array IValidatable.GetValidationConditions()</c>) are not visible to Godot's
	/// method lookup and will be silently skipped.
	/// </remarks>
	/// <returns>A Godot array of validation conditions.</returns>
	public Array GetValidationConditions();
}
