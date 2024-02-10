//
//  Conversion.swift
//  
//
//  Created by Biut Raj Thapa on 09/02/2024.
//

import DoodleCore


// Expr -> ViewExpr converter
//
//func convert(expr: Expr) throws -> ViewExpr {
//    switch expr {
//    case .list(let exprList):
//        guard let firstExpr = exprList.first, case .symbol(let symbol) = firstExpr, let lambda = viewsNS[symbol] else {
//            throw ViewError.unsupportedViewType("Unsupported or undefined view type.")
//        }
//        return try lambda(Array(exprList.dropFirst()))
//    default:
//        throw ViewError.typeMismatch(expected: "List", found: "\(expr)")
//    }
//}

