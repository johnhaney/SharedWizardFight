//
//  ImmersiveView.swift
//  CommonSpace
//
//  Created by John Haney (Lextech) on 3/30/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {
    @Environment(CommonSpaceViewModel.self) var model
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    @Environment(\.openWindow) var openWindow
    @State var worldAnchor: Entity = AnchorEntity(.image(group: "CardDeck20", name: "IMG_4107 2"), trackingMode: .once)
    var body: some View {
        RealityView { content in
            content.add(model.setupContentEntity())
        }
        .task {
            do {
                if model.dataProvidersAreSupported && model.isReadyToRun {
                    try await model.runSession()
                } else {
                    await dismissImmersiveSpace()
                }
            } catch {
                logger.error("Failed to start session: \(error)")
                await dismissImmersiveSpace()
                openWindow(id: "error")
            }
        }
        .task {
            await model.processUpdates()
        }
        .task {
            await model.monitorSessionEvents()
        }
        .task(priority: .low) {
            await model.processLowUpdates()
        }
        .onChange(of: model.errorState) {
            openWindow(id: "error")
        }
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
}
