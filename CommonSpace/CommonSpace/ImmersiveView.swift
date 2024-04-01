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
    
    @StateObject private var networkedCircle = PSNetworking<SendablePlayer>(defaultSendable: SendablePlayer(state: .nonexistent, playerTransform: Transform().matrix))
    
    @Binding var fireballModel:FireViewModel
    @State var timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    @StateObject private var receiver: Receiver = Receiver()
    
    var body: some View {
        RealityView { content in
            content.add(model.setupContentEntity())
            fireballModel.root = model.homeEntity
            content.add(fireballModel.myball)
            model.homeEntity.addChild(fireballModel.yourball)
        }
        .gesture(TapGesture().targetedToAnyEntity().onEnded { tap in
            model.collect(tap.entity)
        })
        .onReceive(timer, perform: { _ in
            let state = fireballModel.encode()
            networkedCircle.send(SendablePlayer(state: state.0, playerTransform: state.1))
            
            print(model.fireState)
        })
//        .onAppear {
//            receiver.fireballModel = fireballModel
//            PeersController.shared.peersDelegates.append(receiver)
//        }
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
            // Get new entity
            
            networkedCircle.listen { player in
                print("Received new entity", player)
                
                fireballModel.decode(state: player.fireballState, trans_matrix: player.playerTransform)
            }
        }

//        }.task{
//            var testing_decoding = false
//            if testing_decoding{
//                if testing_decoding{
//                    for second in 1...1000 {
//                        await Task.sleep(UInt64(100_000_000)) // Wait for 1 sec
//                        let (a,b) = fireballModel.encode()
//                        fireballModel.decode(state: a, trans_matrix: b)
//                    }
//                }
//            }
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

class Receiver: PeersControllerDelegate, ObservableObject {
    var fireballModel: FireViewModel?
    
    func received(data: Data, viaStream: Bool) -> Bool {
        guard let player = try? JSONDecoder().decode(SendablePlayer.self, from: data) else {
            return false
        }
        
        fireballModel?.decode(state: player.fireballState, trans_matrix: player.playerTransform)
        
        return true
    }
}
