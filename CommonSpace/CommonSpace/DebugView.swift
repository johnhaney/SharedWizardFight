//
//  DebugView.swift
//  CommonSpace
//
//  Created by John Haney (Lextech) on 3/31/24.
//

import SwiftUI

struct DebugView: View {
    @StateObject public var peersVm = PeersVm.shared
//    @StateObject private var networkedCircle = PSNetworking<SendableCircle>(defaultSendable: SendableCircle(sender: "", point: CGPoint(x: 200, y: 200)))

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            PeersView(peersVm)
//            DraggableCircle(entity: $networkedCircle.entity)
        }
        .padding()
        .task {
            // Get new entity
        }
    }
}

struct DraggableCircle: View {
    
    var body: some View {
        Circle()
            .frame(width: 50, height: 50)
            .foregroundColor(.blue)
            .gesture(
                DragGesture()
                    .onChanged { value in
                    }
            )
            
    }
}
