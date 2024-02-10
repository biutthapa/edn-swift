//
//  Printer.swift
//
//
//  Created by Biut Raj Thapa on 29/12/2023.
//

import Foundation

public func prnStr(_ expr: Expr, readably: Bool = false) -> String {
    switch expr {
    case .symbol(let symbol):
        return symbol
    case .keyword(let keyword):
        return ":\(keyword)"
    case .number(let number):
        if floor(number) == number {
            return String(Int(number))
        }
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
    case .lambda:
        return "#<lambda>"
    case .view(_):
        return "#<view>"
    }
}
