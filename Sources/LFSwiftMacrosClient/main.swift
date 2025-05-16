//
//  main.swift
//  LFSwiftMacros
//
//  Created by Luis Finke on 5/16/25.
//

import LFSwiftMacros

@ExtendableEnum
enum Color {
	private enum KnownCases: String {
		case red = "thecolorred"
	}
}

print("red = \(Color.red.rawValue)")
