//
//  CommonSpaceViewModel.swift
//  CommonSpace
//
//  Created by John Haney (Lextech) on 3/30/24.
//

import ARKit
import RealityKit
import Spatial

@Observable
@MainActor
class CommonSpaceViewModel: ARUnderstandingModel {
    let imageTracking = ImageTrackingProvider(
        referenceImages: ReferenceImage.loadReferenceImages(inGroupNamed: "CardDeck20")
    )
    
    let planeDetection = PlaneDetectionProvider(alignments: [.horizontal, .vertical])
    
    var planeAnchors: [UUID: PlaneAnchor] = [:]
    var imageAnchors: [UUID: ImageAnchor] = [:]
    var imageAnchorsByName: [String: ImageAnchor] = [:]
    var entityMap: [UUID: Entity] = [:]
    var home: UUID = UUID()
    
    init() {
        super.init(providers: [.image(imageTracking), .planes(planeDetection)])
    }
    
    override func update(_ anchor: PlaneAnchor) async {
        if planeAnchors[anchor.id] == nil {
            let entity = Entity()
            entity.name = anchor.id.uuidString
            entityMap[anchor.id] = entity
            contentEntity.addChild(entity)
            self.planeAnchors[anchor.id] = anchor
        }
    }
    
    override func update(_ anchor: ImageAnchor) async {
        if imageAnchors[anchor.id] == nil {
            do {
                let entity = ModelEntity(mesh: .generateSphere(radius: 0.025))
                entity.name = anchor.id.uuidString
                entityMap[anchor.id] = entity
                contentEntity.addChild(entity)
            }
            self.imageAnchors[anchor.id] = anchor
            imageAnchorsByName[anchor.referenceImage.name ?? "NAME"] = anchor
            checkHome()
        }
        
        if anchor.isTracked {
            entityMap[anchor.id]?.transform = Transform(matrix: anchor.originFromAnchorTransform)
        }
    }
    
    func checkHome() {
        guard entityMap[home] == nil else { return }
        if let one = imageAnchorsByName["IMG_4108"] {
            let oneTransform = one.originFromAnchorTransform
            var position = Transform(matrix: oneTransform)
            position.translation = SIMD3<Float>(x: position.translation.x, y: 0, z: position.translation.z)
            
            let base = AnchorEntity(world: position.matrix)
            
            let rotationOne = Entity()
            rotationOne.transform = Transform(rotation: simd_quatf(angle: .pi, axis: SIMD3<Float>(x: 0, y: 1, z: 0)))
            
            let rotationTwo = Entity()
            rotationTwo.transform = Transform(rotation: simd_quatf(angle: .pi/2, axis: SIMD3<Float>(x: 1, y: 0, z: 0)))
            
            entityMap[one.id]?.addChild(rotationOne)
            rotationOne.addChild(rotationTwo)
            
            let homeEntity = ModelEntity(mesh: .generateSphere(radius: 0.025))
            homeEntity.name = "home"
            let plane = nearestPlane(to: Transform(matrix: one.originFromAnchorTransform))
            entityMap[home] = homeEntity
            rotationTwo.addChild(homeEntity)
            for z in 1...10 {
                let entity = ModelEntity(mesh: .generateSphere(radius: 0.025))
                entity.transform = Transform(translation: SIMD3<Float>(x: 0, y: 0, z: -0.5 * Float(z)))
                rotationTwo.addChild(entity)
            }
        }
    }
    
    func nearestPlane(to anchor: Transform) -> PlaneAnchor? {
        let rotation = anchor.rotation
        let translation = anchor.translation
        return planeAnchors.values.map({ ($0, (Transform(matrix: $0.originFromAnchorTransform).rotation - rotation).length) }).sorted(by: { $0.1 < $1.1 }).first(where: { (Transform(matrix: $0.0.originFromAnchorTransform).translation - translation).max() < 0.1 })?.0
    }
}
