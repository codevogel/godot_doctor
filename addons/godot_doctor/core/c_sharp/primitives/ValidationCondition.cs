using System;
using System.Reflection;
using System.Runtime.CompilerServices;
using Godot;

namespace GodotDoctor.Core.Primitives;

/// <summary>
/// Represents a validation condition.
/// It contains a callable that performs the validation,
/// and an error message that is used if the validation fails.
/// The callable should return either a bool,
/// or an array of nested <see cref="ValidationCondition"/> instances.
/// Used by <see cref="GodotDoctorValidator"/> to define validation rules.
/// </summary>
public partial class ValidationCondition : GodotObject
{
	/// <summary>
	/// The severity level of a validation condition. Used to indicate how critical a validation failure is.
	/// </summary>
	public enum Severity
	{
		/// <summary>
		/// Informational message, does not indicate a problem but may be useful for users to know.
		/// </summary>
		Info = 0,

		/// <summary>
		/// Warning message, indicates a potential issue that may or may not break functionality, but could lead to problems.
		/// </summary>
		Warning = 1,

		/// <summary>
		/// Indicates a critical issue that breaks functionality, or is very likely to cause problems if not addressed.
		/// </summary>
		Error = 2,
	}

	public enum InheritanceSearchStrategy
	{
		/// <summary>
		/// Only consider the root node of the PackedScene referenced,
		/// regardless of whether it has a script or not.
		/// i.e. the root node of the directly referenced scene,
		/// even if it has a screne as a parent scene.
		/// </summary>
		DIRECT = 0,

		///<summary>
		/// Only consider the very topmost root node of the PackedScene's inheritance chain,
		/// regardless of whether it has a script or not.
		/// i.e. the root node of the base scene that has no further parents.
		/// </summary>
		TOPMOST_ROOT = 1,

		/// <summary>
		/// Only consider the first root node in the PackedScene's inheritance chain,
		/// that has a script attached.
		/// i.e. the root node of the first parent scene that has a script, starting
		/// from the directly referenced scene and moving up the inheritance chain.
		/// </summary>
		FIRST_SCRIPT_ROOT = 2,

		/// <summary>
		/// Only consider the last root node in the PackedScene's inheritance chain,
		/// that has a script attached.
		/// i.e. the root node of the last parent scene that has a script.
		/// </summary>
		LAST_SCRIPT_ROOT = 3,
	}

	/// <summary>
	/// The path to the GDScript file that defines the ValidationCondition class and its static factory methods.
	/// </summary>
	private const string GD_SCRIPT_PATH =
		"res://addons/godot_doctor/core/primitives/validation_condition.gd";

	/// <summary>
	/// Lazy-loaded GDScript resource that defines the ValidationCondition class and its static factory methods.
	/// </summary>
	private static readonly Lazy<Script> _gdScript = new(() => GD.Load<Script>(GD_SCRIPT_PATH));

	/// <summary>
	/// The underlying GodotObject that represents the GDScript ValidationCondition instance.
	/// This is what gets passed to GDScript when we call static factory methods, and
	/// is used internally to bridge between C# and GDScript representations of validation conditions.
	/// </summary>
	internal readonly GodotObject Inner;

	/// <summary>
	/// Private constructor that wraps a GodotObject. Used internally to create ValidationCondition instances
	/// from GDScript static factory methods, which return GodotObjects that we wrap in this class.
	/// </summary>
	private ValidationCondition(GodotObject inner) => Inner = inner;

	/// <summary>
	/// Parameterless constructor required by Godot's C# scripting runtime.
	/// Should not be used directly.
	/// </summary>
	[Obsolete(
		"This constructor is only for Godot's C# scripting runtime and should not be used directly."
	)]
	public ValidationCondition() { }

	/// <summary>
	/// Initializes a <see cref="ValidationCondition"/> with a callable, error message, and severity.
	/// The callable should return either a <see cref="bool"/>,
	/// or an array of nested <see cref="ValidationCondition"/> instances.
	/// The validation fails if the callable evaluates to <see langword="false"/>.
	/// If the validation fails, the error message is reported at the given severity level.
	/// </summary>
	/// <param name="callable">
	/// The function evaluated when this condition is tested.
	/// </param>
	/// <param name="errorMessage">
	/// The error message reported when this condition fails.
	/// </param>
	/// <param name="severity">
	/// The severity level reported when this condition fails.
	/// Defaults to <see cref="Severity.Warning"/>.
	/// </param>
	public ValidationCondition(
		Func<Variant> callable,
		string errorMessage,
		Severity severity = Severity.Warning
	)
	{
		Inner = (GodotObject)
			_gdScript.Value.Call("new", Callable.From(callable), errorMessage, (int)severity);
	}

