//
//  Examples/CurrencyConversion.swift
//  
//
//  Created by Biut Raj Thapa on 11/02/2024.
//

import Foundation
import EDN

let stringInput = """
{
  :conversion-logic (fn [amount conversion-factor] (* amount conversion-factor))
  :data {
    :amount 100
    :source-currency "USD"
    :target-currency "EUR"
    :conversion-factor 0.85
  }
}
"""


main()


func main() {
    

    
    guard let conversionLogicLambda = ednMap[.keyword(":conversion-logic")],
          let dataExpr = ednMap[.keyword(":data")] as? [ExprKey: Expr],
          let amountExpr = dataExpr[.keyword(":amount")],
          let conversionFactorExpr = dataExpr[.keyword(":conversion-factor")],
          let sourceCurrencyExpr = dataExpr[.keyword(":source-currency")],
          let targetCurrencyExpr = dataExpr[.keyword(":target-currency")] else {
        fatalError("Malformed EDN data or conversion logic")
    }
    
    guard let amount = amountExpr.numberValue,
          let conversionFactor = conversionFactorExpr.numberValue,
          let targetCurrency = targetCurrencyExpr.stringValue else {
        fatalError("Expected numerical values for amount and conversion factor, and string value for currency")
    }
    
    
    do {
        let conversionApplicationExpr = Expr.list([conversionLogicExpr, .number(amount), .number(conversionFactor)])
        let resultExpr = try EVAL(conversionApplicationExpr, env)
        
        guard let convertedAmount = resultExpr.numberValue else {
            fatalError("Conversion logic did not result in a numerical value")
        }
        
        let convertedResult: (currency: String, amount: Number) = (currency: targetCurrency, amount: convertedAmount)
        print("Converted amount: \(convertedResult.amount) \(convertedResult.currency)")
    } catch {
        print("Evaluation error: \(error)")
    }
}

