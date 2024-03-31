//
//  ImmersiveView.swift
//  SharedSpaceMenu
//
//  Created by Gary Yao on 3/30/24.
//

import SwiftUI
import RealityKit
import RealityKitContent
@MainActor
struct ImmersiveView: View {
    @Binding var sharedModel:SharedSpaceModel
    @State private var handTracker = HandTracking()
    @Binding var fireballModel:FireViewModel
    var body: some View {
        RealityView { content in
            //let root = Entity()//to change to fixed
            let root = Entity()
            fireballModel.root = root
            root.setPosition(SIMD3(x: 0.0, y: 0.0, z: 0.0), relativeTo: nil)
            content.add(root)
            root.addChild(fireballModel.myball)
            root.addChild(fireballModel.yourball)
            
            handTracker.fireballModel = fireballModel
            Task {
                print("Tasking")
                await handTracker.runARKitSession()
            }
        }.task {
           await handTracker.processHandAnchorUpdates()
        }.onTapGesture {
            sharedModel.add_to_box()
        }
        .gesture(
            DragGesture().targetedToAnyEntity()
                .onChanged {value in
                    let currently_dragged_entity = value.entity
                    currently_dragged_entity.position = value.convert(value.translation3D, from: .local, to: sharedModel.root)
                })
    }
}
