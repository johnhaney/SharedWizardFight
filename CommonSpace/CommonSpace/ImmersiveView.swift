//
//  ImmersiveView.swift
//  CommonSpace
//
//  Created by John Haney (Lextech) on 3/30/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

@MainActor
struct ImmersiveView: View {
    @Environment(CommonSpaceViewModel.self) var model
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    @Environment(\.openWindow) var openWindow
    
    @Binding var fireballModel:FireViewModel
    
    var body: some View {
        RealityView { content in
            content.add(model.setupContentEntity())
            fireballModel.root = model.homeEntity
            model.homeEntity.addChild(fireballModel.myball)
            model.homeEntity.addChild(fireballModel.yourball)
        }
        .gesture(TapGesture().targetedToAnyEntity().onEnded { tap in
            model.collect(tap.entity)
        })
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
        }.task{
            var testing_decoding = false
            if testing_decoding{
                if testing_decoding{
                    for second in 1...1000 {
                        await Task.sleep(UInt64(100_000_000)) // Wait for 1 sec
                        let (a,b) = fireballModel.encode()
                        fireballModel.decode(state: a, trans_matrix: b)
                    }
                }
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
