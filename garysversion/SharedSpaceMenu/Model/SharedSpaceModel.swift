//
//  SharedSpaceModel.swift
//  SharedSpaceMenu
//
//  Created by Gary Yao on 3/30/24.
//

import Foundation
import RealityKit

class SharedSpaceModel{
    var root:Entity
    var entities:[Entity] = []
    init() {
        //this is floor at clock
        self.root = Entity()
        if let pancake = try? ModelEntity.load(named: "pancakes"){
            root.addChild(pancake)
            pancake.setPosition(SIMD3(x: 0.0, y: 0.5, z: -3.0), relativeTo: root)
            pancake.setScale(SIMD3(x: 0.1, y: 0.1, z: 0.1), relativeTo: nil)
        }else{
            print("Pancake failed")
        }
        let box = ModelEntity(mesh: .generateBox(width: 0.4, height: 0.4, depth: 0.1), materials: [SimpleMaterial(color: .blue, isMetallic: false)])
        box.setPosition(SIMD3(x: 0.0, y: 0.0, z: -2.0), relativeTo: root)
        box.generateCollisionShapes(recursive: false)
        box.components.set(InputTargetComponent())
        root.addChild(box)
    }
    
    func add_to_box(){
        let sample_adding_entity = ModelEntity(mesh: .generateSphere(radius: 0.3), materials: [SimpleMaterial(color: .red, isMetallic: false)])
        entities.append(sample_adding_entity)
        root.addChild(sample_adding_entity)
        
        sample_adding_entity.generateCollisionShapes(recursive: false)
        sample_adding_entity.components.set(InputTargetComponent())
        sample_adding_entity.setPosition(SIMD3(x: 0.5, y: 0.5, z: -0.5), relativeTo: root)
    }
}
