//
//  Env.swift
//  
//
//  Created by Biut Raj Thapa on 30/01/2024.
//

import Foundation

public class Env {
    private var outer: Env?
    private var data: [String: Expr] = [:]

    public init(outer: Env?) {
        self.outer = outer
    }
    
    public init(outer: Env?, binds: [String: Expr]) {
        self.outer = outer
        self.data = binds
    }

    public func set(symbol key: String, value: Expr) -> Env {
        data[key] = value
        return self
    }
    
    public func set(data: [String: Expr]) -> Env {
        data.forEach { key, value in
            self.data[key] = value
        }
        return self
    }
    
    public func get(symbol key: String) throws -> Expr {
        guard let val = find(symbol: key) else {
            throw EnvError.symbolNotFound(symbol: key, available: self.allSymbols())
        }
        return val
    }

    private func find(symbol key: String) -> Expr? {
        if let val = data[key] {
          return val
        }
        
        if let outer = outer {
            return outer.find(symbol: key)
        }
        return nil
    }
    
    public func allSymbols() -> [String] {
        let dataKeys = data.keys.map { String($0) }
        if let outerDataKeys = outer?.allSymbols() {
            return dataKeys + outerDataKeys
        }
        return dataKeys
    }
        
}
