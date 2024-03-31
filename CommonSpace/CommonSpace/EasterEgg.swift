//
//  EasterEgg.swift
//  CommonSpace
//
//  Created by John Haney (Lextech) on 3/31/24.
//

import RealityKit
import RealityKitContent

struct EasterEgg {
    enum Egg: String, CaseIterable {
        case lexperson
        case pancakes
        case tadpole
        case airplane
//        case duck
    }
    static func random() async -> Entity? {
        let name = Egg.allCases.randomElement()?.rawValue ?? "lexperson"
        return try? await Entity(named: name, in: realityKitContentBundle)
    }
}
