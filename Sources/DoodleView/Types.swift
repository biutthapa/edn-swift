//
//  types.swift
//  
//
//  Created by Biut Raj Thapa on 09/02/2024.
//

import Foundation
import SwiftUI

public typealias ViewLambda = ([ViewExpr]) throws -> ViewExpr

public enum ViewExpr {
    case text(String, TextModifiers)
    case rect(Color)
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

}

public typealias TextModifiers = (
    fontWeight: Font.Weight?,
    fontSize: CGFloat?,
    color: Color?,
    customFontName: String?
//    gradient: Gradient?
)





//    case image(String, ImageModifiers)
//    case button(String, ButtonModifiers, [ViewExpr])
//    case stack(StackType, [ViewExpr], StackModifiers)
//    case custom(AnyView)






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
//    public enum StackType {
//        case hStack, vStack, zStack
//    }


enum ViewError: Error {
    case typeMismatch(expected: String, found: String)
    case missingRequiredArgument(String)
    case unsupportedViewType(String)
    case invalidModifierValue(String)
    case custom(String)
}
