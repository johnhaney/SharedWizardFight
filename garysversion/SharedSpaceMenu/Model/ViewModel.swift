//
//  ViewModel.swift
//  SharedSpaceMenu
//
//  Created by Gary Yao on 3/30/24.
//

import Foundation
import RealityKit


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
class FireViewModel{
    var myfireball = BallInformation.defaultInfo
    var yourfireball = BallInformation.defaultInfo
    var myball = ModelEntity(mesh: .generateSphere(radius: 0.05), materials: [SimpleMaterial(color: .red, isMetallic: false)])
    var yourball = ModelEntity(mesh: .generateSphere(radius: 0.05), materials: [SimpleMaterial(color: .red, isMetallic: false)])
    var root = Entity()
    func encode() -> (String, simd_float4x4){
        return (myfireball.state.rawValue, myball.transform.matrix)
    }
    func decode(state:String, trans_matrix:simd_float4x4){
        yourball.setTransformMatrix(trans_matrix, relativeTo: root)
    }
}

extension BallInformation{
    static let defaultInfo: BallInformation = BallInformation(state: fireballstate.nonexistent, coordinates: SIMD3(x: 0.0, y: 0.0, z: 0.0))
}
