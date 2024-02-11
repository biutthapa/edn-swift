//
//  Extensions.swift
//  
//
//  Created by Biut Raj Thapa on 04/02/2024.
//

import Foundation

extension String {
    public func toSymbol() -> Expr {
        return .symbol(self)
    }

    public func toKeyword() -> Expr {
        return .keyword(self)
    }
}

extension Array where Element == Expr {
    public func toDictionary() throws -> [String: Expr] {
        guard self.count % 2 == 0 else {
            throw EvalError.generalError("Bindings in let should be expressed in pairs.")
        }
        
        return stride(from: 0, to: self.count, by: 2)
            .reduce(into: [String: Expr]()) { dict, i in
                guard case let .symbol(key) = self[i], i + 1 < self.count else { return }
                dict[key] = self[i + 1]
            }
    }
}

extension ExprKey {
    public func toString(readably: Bool = false) -> String {
        switch self {
        case .symbol(let symbol):
            return symbol
        case .keyword(let keyword):
            return ":\(keyword)"
        case .number(let number):
            return String(number)
        case .boolean(let boolean):
            return boolean ? "true" : "false"
        case .string(let string):
            if readably {
                let out = string.replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: "\"", with: "\\\"")
                    .replacingOccurrences(of: "\n", with: "\\n")
                return out
            } else {
                return "\"\(string)\""
            }

        case .list(let list):
            let listContents = list.map{ prnStr($0, readably: readably) }.joined(separator: " ")
            return "(\(listContents))"
        case .vector(let vector):
            let vectorContents = vector.map{ prnStr($0, readably: readably) }.joined(separator: " ")
            return "[\(vectorContents)]"
        case .map(let mapPairs):
            let mapContents = mapPairs.map { (key, value) in prnStr(key.toExpr(), readably: readably) + " " + prnStr(value, readably: readably) }.joined(separator: " ")
            return "{\(mapContents)}"
        case .nil:
            return "nil"
        }
    }
}

// Predicates
extension Expr {
    public func isEmptyP() -> Bool {
        switch self {
        case .vector(let items), .list(let items):
            return items.isEmpty
        case .map(let items):
            return items.isEmpty
        default:
            return false
        }
    }
    
    public func isVectorP() -> Bool {
        if case .vector(_) = self {
            return true
        }
        return false
    }
    
    public func isListP() -> Bool {
        if case .list(_) = self {
            return true
        }
        return false
    }
    
    public func count() throws -> Int {
        switch self {
        case .vector(let items), .list(let items):
            return items.count
        case .map(let items):
            return items.count
        // case .string(_):
        //  <#code#>
        default:
            throw EvalError.generalError("Expected sequence types on count.")
        }
    }
}

public extension Expr {
    var numberValue: Number? {
        if case let .number(value) = self { return value }
        return nil
    }

    func makeKey() -> ExprKey? {
        switch self {
        case .symbol(let sym):
            return .symbol(sym)
        case .keyword(let sym):
            return .keyword(sym)
        case .number(let num):
            return .number(num)
        case .string(let str):
            return .string(str)
        default:
            return nil
        }
    }
}

public extension ExprKey {
    func toExpr() -> Expr {
        switch self {
        case .symbol(let value):
            return .symbol(value)
        case .keyword(let value):
            return .keyword(value)
        case .number(let value):
            return .number(value)
        case .boolean(let value):
            return .boolean(value)
        case .string(let value):
            return .string(value)
        case .list(let exprList):
            return .list(exprList)
        case .vector(let exprVector):
            return .vector(exprVector)
        case .map(let exprMap):
            return .map(exprMap)
        case .nil:
            return .nil
        }
    }
}

extension Array where Element == Expr {
    // car: Returns the first element of the array, if present,
    public func first() -> Expr? {
        guard !self.isEmpty else { return .nil }
        return self[0]
    }
    
    // cdr: Returns a new array containing all elements except the first
    public func rest() -> [Expr] {
        guard !self.isEmpty else { return [] }
        return Array(self[1..<self.count])
    }
    
    public func last() -> Expr? {
        guard !self.isEmpty else { return .nil }
        return self[self.count - 1]
    }
    
