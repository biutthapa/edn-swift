//
//  Utils.swift
//
//
//  Created by Biut Raj Thapa on 29/12/2023.
//

import Foundation

func compileRegexPattern(_ patternString: String) -> NSRegularExpression? {
	do {
		return try NSRegularExpression(pattern: patternString)
	} catch {
		print("Invalid regex: \(error.localizedDescription)")
		return nil
	}
}

func findAllMatches(with compiledRegex: NSRegularExpression, in targetString: String) -> [String] {
	let range = NSRange(targetString.startIndex..., in: targetString)
	let matches = compiledRegex.matches(in: targetString, range: range)
	
	return matches.map {
		let matchRange = Range($0.range, in: targetString)!
		return String(targetString[matchRange])
	}
}

func extractMatches(from sourceString: String, usingPattern regexPattern: String) -> [String] {
	guard let compiledRegex = compileRegexPattern(regexPattern) else {
		print("Invalid regex pattern")
		return []
	}
	return findAllMatches(with: compiledRegex, in: sourceString)
}

func test_extractMatches(_ input: String) -> [String] {
	let intPattern = "^-?[0-9]+$"
	return extractMatches(from: input, usingPattern: intPattern)
}

func correspondingDelimiter(for delimiter: String) -> String {
	switch delimiter {
		case "(": return ")"
		case "[": return "]"
		case "{": return "}"
		default: return ""
	}
}
