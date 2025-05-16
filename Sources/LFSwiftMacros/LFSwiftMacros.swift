//
//  LFSwiftMacros.swift
//  LFSwiftMacros
//
//  Created by Luis Finke on 5/16/25.
//

@attached(member, names: arbitrary, named(rawValue), named(init))
@attached(extension, conformances: Hashable)
public macro ExtendableEnum() = #externalMacro(
	module: "LFSwiftMacrosMacros",
	type: "ExtendableEnumMacro"
)
