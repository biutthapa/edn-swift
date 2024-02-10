//
//  NS.swift
//  
//
//  Created by Biut Raj Thapa on 09/02/2024.
//

import Foundation
import DoodleCore
import SwiftUI



let viewsNS: [String: ViewLambda] = [
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
        let color: Color = .black // Placeholder, implement actual logic
        return .rectView(color)
    }
]
