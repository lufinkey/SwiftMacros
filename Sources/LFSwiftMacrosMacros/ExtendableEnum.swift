//
//  ExtendableEnum.swift
//  LFSwiftMacros
//
//  Created by Luis Finke on 5/16/25.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/* // declared enum should look like this
@ExtendableEnum
enum Status {
	private enum KnownCases: String {
		case active = "active"
		case inactive = "inactive"
	}
}
*/

/* // final enum should look like this
enum Status {
	case active
	case inactive
	case unknown(_ rawValue: RawValue)
	
	private static let knownValuesMap: [Self:RawValue] = [
		.active: "active"
		.inactive: "inactive"
	]
	
	private static let knownKeysMap: [RawValue:Self] = {
		var map: [RawValue:Self] = [:]
		for (key,value) in Self.knownValuesMap {
			map[value] = key
		}
		return map
	}()
 
	public init(rawValue: RawValue) {
		if let match = Self.knownKeysMap[rawValue] {
			self = match
		} else {
			self = .unknown(rawValue)
		}
	}
	
	public var rawValue: RawValue {
		if case let .unknown(rawValue) = self {
			return rawValue
		} else {
			return Self.knownValuesMap[self]!
		}
	}
}
*/

public struct ExtendableEnumMacro: MemberMacro, ExtensionMacro {
	// extensions
	public static func expansion(
		of node: SwiftSyntax.AttributeSyntax,
		attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
		providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
		conformingTo protocols: [SwiftSyntax.TypeSyntax],
		in context: some SwiftSyntaxMacros.MacroExpansionContext
	) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
		// Ensure this is being used on an enum
		guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
			throw MacroExpansionErrorMessage("@ExtendableEnum can only be applied to enums")
		}
		var extensions: [ExtensionDeclSyntax] = []
		if !(enumDecl.inheritanceClause?.inheritedTypes.contains(where: { $0.type.trimmedDescription == "Hashable" || $0.type.trimmedDescription == "Swift.Hashable" }) ?? false) {
			let hashableExtension: DeclSyntax =
				"""
				extension \(type.trimmed): Hashable {}
				"""
			extensions.append(hashableExtension.as(ExtensionDeclSyntax.self)!)
		}
		return extensions
	}
	
	// members
	public static func expansion(
		of node: AttributeSyntax,
		providingMembersOf declaration: some DeclGroupSyntax,
		conformingTo protocols: [TypeSyntax],
		in context: some MacroExpansionContext
	) throws -> [DeclSyntax] {
		// Ensure this is being used on an enum
		guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
			throw MacroExpansionErrorMessage("@ExtendableEnum can only be applied to enums")
		}
		
		// Get the KnownCases enum
		guard let knownCasesDecl = enumDecl.memberBlock.members.first(where: { $0.decl.as(EnumDeclSyntax.self)?.name.text == "KnownCases" })?.decl.as(EnumDeclSyntax.self)! else {
			throw MacroExpansionErrorMessage("KnownCases enum must be declared")
		}
		// Ensure KnownCases is private
		if !knownCasesDecl.modifiers.contains(where: { $0.name.text == "private" }) {
			throw MacroExpansionErrorMessage("KnownCases enum must be private")
		}
		// Get the inherited type of KnownCases
		guard let rawValueType = knownCasesDecl.inheritanceClause?.inheritedTypes.first else {
			throw MacroExpansionErrorMessage("KnownCases enum must inherit from a type")
		}
		let rawValueTypeName = rawValueType.type.trimmedDescription
		
		// Get all the known value cases
		var caseNames: [String] = []
		for member in knownCasesDecl.memberBlock.members {
			// ensure this is an enum case
			guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else {
				continue
			}
			// loop through the case elements (ie: comma separated names after the "case" keyword)
			for elem in caseDecl.elements {
				let name = elem.name.text
				// ensure enum case has no parameters
				if elem.parameterClause != nil {
					throw MacroExpansionErrorMessage("Known enum case \(name) may not have parameters")
				}
				caseNames.append(name)
			}
		}
		
		// Add cases to enum
		let casesDecl: [DeclSyntax] = caseNames.map { "case \(raw: $0)" }
		
		// Get the name of the unknown case
		let fullUnknownCaseName = "unknown(_:)"
		let unknownCaseName: String
		let unknownCasePrefix: String
		if let parenthIndex = fullUnknownCaseName.lastIndex(of: "(") {
			var index = parenthIndex
			// backtrack to start of whitespace
			while index != fullUnknownCaseName.startIndex {
				let prevIndex = fullUnknownCaseName.index(before:index)
				let prevChar = fullUnknownCaseName[prevIndex]
				if !(prevChar.isWhitespace || prevChar.isNewline) {
					break
				}
				index = prevIndex
			}
			// backtrack to start of identifier
			let nameEndIndex = index
			while index != fullUnknownCaseName.startIndex {
				let prevIndex = fullUnknownCaseName.index(before:index)
				let prevChar = fullUnknownCaseName[prevIndex]
				if (prevChar.isWhitespace || prevChar.isNewline) {
					break
				}
				index = prevIndex
			}
			// we have the range of the name
			let nameStartIndex = index
			unknownCaseName = String(fullUnknownCaseName[nameStartIndex..<nameEndIndex])
			if unknownCaseName.isEmpty {
				throw MacroExpansionErrorMessage("Invalid empty case name")
			}
			// find colon
			let paramNameStartIndex = fullUnknownCaseName.index(after: parenthIndex)
			guard let colonIndex = fullUnknownCaseName[paramNameStartIndex..<fullUnknownCaseName.endIndex].firstIndex(of: ":") else {
				throw MacroExpansionErrorMessage("Missing colon after param name in \(fullUnknownCaseName.debugDescription) case name")
			}
			// parse identifier
			let paramName = fullUnknownCaseName[paramNameStartIndex..<colonIndex]
			let identifierParts = splitOnWhitespace(paramName)
			if identifierParts.count == 0 {
				throw MacroExpansionErrorMessage("Invalid empty parameter name")
			} else if identifierParts.count > 2 {
				throw MacroExpansionErrorMessage("Invalid parameter name \(paramName.debugDescription)")
			}
			if identifierParts[0] == "_" {
				unknownCasePrefix = "\(unknownCaseName)("
			} else {
				unknownCasePrefix = "\(unknownCaseName)(\(identifierParts[0]):"
			}
		} else {
			unknownCaseName = fullUnknownCaseName
			unknownCasePrefix = "\(unknownCaseName)("
		}
		
		// Check if the unknown case is already defined
		let existingUnknownCaseDecl = enumDecl.memberBlock.members.lazy.compactMap { member in
			return member.decl.as(EnumCaseDeclSyntax.self)?.elements.first(where: { element in
				return element.name.text == unknownCaseName
			})
		}.first
		if let existingUnknownCaseDecl {
			// unknown case is defined
			if existingUnknownCaseDecl.parameterClause?.parameters.count != 1 {
				throw MacroExpansionErrorMessage("Unknown case `\(unknownCaseName)` must have exactly one parameter")
			}
			let paramTypeName = existingUnknownCaseDecl.parameterClause?.parameters.first?.type.trimmedDescription
			if paramTypeName != rawValueTypeName && paramTypeName != "RawValue" {
				throw MacroExpansionErrorMessage("Unknown case must take a single parameter of type RawValue or \(rawValueTypeName) (found \(paramTypeName ?? "<nil>"))")
			}
		}
		
		// Create `.unknown(_ rawValue: RawValue)` if not already present
		let unknownCaseDecl: DeclSyntax? = (existingUnknownCaseDecl == nil) ? "case \(raw: unknownCasePrefix) \(raw: rawValueType))" : nil
		
		// Create known values map
		let knownValuesMapDecl: DeclSyntax =
			"""
			private static let knownValuesMap: [Self:KnownCases.RawValue] = [
				\(raw: caseNames.map {
					".\($0): Self.KnownCases.\($0).rawValue,"
				}.joined(separator: "\n\t"))
			]
			"""
		
		// Create known keys map
		let knownKeysMapDecl: DeclSyntax =
			"""
			private static let knownKeysMap: [KnownCases.RawValue:Self] = {
				var map: [\(raw: rawValueTypeName):Self] = [:]
				for (key,val) in Self.knownValuesMap {
					map[val] = key
				}
				return map
			}()
			"""
		
		// Create rawValue member var
		let rawValueDecl: DeclSyntax =
			"""
			public var rawValue: \(raw: rawValueTypeName) {
				if case let .unknown(rawValue) = self {
					return rawValue
				} else {
					return Self.knownValuesMap[self]!
				}
			}
			"""
		
		let initDecl: DeclSyntax =
			"""
			public init(rawValue: \(raw: rawValueTypeName)) {
				if let match = Self.knownKeysMap[rawValue] {
					self = match
				} else {
					self = .unknown(rawValue)
				}
			}
			"""
		
		return casesDecl + (unknownCaseDecl.map { [$0] } ?? []) + [knownValuesMapDecl, knownKeysMapDecl, rawValueDecl, initDecl]
		
		/*// Get RawValue type from generic argument
		guard let genericArgument = node.attributeName.as(IdentifierTypeSyntax.self)?
				.genericArgumentClause?.arguments.first?.argument else {
			throw MacroExpansionErrorMessage("Missing generic type (e.g. @ExtendableEnum<String>)")
		}
		
		let rawType = genericArgument.description.trimmingCharacters(in: .whitespaces)

		// Extract case values
		var caseMap: [String:ExprSyntax] = [:]
		var hasUnknownCase = false
		for member in enumDecl.memberBlock.members {
			// ensure this is an enum case
			guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else {
				continue
			}
			// loop through the case elements (ie: comma separated names after the "case" keyword)
			for elem in caseDecl.elements {
				let name = elem.name.text
				// check if this is the unknown case
				if name == "unknown" {
					// ignore the unknown case for now
					hasUnknownCase = true
					continue
				}
				// get the raw literal assigned to this case (ie: case active = "active")
				guard let rawLiteral = elem.rawValue?.value else {
					throw MacroExpansionErrorMessage("Case '\(name)' must have a literal raw value")
				}

				caseMap[name] = rawLiteral
			}
		}
		
		// Add `.unknown(_ rawValue: RawValue)` if not already present
		let unknownCaseDecl: DeclSyntax? = hasUnknownCase ? nil : "case unknown(_ rawValue: \(raw: rawType))"
		
		// Create known values map
		let knownValuesMapDecl: DeclSyntax =
			"""
			private static var knownValuesMap: [Self:\(raw: rawType)] = [
				\(raw: caseMap.map {
					".\($0.key): \($0.value),"
				}.joined(separator: "\n\t"))
			]
			"""
		
		// Create known keys map
		let knownKeysMapDecl: DeclSyntax =
			"""
			private static var knownKeysMap: [\(raw: rawType):Self] = {
				let map: [\(raw: rawType):Self] = [:]
				for (key,val) in Self.knownValuesMap {
					map[key] = val
				}
				return map
			}()
			"""
		
		// Create rawValue member var
		let rawValueDecl: DeclSyntax =
			"""
			public var rawValue: \(raw: rawType) {
				if case let .unknown(rawValue) = self {
					return rawValue
				} else {
					return Self.knownValuesMap[self]!
				}
			}
			"""
		
		let initDecl: DeclSyntax =
			"""
			public init(rawValue: \(raw: rawType)) {
				if let match = Self.knownKeysMap[rawValue] {
					self = match
				} else {
					self = .unknown(rawValue)
				}
			}
			"""
		
		return [knownValuesMapDecl, knownKeysMapDecl, rawValueDecl, initDecl] + (unknownCaseDecl.map { [$0] } ?? [])*/
	}
}

public struct ExtendableEnumCaseMacro: DeclarationMacro {
	public static func expansion(
		of node: some SwiftSyntax.FreestandingMacroExpansionSyntax,
		in context: some SwiftSyntaxMacros.MacroExpansionContext
	) throws -> [SwiftSyntax.DeclSyntax] {
		/*// ensure this macro is directly within an enum
		guard let enclosingEnum = node.parent?.as(EnumDeclSyntax.self) else {
			throw MacroExpansionErrorMessage("#case can only be used inside an enum")
		}
		
		// ensure the enum has the ExtendableEnum macro
		guard enclosingEnum.attributes.contains(where: { $0.as(AttributeSyntax.self)?.attributeName.trimmedDescription == "ExtendableEnum" }) else {
			throw MacroExpansionErrorMessage("#case can only be used inside an enum marked with @ExtendableEnum")
		}*/
		
		// expand to nothing
		return []
	}
}
