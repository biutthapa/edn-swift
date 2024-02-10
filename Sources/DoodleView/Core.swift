//
//  Core.swift
//


import Foundation
import DoodleCore
import SwiftUI

// MARK: Reps
func READ(_ input: String) -> [Expr] {
    if input == "quit" || input == "exit" {
        exit(0)
    }
    return readStr(input)
}

func PRINT(_ expr: Expr) -> String {
    return prnStr(expr)
}

func EVAL(_ expr: Expr, _ env: Env) throws -> Expr {
    switch expr {
    case .list(let items) where !items.isEmpty:
        if case .symbol(_) = items.first() {
             if let applied = try apply(items: items, env: env) {
                 return applied
             }
        }

        return try evalList(items: items, env: env)
   
    case .list:
        return expr

    default:
        return try evalAST(expr, env)
    }
}


func rep(_ input: String, _ env: Env) throws -> (output: String, env: Env) {
    let exprs = READ(input)
    let stringOutput = try exprs.map { expr in
        let resExpr = try EVAL(expr, env)
        return PRINT(resExpr)
    }.joined(separator: "\n")
    return (output: stringOutput, env: env)
}

public func initialEnv() -> Env {
    return Env(outer: nil)
        .set(data: coreNS
            .reduce(into: [String: Expr]()) { result, pair in
                result[pair.key] = .lambda(pair.value)
            })
}

public func initialEnv(custom: [String: Lambda]) -> Env {
    let data = coreNS.merging(custom) { _, new in
        return new
    }
    
    return Env(outer: nil)
        .set(data: data
            .reduce(into: [String: Expr]()) { result, pair in
                result[pair.key] = .lambda(pair.value)
            })
}

func applyDef(arguments: [Expr], env: Env) throws -> Expr? {
    guard arguments.count == 2 else {
        throw EvalError.wrongNumberOfArgument(inOperation: "def!", expected: 2.description, found: arguments.count.description)
    }
    guard case let .symbol(name) = arguments.first() else {
        throw EvalError.invalidName(inOperation: "def!")
    }
    let value = try EVAL(arguments.rest().first()!, env)
    let _ = env.set(symbol: name, value: value)
    return value
}

func applyLet(arguments: [Expr], env: Env) throws -> Expr? {
    guard arguments.count == 2 else {
        throw EvalError.wrongNumberOfArgument(inOperation: "let*",
                                              expected: 2.description,
                                              found: arguments.count.description)
    }
    
    let bindings: [Expr]
    switch arguments.first() {
    case .vector(let vectorBindings):
        bindings = vectorBindings
    case .list(let listBindings):
        bindings = listBindings
    default:
        throw EvalError.generalError("The bindings for let must be a vector or a list.")
    }

    guard bindings.count % 2 == 0 else {
        throw EvalError.generalError("The bindings for let supposed be in piars.")
    }

    guard let expression = arguments.rest().first() else {
        throw EvalError.generalError("The expression for let is not valid.")
    }
    
    let innerEnv = Env(outer: env)
    let bindingDictionairy = try bindings.toDictionary()
    
    for binding in bindingDictionairy {
        let evaluatedVal = try EVAL(binding.value, innerEnv)
        let _ = innerEnv.set(symbol: binding.key, value: evaluatedVal)
    }
    
    return try EVAL(expression, innerEnv)
}

func applyDo(expressions: [Expr], env: Env) throws -> Expr? {
    return try expressions.map { try EVAL($0, env) }.last
}

func applyIf(arguments: [Expr], env: Env) throws -> Expr? {
    guard 2...3 ~= arguments.count else {
        throw EvalError.wrongNumberOfArgument(inOperation: "if", expected: "2 or 3", found: String(arguments.count))
    }
    guard let predicate = arguments.first() else {
        throw EvalError.invalidPredicate(inOperation: "if")
    }
    guard let ifTrueExpr = arguments.rest().first() else {
        throw EvalError.generalError("if true expression is invalid")
    }
    let ifFalseExpr = arguments.rest().rest().first()
    
    let evaluatedPredicate = try EVAL(predicate, env)
    switch evaluatedPredicate {
    case .boolean(false), .nil:
        return try EVAL(ifFalseExpr ?? .nil, env)
    default:
        return try EVAL(ifTrueExpr, env)
    }
}