	/// <summary>
	/// Internal helper method to call a static factory method on the GDScript ValidationCondition class,
	/// passing the provided arguments, and wrapping the resulting GodotObject in a C# ValidationCondition instance.
	/// </summary>
	private static ValidationCondition FromGdStatic(string method, params Variant[] args) =>
		new((GodotObject)_gdScript.Value.Call(method, args));

	/// <summary>
	/// Creates a <see cref="ValidationCondition"/> that simply returns the provided result.
	/// If the result is <see langword="false"/>, the error message is reported
	/// at the specified severity level.
	/// This is a convenience method for creating basic validation conditions,
	/// useful for avoiding manual callable definitions.
	/// </summary>
	/// <param name="result">The result of the validation.</param>
	/// <param name="errorMessage">The error message reported if validation fails.</param>
	/// <param name="severity">
	/// The severity level reported when validation fails.
	/// Defaults to <see cref="Severity.Warning"/>.
	/// </param>
	public static ValidationCondition Simple(
		bool result,
		string errorMessage,
		Severity severity = Severity.Warning
	) => FromGdStatic("simple", result, errorMessage, (int)severity);

	/// <summary>
	/// Creates a <see cref="ValidationCondition"/> that checks whether an instance is valid.
	/// The variable name is used in the error message, defaulting to "Instance".
	/// This is a convenience method for checking instance validity with a default error message.
	/// </summary>
	/// <param name="instance">The instance to validate.</param>
	/// <param name="variableName">The name of the variable that is being validated. Automatically inferred from the variable name in C#, but can be overridden.</param>
	/// <param name="severity">
	/// The severity level reported when validation fails.
	/// Defaults to <see cref="Severity.Error"/>.
	/// </param>
	public static ValidationCondition IsInstanceValid(
		GodotObject instance,
		Severity severity = Severity.Error,
		[CallerArgumentExpression(nameof(instance))] string variableName = "Instance"
	) => FromGdStatic("is_instance_valid", instance, variableName, (int)severity);

	/// <summary>
	/// Creates a <see cref="ValidationCondition"/> that checks whether a string,
	/// after trimming leading and trailing whitespace, is not empty.
	/// The variable name is used in the error message, defaulting to "String".
	/// This is a convenience method for checking trimmed string emptiness.
	/// </summary>
	/// <param name="value">The string to validate.</param>
	/// <param name="severity">
	/// The severity level reported when validation fails.
	/// Defaults to <see cref="Severity.Warning"/>.
	/// </param>
	/// <param name="variableName">The name of the variable that is being validated. Automatically inferred from the variable name in C#, but can be overridden.</param>
	public static ValidationCondition IsStringNotEmpty(
		string value,
		Severity severity = Severity.Warning,
		[CallerArgumentExpression(nameof(value))] string variableName = "String"
	) => FromGdStatic("is_string_not_empty", value, variableName, (int)severity);

	/// <summary>
	/// Creates a <see cref="ValidationCondition"/> that checks whether a string,
	/// after trimming leading and trailing whitespace, is not empty.
	/// The variable name is used in the error message, defaulting to "String".
	/// This is a convenience method for checking trimmed string emptiness.
	/// </summary>
	/// <param name="value">The string to validate.</param>
	/// <param name="severity">
	/// The severity level reported when validation fails.
	/// Defaults to <see cref="Severity.Warning"/>.
	/// </param>
	/// <param name="variableName">The name of the variable that is being validated. Automatically inferred from the variable name in C#, but can be overridden.</param>
	public static ValidationCondition IsStrippedStringNotEmpty(
		string value,
		Severity severity = Severity.Warning,
		[CallerArgumentExpression(nameof(value))] string variableName = "String"
	) => FromGdStatic("is_stripped_string_not_empty", value, variableName, (int)severity);

