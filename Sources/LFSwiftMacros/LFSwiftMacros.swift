// The Swift Programming Language
// https://docs.swift.org/swift-book

/// A macro that produces both a value and a string containing the
/// source code that generated the value. For example,
///
///     #stringify(x + y)
///
/// produces a tuple `(x + y, "x + y")`.
@freestanding(expression)
public macro stringify<T>(_ value: T) -> (T, String) = #externalMacro(module: "LFSwiftMacrosMacros", type: "StringifyMacro")

@attached(member, names: arbitrary, named(rawValue), named(init))
@attached(extension, conformances: Hashable)
public macro ExtendableEnum() = #externalMacro(
	module: "LFSwiftMacrosMacros",
	type: "ExtendableEnumMacro"
)

@freestanding(expression)
public macro `knownCase`<T>(_ value: T) = #externalMacro(
	module: "LFSwiftMacrosMacros",
	type: "ExtendableEnumCaseMacro"
)