func applyFn(items: [Expr], env: Env) throws -> Expr? {
    guard case let .symbol(symbol) = items.first() else { throw EvalError.generalError("Symbol invalid") }
    let arguments = items.rest() // this mayn not be right
    guard arguments.count == 2 else {
        throw EvalError.wrongNumberOfArgument(inOperation: symbol, expected: "2", found: String(arguments.count))
    }

    let lambdaArgKeysExpr: [Expr]
    switch arguments.first() {
    case .vector(let vectorArgs):
        lambdaArgKeysExpr = vectorArgs
    case .list(let listArgs):
        lambdaArgKeysExpr = listArgs
    default:
        throw EvalError.generalError("The lambda args must be in a vector or a list.")
    }
    
    let lambdaArgKeys: [String] = try lambdaArgKeysExpr.map { expr in
        guard case .symbol(let key) = expr else {
            throw EvalError.generalError("invalid arg binding key in lambda.")
        }
        return key
    }
    
    let lambdaBody: [Expr] = arguments.rest()
    
    return .lambda { lambdaArgValues in
        // in ((fn* [x] (+ x 1)) 3) or (inc 3) with (def! inc (fn* [x] (+ x 1)))
        // in closureEnv, gotta set x = 3.
        // argKeys = ["x"] and argVals = [.number(3)]
        
        // in ((fn* [a b] (+ a b)) 6 4) or (add 3) with (def! add (fn* [a b] (+ a b)))
        // in closureEnv, gotta set a = 6 and b = 4.
        // argKeys = ["a", "b"] and argVals = [.number(6), .number(4)]
        
        let lambdaBinds: [String: Expr] = Dictionary.buildFrom(keys: lambdaArgKeys,
                                                               values: lambdaArgValues)
        
        let closureEnv = Env(outer: env, binds: lambdaBinds)
        
        guard let evaluatedLambdaValue = try lambdaBody.map({ try EVAL($0, closureEnv) }).last() else {
            throw EvalError.generalError("Something wrong whaile evaluating lambda body")
        }
        
        return evaluatedLambdaValue
    }
    
}


func apply(items: [Expr], env: Env) throws -> Expr? {
    guard case .symbol(let symbol) = items.first() else {
        throw EvalError.generalError("First item in apply invalid")
    }
    
    let arguments = items.rest()
    
    switch symbol {
    case "def!":
        return try applyDef(arguments: arguments, env: env)
    case "let*":
        return try applyLet(arguments: arguments, env: env)
    case "do":
        return try applyDo(expressions: arguments, env: env)
    case "if":
        return try applyIf(arguments: arguments, env: env)
    case "fn*", "lambda":
        return try applyFn(items: items, env: env)
    default:
        return nil
    }       
}


func evalList(items: [Expr], env: Env) throws -> Expr {
    let evaluatedList = try items.map { try EVAL($0, env) }
    // TODO: What about for quoted list??
    guard case .lambda(let function) = evaluatedList.first else {
        throw ParserError.invalidInput("First item in list is expected to be a lambda.")
    }
    // Further evaluate any nested lists within the arguments
    let arguments = try evaluatedList.rest().map { item in
        if case .list(_) = item {
            return try EVAL(item, env)
        } else {
            return item
        }
    }
    return try function(arguments)
}

