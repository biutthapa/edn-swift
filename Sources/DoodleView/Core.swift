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

func initialEnv() -> Env {
    return Env(outer: nil)
        .set(data: coreNS
            .reduce(into: [String: Expr]()) { result, pair in
                result[pair.key] = .lambda(pair.value)
            })
}

func initialEnv(custom: [String: Lambda]) -> Env {
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

public class DoodleSession {
    var inputString: String
    var env: Env
    
    public init(env: Env) {
        self.env = env
    }
    
    func beginSession() -> View throws {
        while true {
            if let input = readLine(strippingNewline: true) {
                guard input != "" else { continue }
                do {
                    let rep = try rep(input, env)
                    print(rep.output)
                    env = rep.env
                } catch {
                    print(error)
                }
            } else {
                exit(0);
            }
        }
    }
}

let doodleViewNS = initialEnv(custom: customNS)
let doodleSession = DoodleSession(env: initialEnv())

//try doodleSession.beginSession()





// MARK: TYPES

public typealias ColorMap = [String: Color]


public protocol ViewExpr {
    func makeView() -> AnyView
}

public struct TextViewExpr: ViewExpr {
    var text: String
    var modifiers: TextModifiers
    
    public func makeView() -> AnyView {
        AnyView(
            Text(text)
                .fontWeight(modifiers.fontWeight)
                .font(.system(size: modifiers.fontSize ?? 17))
                .foregroundColor(modifiers.color)
        )
    }
}

public struct RectViewExpr: ViewExpr {
    var color: Color
    var size: CGSize

    public func makeView() -> AnyView {
        AnyView(Rectangle()
                    .fill(color)
                    .frame(width: size.width, height: size.height))
    }
}


public enum ViewError: Error {
    case typeMismatch(expected: String, found: String)
    case missingRequiredArgument(String)
    case unsupportedViewType(String)
    case invalidModifierValue(String)
    case custom(String)
}

public struct TextModifiers {
    var fontWeight: Font.Weight?
    var fontSize: CGFloat?
    var color: Color
    var customFontName: String?
}


// MARK: Reader

// Note: extending Expr with new case is not allowed.
//
// Note: use value of ":ui/type" in input map to know which view to use inside evalViewMap.
//
let ExampleOfViewMapString = """
{:ui/type :text
 :text "The best laid plans"
 :foreground-style :red}
"""
//
// viewMap is a <#T##[ExprKey : Expr]#> ofcourse.

//public let exampleDynamicTextView: ViewExpressable = .textView("Dynamic Text", TextModifiers(fontWeight: .bold, fontSize: 24, color: .green, customFontName: nil))
//public let exampleDynamicRectangle: ViewExpressable = .rectView(.blue)
//

public typealias ViewMakerLambda = ([Expr]) throws -> ViewExpr

func exprMapToTextViewExpr(_ map: [ExprKey: Expr]) throws -> TextViewExpr {
   throw EvalError.generalError("Not Implemented")
}

let textLambda: ViewMakerLambda = { args in
     guard let firstArg = args.first, case .map(let map) = firstArg else {
        throw EvalError.generalError("Expected a map for 'text' view definition.")
    }
    let textViewExpr = try exprMapToTextViewExpr(map)
    return textViewExpr
}

let rectLambda: ViewMakerLambda = { args in
    guard let firstArg = args.first, case .map(let map) = firstArg else {
        throw EvalError.generalError("Expected a map for 'rect' view definition.")
    }
    let rectViewExpr = try exprMapToRectViewExpr(map)
    return rectViewExpr
}

func exprMapToRectViewExpr(_ map: [ExprKey: Expr]) throws -> RectViewExpr {
      throw EvalError.generalError("Not Implemented")
}



public let colorMap: ColorMap = [
    "red": .red,
    "blue": .blue,
    "green": .green,
]

public func colorFromExprMap(_ map: [ExprKey: Expr]) -> Color {
    guard case let .string(colorName) = map[.keyword("color")] else { return .black }
    return colorMap[colorName, default: .black]
}



public func readViewMap(_ viewMap: [ExprKey: Expr]) throws -> ViewExpr {
    guard case let .keyword(uiType) = viewMap[.keyword("ui/type")] else {
        throw ViewError.custom("Missing or invalid :ui/type in view map.")
    }
    switch uiType {
    case "text":
        guard case let .string(text) = viewMap[.keyword("text")] else {
            throw ViewError.missingRequiredArgument("Text content is required for :text type.")
        }
        let color = colorFromExprMap(viewMap)
        let modifiers = TextModifiers(fontWeight: nil, fontSize: 12, color: .black, customFontName: nil)
        return TextViewExpr(text: text, modifiers: modifiers)
    case "rectangle":
        let color = colorFromExprMap(viewMap)
        return RectViewExpr(color: .blue, size: CGSize(width: 100, height: 100))
    default:
        throw ViewError.unsupportedViewType(uiType)
    }
}



public func makeViewExprs(from input: String, env: Env) throws -> [ViewExpr] {
    let exprs: [Expr] = READ(input)
    var viewExprs: [ViewExpr] = []
    
    for expr in exprs {
        let evaluatedExpr: Expr = try EVAL(expr, env)
        if let viewExpr: ViewExpr = try? evaluatedExpr.toViewExpr() {
            viewExprs.append(viewExpr)
        } else {
            throw ViewError.invalidModifierValue("Unable to convert evaluated expression to ViewExpr.")
        }
    }
    
    return viewExprs
}


public extension Expr {
    func toViewExpr() throws -> ViewExpr {
        switch self {
        case let .map(map):
            return try readViewMap(map)
        default:
            throw ViewError.custom("Unsupported Expr type for conversion to ViewExpr.")
        }
    }
}
