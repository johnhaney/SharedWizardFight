//
//  CommonSpaceApp.swift
//  CommonSpace
//
//  Created by John Haney (Lextech) on 3/30/24.
//

import SwiftUI
import OSLog

let logger = Logger(subsystem: "com.lextech.CommonSpaceApp", category: "general")

@main
struct CommonSpaceApp: App {
    @State private var commonModel: CommonSpaceViewModel
    
    init() {
        commonModel = CommonSpaceViewModel()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(commonModel)
        }.windowStyle(.volumetric)

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
                .environment(commonModel)
        }
    }
}
