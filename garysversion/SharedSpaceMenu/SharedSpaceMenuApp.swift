//
//  SharedSpaceMenuApp.swift
//  SharedSpaceMenu
//
//  Created by Gary Yao on 3/30/24.
//

import SwiftUI

@main
struct SharedSpaceMenuApp: App {
    var body: some Scene {
        @State var sharedModel:SharedSpaceModel = SharedSpaceModel()
        @State var fireballModel = FireViewModel()
        WindowGroup {
            ContentView()
        }.windowStyle(.volumetric)

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView(sharedModel: $sharedModel, fireballModel: $fireballModel)
        }
    }
}