    public func count() -> Int {
        guard !self.isEmpty else { return 0 }
        return self.count
    }
    
    public func areEqualP() throws -> Bool {
        guard !self.isEmpty else {
            throw EvalError.wrongNumberOfArgument(inOperation: "areEqual?", expected: "atleast 1",
                                                  found: "\(self.count)")
        }
        return self.allSatisfy { $0 == self.first }
    }
    
   

}

extension Dictionary where Key == String, Value == Expr {
    public static func buildFrom(keys: [String], values: [Expr]) -> [String: Expr] {
        do {
            guard keys.count == values.count else {
                throw DataError.unequalKeyValueCount("in Dictionary's buildFrom.")
            }
        } catch {
            print(error)
        }
        
        return Dictionary(uniqueKeysWithValues: zip(keys, values))
    }
}

extension Dictionary {
    
    // Create a new dictionary with added or updated key-value pairs
    public func assoc(_ key: Key, _ value: Value) -> Dictionary {
        var newDict = self
        newDict[key] = value
        return newDict
    }
    
    // Merge two dictionaries, with values from the second dict overriding those from the first in case of key conflicts
    public func merge(with dict: Dictionary) -> Dictionary {
        return self.merging(dict) { (_, new) in new }
    }
    
    // Retrieves the value for a key, or returns a default value if the key is not found
    public func get(_ key: Key, defaultValue: Value) -> Value {
        return self[key] ?? defaultValue
    }
    
    // Updates the value for a key using a transformation function, if the key exists
    public func update(_ key: Key, transform: (Value) -> Value) -> Dictionary {
        var newDict = self
        if let currentValue = newDict[key] {
            newDict[key] = transform(currentValue)
        }
        return newDict
    }
    
    // Selects a new dictionary with only the specified keys
    public func selectKeys(_ keys: [Key]) -> Dictionary {
        return keys.reduce(into: Dictionary()) { result, key in
            if let value = self[key] {
                result[key] = value
            }
        }
    }
    
    // Checks if a key is present in the dictionary
    public func containsKey(_ key: Key) -> Bool {
        return self[key] != nil
    }
    
    // Transform keys and values with given functions
    public func mapKeys<T>(_ transform: (Key) -> T) -> Dictionary<T, Value> {
        return self.reduce(into: Dictionary<T, Value>()) { result, entry in
            result[transform(entry.key)] = entry.value
        }
    }
    
    public func mapValues<T>(_ transform: (Value) -> T) -> Dictionary<Key, T> {
        return self.reduce(into: Dictionary<Key, T>()) { result, entry in
            result[entry.key] = transform(entry.value)
        }
    }
}



extension Expr: Equatable {
    public static func ==(lhs: Expr, rhs: Expr) -> Bool {
        switch (lhs, rhs) {
        case (.symbol(let a), .symbol(let b)):
            return a == b
        case (.keyword(let a), .keyword(let b)):
            return a == b
        case (.string(let a), .string(let b)):
            return a == b
        case (.number(let a), .number(let b)):
            return a == b
        case (.boolean(let a), .boolean(let b)):
            return a == b
        case (.list(let a), .list(let b)):
            return a == b
        case (.vector(let a), .vector(let b)):
            return a == b
        case (.map(let a), .map(let b)):
            return a == b
        case (.nil, .nil):
            return true
        case (.lambda, .lambda):
            // Lambda functions are treated as always unequal
            return false
        case (.list(_), _),
             (.vector(_), _),
             (.map(_), _),
             (.nil, _):
            return false
        default:
            return false
        }
    }
}


extension Expr: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .symbol(let value), .keyword(let value), .string(let value):
            hasher.combine(value)
        case .number(let value):
            hasher.combine(value)
        case .boolean(let value):
            hasher.combine(value)
        case .list(let list):
            hasher.combine(list)
        case .vector(let vector):
            hasher.combine(vector)
        case .map(let map):
            for (key, value) in map {
                hasher.combine(key)
                hasher.combine(value)
            }
        case .nil:
            hasher.combine(0) // Arbitrary value for nil
        case .lambda:
            hasher.combine("lambda")
        case .view(_):
            hasher.combine("view")
        }
    }
}
