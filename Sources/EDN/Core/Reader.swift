//
//  Reader.swift
//
//
//  Created by Biut Raj Thapa on 29/12/2023.
//

import Foundation

struct Reader {
    let tokens: [String]
    let position: Int

    init(tokens: [String], position: Int = 0) {
        self.tokens = tokens
        self.position = position
    }

    func peek() -> String? {
        guard position < tokens.count else { return nil }
        return tokens[position]
    }

    func next() -> Reader {
        return Reader(tokens: self.tokens, position: self.position + 1)
    }
}

func readForm(_ reader: Reader) throws -> (Expr, Reader) {
    guard let token = reader.peek() else {
        throw ParserError.unexpectedEndOfInput
    }

    switch token.first {
    case "(":
        return try readSequence(reader.next(), startDelimiter: "(", endDelimiter: ")")
    case "[":
        return try readSequence(reader.next(), startDelimiter: "[", endDelimiter: "]")
    case "{":
        return try readHashMap(reader.next())
    default:
        return try readAtom(reader)
    }
}

func readForms(_ reader: Reader) throws -> ([Expr], Reader) {
    var reader = reader
    var expressions = [Expr]()

    while reader.position < reader.tokens.count {
        let (expr, nextReader) = try readForm(reader)
        expressions.append(expr)
        reader = nextReader
    }

    return (expressions, reader)
}


func readAtom(_ reader: Reader) throws -> (Expr, Reader) {
    guard let token = reader.peek() else {
        throw ParserError.unexpectedEndOfInput
    }

    if let number = Double(token) {
        return (.number(number), reader.next())
    } else if token.first == ":" {
        let keyword = String(token.dropFirst())
        return (.keyword(keyword), reader.next())
    } else if token == "nil" {
        return (.nil, reader.next())
    } else if token == "true" {
        return (.boolean(true), reader.next())
    } else if token == "false" {
        return (.boolean(false), reader.next())
    } else if token.first == "\"" {
        return try readStringLiteral(token, reader: reader)
    } else {
        return (.symbol(token), reader.next())
    }
}

func readStringLiteral(_ token: String, reader: Reader) throws -> (Expr, Reader) {
    var processedString = ""
    var escapeNext = false
    for char in token.dropFirst().dropLast() {
        if escapeNext {
            switch char {
            case "\"": processedString += "\""
            case "n": processedString += "\n"
            case "\\": processedString += "\\"
            default: throw ParserError.invalidInput("Invalid escape sequence")
            }
            escapeNext = false
        } else if char == "\\" {
            escapeNext = true
        } else {
            processedString += String(char)
        }
    }
    if escapeNext {
        throw ParserError.invalidInput("Invalid string termination")
    }
    return (.string(processedString), reader.next())
}



func readSequence(_ reader: Reader, startDelimiter: String, endDelimiter: String) throws -> (Expr, Reader) {
    var reader = reader
    var items = [Expr]()

    while let token = reader.peek(), token != endDelimiter {
        let (expr, nextReader) = try readForm(reader)
        items.append(expr)
        reader = nextReader
    }

    guard reader.peek() == endDelimiter else {
        throw ParserError.unbalancedParentheses
    }

    let expr: Expr = (startDelimiter == "(") ? .list(items) : .vector(items)
    return (expr, reader.next())
}



func readHashMap(_ reader: Reader) throws -> (Expr, Reader) {
    var reader = reader
    var map = [ExprKey: Expr]()

    while let token = reader.peek(), token != "}" {
        // Parse the key
        let (keyExpr, nextReaderForKey) = try readForm(reader)
        guard let mapKey = keyExpr.makeKey() else {
            throw ParserError.invalidMapKey
        }
        reader = nextReaderForKey

        // Parse the value
        let (valueExpr, nextReaderForValue) = try readForm(reader)
        map[mapKey] = valueExpr
        reader = nextReaderForValue
    }

    guard reader.peek() == "}" else {
        throw ParserError.unbalancedParentheses
    }

    return (.map(map), reader.next())
}


func tokenizeString(_ input: String) -> [String] {
    let pattern = #"[\s,]*(~@|[\[\]{}()'`~^@]|"(?:\\.|[^\\"])*"?|;.*|[^\s\[\]{}('"`,;)]*)"#
    var tokens = extractMatches(from: input, usingPattern: pattern)
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.trimmingCharacters(in: .whitespaces).starts(with: ";") }

    if let lastToken = tokens.last, lastToken.isEmpty {
        tokens.removeLast()
    }

    return tokens
}

public func readStr(_ input: String) -> [Expr] {
    let tokens = tokenizeString(input)
    let reader = Reader(tokens: tokens, position: 0)
    do {
        let (parsed, _) = try readForms(reader)
        return parsed
    } catch {
        print("Parsing error: \(error)")
        return []
    }
}