func evalAST(_ ast: Expr, _ env: Env) throws -> Expr {
    switch ast {
    case .list(let items):
        let newList = try items.map { try EVAL($0, env) }
        return .list(newList)

    case .symbol(let sym):
        let val = try env.get(symbol: sym)
        return val

    case .vector(let items):
        return .vector(try items.map { try EVAL($0, env) })

    case .map(let items):
        var newMap = [ExprKey: Expr]()
        for (key, value) in items {
            let evaluatedValue = try EVAL(value, env)
            newMap[key] = evaluatedValue
        }
        return .map(newMap)

    default:
        return ast
    }
}

// MARK: Namespaces/Lambdas

public let viewsNS: [String: ViewLambda] = [
    "text": { args in
        guard args.count >= 1, case let .string(text) = args[0] else {
            throw ViewError.missingRequiredArgument("Text content is required.")
        }

        let modifiers = TextModifiers(
            fontWeight: nil,
            fontSize: nil,
            color: nil,
            customFontName: nil
        )
        return .textView(text, modifiers)
    },
    "rect": { args in
        let color: Color = .black // Placeholder, should implement actual logic
        return .rectView(color)
    }
]

// MARK: Types
public typealias ViewLambda = ([Expr]) throws -> ViewExpr

public enum ViewExpr {
    case textView(String, TextModifiers)
    case rectView(Color)
}

public typealias TextModifiers = (
    fontWeight: Font.Weight?,
    fontSize: CGFloat?,
    color: Color?,
    customFontName: String?
)

enum ViewError: Error {
    case typeMismatch(expected: String, found: String)
    case missingRequiredArgument(String)
    case unsupportedViewType(String)
    case invalidModifierValue(String)
    case custom(String)
}


//// MARK: Make Views
//public func makeViewExprs(from input: String, env: Env, viewsNS: [String: ViewLambda]) -> [ViewExpr] {
//    let exprs = READ(input)
//    var viewExprs: [ViewExpr] = []
//
//    let dynamicTextView: ViewExpr = .textView("Dynamic Text", TextModifiers(fontWeight: .bold, fontSize: 24, color: .green, customFontName: nil))
//    let dynamicRectangle: ViewExpr = .rectView(.blue)
//    return [dynamicTextView, dynamicRectangle]
////    return viewExprs
//}

// MARK: Make Views
public func makeViewExprs(from input: String, env: Env, viewsNS: [String: ViewLambda]) -> [ViewExpr] {
    // Parse the input string into expressions
    let exprs = READ(input)
    var viewExprs: [ViewExpr] = []

    for expr in exprs {
        do {
            // Evaluate each expression in the given environment
            let evaluatedExpr = try EVAL(expr, env)
            // Determine if the evaluated expression corresponds to a view type in the view namespace
            if case let .map(viewProperties) = evaluatedExpr {
                if let viewTypeExpr = viewProperties[.keyword("ui/type")], case let .keyword(viewType) = viewTypeExpr {
                    switch viewType {
                    case "text":
                        if let textLambda = viewsNS["text"], let viewExpr = try? textLambda(Array(viewProperties.values)) {
                            viewExprs.append(viewExpr)
                        }
                    case "rectangle":
                        if let rectLambda = viewsNS["rect"], let viewExpr = try? rectLambda(Array(viewProperties.values)) {
                            viewExprs.append(viewExpr)
                        }
                    default:
                        print("Unsupported view type: \(viewType)")
                    }
                }
            }
        } catch {
            print("Error evaluating expression: \(error)")
        }
    }

    return viewExprs
}


@ViewBuilder
public func makeView(from viewExpr: ViewExpr) -> some View {
    switch viewExpr {
    case let .textView(string, modifiers):
        Text(string)
            .fontWeight(modifiers.fontWeight)
            .font(.system(size: modifiers.fontSize ?? 17))
            .foregroundColor(modifiers.color ?? .primary)
    case let .rectView(color):
        Rectangle()
           .fill(color)
           .frame(maxWidth: .infinity, maxHeight: .infinity)
      
    default:
        EmptyView()
    }
}


