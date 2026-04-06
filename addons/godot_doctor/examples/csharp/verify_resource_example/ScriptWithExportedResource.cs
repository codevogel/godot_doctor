using Godot;
using Godot.Collections;
using GodotDoctor.Core;
using GodotDoctor.Core.Primitives;

namespace GodotDoctor.Examples.VerifyResourceExample;

/// <summary>
/// A script that demonstrates how to validate an exported resource variable.
/// Used by GodotDoctor to show how to validate exported resources.
/// </summary>
public partial class ScriptWithExportedResource : Node, IValidatable
{
	/// <summary>A resource type with its own validation conditions.</summary>
	[Export]
	public MyResourceCS MyResource { get; set; }

	public Array GetValidationConditions()
	{
		// We rely on the default validation conditions here to see
		// if the resource is valid.
		// But, notice how we return an empty array in case the instance
		// is null, or we might call GetValidationConditions on a null instance.
		if (IsInstanceValid(MyResource))
		{
			return MyResource.GetValidationConditions();
		}
		return System.Array.Empty<ValidationCondition>().ToGodotArray();
	}
}
