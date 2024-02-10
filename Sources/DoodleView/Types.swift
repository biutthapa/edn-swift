//
//  types.swift
//  
//
//  Created by Biut Raj Thapa on 09/02/2024.
//

import Foundation
import DoodleCore
import SwiftUI

public typealias ViewLambda = ([Expr]) throws -> ViewExpr

public enum ViewExpr {
    case textView(String, TextModifiers)
    case rectView(Color)
    
    //    case stack(StackType, [ViewExpr], StackModifiers)
//    public enum StackType {
//        case hStack, vStack, zStack
//    }

}

public typealias TextModifiers = (
    fontWeight: Font.Weight?,
    fontSize: CGFloat?,
    color: Color?,
    customFontName: String?
//    gradient: Gradient?
)

enum ViewError: Error {
    case typeMismatch(expected: String, found: String)
    case missingRequiredArgument(String)
    case unsupportedViewType(String)
    case invalidModifierValue(String)
    case custom(String)
}





//    case image(String, ImageModifiers)
//    case button(String, ButtonModifiers, [ViewExpr])
//    case custom(AnyView)

//    case vStack([ViewExpr])
//    case hStack([ViewExpr])
//    case zStack([ViewExpr])
//    case linearGradient(Gradient, startPoint: UnitPoint, endPoint: UnitPoint)
//    case spacer
//    case frame(width: CGFloat?, height: CGFloat?)
//    case opacity(Double)
//    case scaleEffect(CGFloat)
//    case shadow(color: Color, radius: CGFloat, x: CGFloat, y: CGFloat)
//    case avPlayerView(AVPlayer)






//
//    public struct ImageModifiers {
//        var resizable: Bool
//        var frame: CGSize?
//    }
//
//    public struct ButtonModifiers {
//        var action: () -> Void
//    }
//
//    public struct StackModifiers {
//        var alignment: Alignment
//        var spacing: CGFloat?
//    }
//
//



