//
//  types.swift
//  
//
//  Created by Biut Raj Thapa on 09/02/2024.
//

import Foundation
import SwiftUI
import DoodleCore

public typealias ViewLambda = ([ViewExpr]) throws -> ViewExpr

public enum ViewExpr {
    case text(String, TextModifiers)
    case image(String, ImageModifiers)
    case button(String, ButtonModifiers, [ViewExpr])
    case stack(StackType, [ViewExpr], StackModifiers)
    case custom(AnyView)
    
    public struct TextModifiers {
        var fontWeight: Font.Weight?
        var fontSize: CGFloat?
        var color: Color?
    }

    public struct ImageModifiers {
        var resizable: Bool
        var frame: CGSize?
    }

    public struct ButtonModifiers {
        var action: () -> Void
    }

    public struct StackModifiers {
        var alignment: Alignment
        var spacing: CGFloat?
    }

    public enum StackType {
        case hStack, vStack, zStack
    }
}


enum ViewError: Error {
    case typeMismatch(expected: String, found: String)
    case missingRequiredArgument(String)
    case unsupportedViewType(String)
    case invalidModifierValue(String)
    case custom(String)
}
