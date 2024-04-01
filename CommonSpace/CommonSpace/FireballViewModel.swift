//
//  ViewModel.swift
//  SharedSpaceMenu
//
//  Created by Gary Yao on 3/30/24.
//

import Foundation
import RealityKit
import RealityKitContent

enum fireballstate:String {
    case nonexistent
    case holding
    case thrown
}
class BallInformation{
    var state:fireballstate
    var coordinates:SIMD3<Float>
    init(state: fireballstate, coordinates: SIMD3<Float>) {
        self.state = state
        self.coordinates = coordinates
    }
}

@Observable
class FireViewModel {
    static var fireballAnimated: Entity?
    var myfireball = BallInformation.defaultInfo
    var yourfireball = BallInformation.defaultInfo
    var myballgoingto = SIMD3<Float>(x: 0.0, y: 0.0, z: 0.0)
    var youballgoingto = SIMD3<Float>(x: 0.0, y: 0.0, z: 0.0)
    var myball = Entity()
    var yourball = Entity()
    
    var root = Entity()
    func encode() -> (fireballstate, simd_float4x4){
        //if myfireball.state == .holding{
        if myfireball.state == .thrown{
            let localTransform = Transform(translation: myballgoingto)
            return (myfireball.state, localTransform.matrix)
        }
        let localTransform = root.convert(transform: myball.transform, from: nil)
        return (myfireball.state, localTransform.matrix)
    }
    func decode(state:fireballstate, trans_matrix:simd_float4x4){
        yourfireball.state = state
        yourball.setTransformMatrix(trans_matrix, relativeTo: root)
        
        return;

        switch state {
        case .thrown:
//            yourball.components.remove(OpacityComponent.self)
            if yourfireball.state != .thrown{
                yourfireball.state = fireballstate.thrown
                
                //another option to try
                //yourball.move(to: trans_matrix, relativeTo: root, duration: 6)
                
                let des_trans = trans_matrix[3].xyz
                let destination = Transform(translation: yourball.convert(position: des_trans, to:root))
                yourball.move(to: destination, relativeTo: root, duration: 6)
            }
        case .holding:
//            yourball.components.remove(OpacityComponent.self)
            yourfireball.state = state
            yourball.setTransformMatrix(trans_matrix, relativeTo: root)
        case .nonexistent:
//            yourball.components.set(OpacityComponent(opacity: 0))
            break
        }
    }

    init() {
        let debug = false
        if debug{
            var myActualBall = ModelEntity(mesh: .generateSphere(radius: 0.05), materials: [SimpleMaterial(color: .red, isMetallic: false)])
            var yourActualBall = ModelEntity(mesh: .generateSphere(radius: 0.05), materials: [SimpleMaterial(color: .blue, isMetallic: false)])
            myball.addChild(myActualBall)
            yourball.addChild(yourActualBall)
            myActualBall.setPosition(SIMD3(0.0,0.0,0.0), relativeTo: myball)
            yourActualBall.setPosition(SIMD3(0.0,0.0,0.0), relativeTo: yourball)
        }else{
            Task {
                if let scene = try? await Entity(named: "fireball_03", in: realityKitContentBundle) {
                    await self.myball.addChild(scene)
                }
                if let scene = try? await Entity(named: "fireball_03", in: realityKitContentBundle) {
                    await self.yourball.addChild(scene)
                }
            }
        }
    }
}

extension BallInformation{
    static let defaultInfo: BallInformation = BallInformation(state: fireballstate.nonexistent, coordinates: SIMD3(x: 0.0, y: 0.0, z: 0.0))
}
