using System;
using System.IO;
using Godot;

namespace GodotDoctor.Core.Primitives;

/// <summary>
/// Represents a range of integers with configurable inclusivity for the end point.
/// Used by <see cref="ValidationCondition"/> for validating integer values against ranges.
/// </summary>
public sealed class RangeInt
{
	public static implicit operator GodotObject(RangeInt range) => range.Inner;

	private const string GD_SCRIPT_PATH =
		"res://addons/godot_doctor/core/primitives/godot_doctor_range_int.gd";

	private static readonly Lazy<Script> _gdScript = new(() => GD.Load<Script>(GD_SCRIPT_PATH));

	/// <summary>
	/// The underlying GDScript instance.
	/// </summary>
	internal readonly GodotObject Inner;

	/// <summary>
	/// Initializes a <see cref="RangeInt"/> with the given parameters.
	/// The range is defined from <paramref name="start"/> to <paramref name="end"/>.
	/// The end may optionally be included.
	/// By default, the range is exclusive.
	/// </summary>
	/// <param name="start">The start of the range.</param>
	/// <param name="end">The end of the range.</param>
	/// <param name="inclusiveEnd">
	/// Whether the end of the range is included.
	/// </param>
	/// <exception cref="ArgumentException">
	/// Thrown if <paramref name="start"/> is greater than <paramref name="end"/>.
	/// </exception>
	public RangeInt(int start = 0, int end = 0, bool inclusiveEnd = false)
	{
		if (start > end)
			throw new InvalidDataException("End must be greater than or equal to start.");

		Inner = (GodotObject)_gdScript.Value.Call("new", start, end, inclusiveEnd);
	}

	/// <summary>
	/// Returns <see langword="true"/> if the specified value is within this range;
	/// otherwise, <see langword="false"/>.
	/// </summary>
	/// <param name="value">The value to test.</param>
	public bool Contains(int value) => (bool)Inner.Call("contains", value);

	/// <summary>
	/// Returns <see langword="true"/> if the specified range is completely within this range;
	/// otherwise, <see langword="false"/>.
	/// </summary>
	/// <param name="other">The range to test.</param>
	public bool Contains(RangeInt other) => (bool)Inner.Call("contains_range", other.Inner);
}
