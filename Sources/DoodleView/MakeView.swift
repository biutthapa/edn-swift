//
//  MakeView.swift
//  
//
//  Created by Biut Raj Thapa on 09/02/2024.
//

import SwiftUI
import AVKit

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
//    case let .vStack(views):
//            VStack {
//                ForEach(views.indices, id: \.self) { index in
//                    makeView(from: views[index])
//                }
//            }
//    case let .hStack(views):
//        HStack {
//            ForEach(views.indices, id: \.self) { index in
//                makeView(from: views[index])
//            }
//        }
//    case .spacer:
//            Spacer()
//    case let .frame(width, height):
//        Group {
//            if let width = width, let height = height {
//                EmptyView().frame(width: width, height: height)
//            } else if let width = width {
//                EmptyView().frame(width: width)
//            } else if let height = height {
//                EmptyView().frame(height: height)
//            } else {
//                EmptyView()
//            }
//        }
      
    default:
        EmptyView()
    }
}




//    case let .image(name, modifiers):
//        Image(name)
//            .resizable(resizing: modifiers.resizable)
//            .frame(width: modifiers.frame?.width, height: modifiers.frame?.height)
//
//    case let .button(label, modifiers, viewExprs):
//        Button(action: modifiers.action) {
//            Text(label)
//        }
//    case let .stack(type, viewExprs, modifiers):
//        switch type {
//        case .hStack:
//            HStack(alignment: modifiers.alignment.vertical, spacing: modifiers.spacing) {
//                ForEach(viewExprs.indices, id: \.self) { index in
//                    makeView(from: viewExprs[index])
//                }
//            }
//        case .vStack:
//            VStack(alignment: modifiers.alignment.horizontal, spacing: modifiers.spacing) {
//                ForEach(viewExprs.indices, id: \.self) { index in
//                    makeView(from: viewExprs[index])
//                }
//            }
//        case .zStack:
//            ZStack(alignment: modifiers.alignment) {
//                ForEach(viewExprs.indices, id: \.self) { index in
//                    makeView(from: viewExprs[index])
//                }
//            }
//        }
//
//    case let .custom(anyView):
//        anyView

//extension Image {
//    func resizable(resizing: Bool) -> some View {
//        resizing ? resizable() : self
//    }
//}
