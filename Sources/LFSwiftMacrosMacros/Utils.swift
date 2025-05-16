//
//  Utils.swift
//  LFSwiftMacros
//
//  Created by Luis Finke on 5/16/25.
//

internal func splitOnWhitespace(_ string: Substring) -> [Substring] {
	var parts: [Substring] = []
	var startIndex = string.startIndex
	var searchStartIndex = startIndex
	while let whitespaceIndex = string[searchStartIndex..<string.endIndex].firstIndex(where: { $0.isWhitespace || $0.isNewline }) {
		let part = string[startIndex..<whitespaceIndex]
		if !part.isEmpty {
			parts.append(part)
		}
		let whitespaceEndSearchStart = string.index(after:whitespaceIndex) // already compared this index, so move to the next one
		if let whitespaceEndIndex = string[whitespaceEndSearchStart..<string.endIndex].firstIndex(where: { !($0.isWhitespace || $0.isNewline) }) {
			startIndex = whitespaceEndIndex
			searchStartIndex = string.index(after: whitespaceEndIndex) // already compared this index, so move to the next one
		} else {
			startIndex = string.endIndex
			searchStartIndex = string.endIndex
			break
		}
	}
	let part = string[startIndex..<string.endIndex]
	if !part.isEmpty {
		parts.append(part)
	}
	return parts
}
