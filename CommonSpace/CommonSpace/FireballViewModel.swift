//
//  ViewModel.swift
//  SharedSpaceMenu
//
//  Created by Gary Yao on 3/30/24.
//

import Foundation
import RealityKit
import RealityKitContent

enum fireballstate:String{
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
    var myball = Entity()
    var yourball = Entity()
    
    var root = Entity()
    func encode() -> (String, simd_float4x4){
        return (myfireball.state.rawValue, myball.transform.matrix)
    }
    func decode(state:String, trans_matrix:simd_float4x4){
        if state == "thrown"{
            if yourfireball.state != .thrown{
                yourfireball.state = fireballstate.thrown
                yourball.move(to: Transform(translation: SIMD3(x: 0.0, y: 0.0, z: -3.0)), relativeTo: yourball, duration: 3)
            }
        }else{
            if let rawvalue = fireballstate(rawValue: state){
                yourfireball.state = rawvalue
            }
            yourball.setTransformMatrix(trans_matrix, relativeTo: root)
        }
    }

    init() {
        Task {
            if let scene = try? await Entity(named: "fireball_01", in: realityKitContentBundle) {
                await self.myball.addChild(scene)
            }
            if let scene = try? await Entity(named: "fireball_01", in: realityKitContentBundle) {
                await self.yourball.addChild(scene)
            }
        }
    }
}

extension BallInformation{
    static let defaultInfo: BallInformation = BallInformation(state: fireballstate.nonexistent, coordinates: SIMD3(x: 0.0, y: 0.0, z: 0.0))
}