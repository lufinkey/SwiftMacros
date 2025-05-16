//
//  Main.swift
//  LFSwiftMacros
//
//  Created by Luis Finke on 5/16/25.
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct LFSwiftMacrosPlugin: CompilerPlugin {
	let providingMacros: [Macro.Type] = [
		ExtendableEnumMacro.self
	]
}
