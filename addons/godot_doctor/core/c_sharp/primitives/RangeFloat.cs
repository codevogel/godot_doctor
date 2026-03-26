using System;
using System.IO;
using Godot;

namespace GodotDoctor.Core.Primitives;

/// <summary>
/// Represents a range of floating-point numbers with
/// configurable inclusivity for the end point and tolerance for comparisons.
/// </summary>
public sealed class RangeFloat
{
	public static implicit operator GodotObject(RangeFloat range) => range.Inner;

	private const string GD_SCRIPT_PATH =
		"res://addons/godot_doctor/core/primitives/godot_doctor_range_float.gd";

	private static readonly Lazy<Script> _gdScript = new(() => GD.Load<Script>(GD_SCRIPT_PATH));

	/// <summary>
	/// The underlying GDScript instance.
	/// </summary>
	internal readonly GodotObject Inner;

	/// <summary>
	/// Initializes a <see cref="RangeFloat"/> with the given parameters.
	/// The range is defined from <paramref name="start"/> to <paramref name="end"/>.
	/// The end may optionally be included, and comparisons use a configurable epsilon tolerance.
	/// By default, the range is exclusive.
	/// </summary>
	/// <param name="start">The start of the range.</param>
	/// <param name="end">The end of the range.</param>
	/// <param name="inclusiveEnd">
	/// Whether the end of the range is included.
	/// </param>
	/// <param name="epsilon">
	/// The tolerance used for floating-point comparisons.
	/// Defaults to <see cref="EPSILON_DEFAULT"/>.
	/// </param>
	/// <exception cref="ArgumentException">
	/// Thrown if <paramref name="start"/> is greater than <paramref name="end"/>.
	/// </exception>
	public RangeFloat(
		float start = 0.0f,
		float end = 0.0f,
		bool inclusiveEnd = false,
		float epsilon = Mathf.Epsilon
	)
	{
		if (start > end)
			throw new InvalidDataException("End must be greater than or equal to start.");

		Inner = (GodotObject)_gdScript.Value.Call("new", start, end, inclusiveEnd, epsilon);
	}

	/// <summary>
	/// Returns true if the specified value is within this range;
	/// otherwise, false.
	/// </summary>
	/// <param name="value">The value to test.</param>
	public bool Contains(float value) => (bool)Inner.Call("contains", value);

	/// <summary>
	/// Returns true if the specified range is completely within this range;
	/// otherwise, false.
	/// </summary>
	/// <param name="other">The range to test.</param>
	public bool Contains(RangeFloat other) => (bool)Inner.Call("contains_range", other.Inner);
}