	/// <summary>
	/// Creates a <see cref="ValidationCondition"/> that checks whether a value falls within an integer range.
	/// The variable name is used in the error message, defaulting to "Value".
	/// </summary>
	/// <param name="value">The value to validate.</param>
	/// <param name="range">The range to check against.</param>
	/// <param name="severity">
	/// The severity level reported when validation fails.
	/// Defaults to <see cref="Severity.Error"/>.
	/// </param>
	/// <param name="variableName">The name of the variable that is being validated. Automatically inferred from the variable name in C#, but can be overridden.</param>
	public static ValidationCondition IsInRangeInt(
		int value,
		RangeInt range,
		Severity severity = Severity.Error,
		[CallerArgumentExpression(nameof(value))] string variableName = "Value"
	) => FromGdStatic("is_in_range_int", value, (GodotObject)range, variableName, (int)severity);

	/// <summary>
	/// Creates a <see cref="ValidationCondition"/> that checks whether a value falls within a floating-point range.
	/// The variable name is used in the error message, defaulting to "Value".
	/// </summary>
	/// <param name="value">The value to validate.</param>
	/// <param name="range">The range to check against.</param>
	/// <param name="severity">
	/// The severity level reported when validation fails.
	/// Defaults to <see cref="Severity.Error"/>.
	/// </param>
	/// <param name="variableName">The name of the variable that is being validated. Automatically inferred from the variable name in C#, but can be overridden.</param>
	public static ValidationCondition IsInRangeFloat(
		float value,
		RangeFloat range,
		Severity severity = Severity.Error,
		[CallerArgumentExpression(nameof(value))] string variableName = "Value"
	) => FromGdStatic("is_in_range_float", value, (GodotObject)range, variableName, (int)severity);

	/// <summary>
	/// Creates a <see cref="ValidationCondition"/> that checks whether a node
	/// has exactly the specified number of children.
	/// The variable name is used in the error message, defaulting to "Node".
	/// This is a convenience method for checking child count.
	/// </summary>
	/// <param name="node">The node to validate.</param>
	/// <param name="expectedCount">The expected number of children.</param>
	/// <param name="severity">
	/// The severity level reported when validation fails.
	/// Defaults to <see cref="Severity.Warning"/>.
	/// </param>
	/// <param name="variableName">The name of the variable that is being validated. Automatically inferred from the variable name in C#, but can be overridden.</param>
	public static ValidationCondition HasChildCount(
		Node node,
		int expectedCount,
		Severity severity = Severity.Warning,
		[CallerArgumentExpression(nameof(node))] string variableName = "Node"
	) => FromGdStatic("has_child_count", node, expectedCount, variableName, (int)severity);

	/// <summary>
	/// Creates a <see cref="ValidationCondition"/> that checks whether a node
	/// has at least the specified number of children.
	/// The variable name is used in the error message, defaulting to "Node".
	/// This is a convenience method for checking minimum child count.
	/// </summary>
	/// <param name="node">The node to validate.</param>
	/// <param name="minimumCount">The minimum number of children required.</param>
	/// <param name="variableName">The display name used in the error message.</param>
	/// <param name="severity">
	/// The severity level reported when validation fails.
	/// Defaults to <see cref="Severity.Error"/>.
	/// </param>
	public static ValidationCondition HasMinimumChildCount(
		Node node,
		int minimumCount,
		Severity severity = Severity.Error,
		[CallerArgumentExpression(nameof(node))] string variableName = "Node"
	) => FromGdStatic("has_minimum_child_count", node, minimumCount, variableName, (int)severity);

	/// <summary>
	/// Creates a <see cref="ValidationCondition"/> that checks whether a node
	/// has at most the specified number of children.
	/// The variable name is used in the error message, defaulting to "Node".
	/// This is a convenience method for checking maximum child count.
	/// </summary>
	/// <param name="node">The node to validate.</param>
	/// <param name="maximumCount">The maximum number of children allowed.</param>
	/// <param name="severity">
	/// The severity level reported when validation fails.
	/// Defaults to <see cref="Severity.Error"/>.
	/// </param>
	/// <param name="variableName">The name of the variable that is being validated. Automatically inferred from the variable name in C#, but can be overridden.</param>
	public static ValidationCondition HasMaximumChildCount(
		Node node,
		int maximumCount,
		Severity severity = Severity.Error,
		[CallerArgumentExpression(nameof(node))] string variableName = "Node"
	) => FromGdStatic("has_maximum_child_count", node, maximumCount, variableName, (int)severity);

