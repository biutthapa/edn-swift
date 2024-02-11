//
//  Examples/SayHello.swift
//  
//
//  Created by Biut Raj Thapa on 11/02/2024.
//

import Foundation
import EDN

let ednString = """
{:name "Bond"}
"""

sayHello(ednString: ednString)




func sayHello(ednString: String) {
    let name: String? = getName(from: ednString)
    if let name = name {
        print("Hello, \(name)")
    } else {
        print("Hello, there")
    }
}


func getName(from ednString: String) -> String? {
    let ednExpr = readEDN(from: ednString, env: initialEnv())
    
    if case .map(let map) = ednExpr {
        if let nameExpr = map[.keyword(":name")] {
            if case .string(let name) = nameExpr {
                return name
            }
        }
    }
    
    return nil
}

