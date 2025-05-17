//
//  LFSwiftMacros.swift
//  LFSwiftMacros
//
//  Created by Luis Finke on 5/16/25.
//

@attached(member, names: arbitrary, named(rawValue), named(init))
@attached(extension, conformances: Hashable, RawRepresentable, ExtendableEnum)
public macro ExtendableEnum() = #externalMacro(
	module: "LFSwiftMacrosMacros",
	type: "ExtendableEnumMacro"
)

public protocol ExtendableEnum {
	associatedtype RawValue
	
	static var knownCases: [Self] { get }
	var rawValue: RawValue { get }
	
	init(rawValue: RawValue)
}