	/// <summary>
	/// Creates a <see cref="ValidationCondition"/> that checks whether a node has no children.
	/// The variable name is used in the error message, defaulting to "Node".
	/// This is equivalent to <see cref="HasChildCount"/> with an expected count of 0.
	/// </summary>
	/// <param name="node">The node to validate.</param>
	/// <param name="severity">
	/// The severity level reported when validation fails.
	/// Defaults to <see cref="Severity.Warning"/>.
	/// </param>
	/// <param name="variableName">The name of the variable that is being validated. Automatically inferred from the variable name in C#, but can be overridden.</param>
	public static ValidationCondition HasNoChildren(
		Node node,
		Severity severity = Severity.Warning,
		[CallerArgumentExpression(nameof(node))] string variableName = "Node"
	) => FromGdStatic("has_no_children", node, variableName, (int)severity);

	/// <summary>
	/// Creates a <see cref="ValidationCondition"/> that checks whether a node
	/// has a child at the specified path.
	/// The variable name is used in the error message, defaulting to "Node".
	/// This is a convenience method for checking node path existence.
	/// </summary>
	/// <param name="node">The node to validate.</param>
	/// <param name="path">The path to check.</param>
	/// <param name="severity">
	/// The severity level reported when validation fails.
	/// Defaults to <see cref="Severity.Error"/>.
	/// </param>
	/// <param name="variableName">The name of the variable that is being validated. Automatically inferred from the variable name in C#, but can be overridden.</param>
	public static ValidationCondition HasNodePath(
		Node node,
		NodePath path,
		Severity severity = Severity.Error,
		[CallerArgumentExpression(nameof(node))] string variableName = "Node"
	) => FromGdStatic("has_node_path", node, path, variableName, (int)severity);

	/// <summary>
	/// Creates a <see cref="ValidationCondition"/> that checks whether a packed scene
	/// has a root node of the specified type.
	/// The variable name is used in the error message, defaulting to "Packed Scene".
	/// Returns nested <see cref="ValidationCondition"/> instances describing any mismatch.
	/// </summary>
	/// <typeparam name="T">The expected root node type.</typeparam>
	/// <param name="packedScene">The scene to validate.</param>
	/// <param name="severity">
	/// The severity level reported when validation fails.
	/// Defaults to <see cref="Severity.Error"/>.
	/// </param>
	/// <param name="variableName">The name of the variable that is being validated. Automatically inferred from the variable name in C#, but can be overridden.</param>
	public static ValidationCondition IsSceneOfType<T>(
		PackedScene packedScene,
		InheritanceSearchStrategy inheritanceSearchStrategy =
			InheritanceSearchStrategy.LAST_SCRIPT_ROOT,
		Severity severity = Severity.Error,
		[CallerArgumentExpression(nameof(packedScene))] string variableName = "Packed Scene"
	)
		where T : GodotObject
	{
		var attr =
			typeof(T).GetCustomAttribute<ScriptPathAttribute>()
			?? throw new InvalidOperationException(
				$"{typeof(T).Name} has no [ScriptPath] attribute. Ensure it is a Godot-registered C# class."
			);
		var script = GD.Load<Script>(attr.Path);
		return FromGdStatic(
			"is_scene_of_type",
			packedScene,
			script,
			variableName,
			(int)inheritanceSearchStrategy,
			(int)severity
		);
	}
}

public static class ValidationConditionExtensions
{
	/// <summary>
	/// Extension method to convert an array of <see cref="ValidationCondition"/> instances
	/// to a Godot array of their underlying <see cref="GodotObject"/> representations.
	/// This is used to return validation conditions from C# to GDScript in a format that GDScript can work with.
	/// </summary>
	public static Godot.Collections.Array ToGodotArray(this ValidationCondition[] conditions)
	{
		var godotArray = new Godot.Collections.Array();
		foreach (var condition in conditions)
		{
			godotArray.Add(condition.Inner);
		}
		return godotArray;
	}
}
