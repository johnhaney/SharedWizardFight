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
    let handTracking = HandTrackingProvider()
    
    let imageTracking = ImageTrackingProvider(
        referenceImages: ReferenceImage.loadReferenceImages(inGroupNamed: "CardDeck20")
    )
    
    let planeDetection = PlaneDetectionProvider(alignments: [.horizontal, .vertical])
    let sceneReconstruction = SceneReconstructionProvider(modes: [.classification])
    
    var planeAnchors: [UUID: PlaneAnchor] = [:]
    var imageAnchors: [UUID: ImageAnchor] = [:]
    var imageAnchorsByName: [String: ImageAnchor] = [:]
    var entityMap: [UUID: Entity] = [:]
    var home: UUID = UUID()
    var root: Entity = Entity()
    var fireballModel = FireViewModel()
    
    private var fireState: FireState = .readyForFire(nil)
    
    var tables: Set<UUID> = Set()
    var seats: Set<UUID> = Set()

    enum FireState {
        case none
        case readyForFire(Entity?)
        case snapReady(Entity?, Date)
        case fireActive
        case fireLoaded(Date)
        case fireThrown(Date)
    }

    init() {
        super.init(providers: [.image(imageTracking), .planes(planeDetection), .hands(handTracking), .meshes(sceneReconstruction)])
    }
    
    func collect(_ entity: Entity) -> Bool {
        if case .none = fireState {
            entity.components.set(OpacityComponent(opacity: 0))
            fireState = .readyForFire(entity)
            return true
        }
        return false
    }
    
    override func update(_ hand: HandAnchor) async {
        switch hand.chirality {
        case .right:
            break
        case .left:
            let fire: Bool
            var item: Entity? = nil
            switch fireState {
            case .none:
                fireballModel.myball.components.set(OpacityComponent(opacity: 0))
                fire = false
            case .readyForFire(let collectedItem):
                item = collectedItem
                if hand.isPreSnap() {
                    print("ready for snap")
                    fireState = .snapReady(collectedItem, Date())
                }
                fireballModel.myball.components.set(OpacityComponent(opacity: 0))
                fire = false
            case .snapReady(let collectedItem, let lastPresnap):
                if hand.isAfterSnap() {
                    if Date().timeIntervalSince(lastPresnap) < 0.1 {
                        print("SNAP!")
                        fireballModel.myball.components.remove(OpacityComponent.self)
                        fireState = .fireActive
                        fire = true
                        collectedItem?.removeFromParent()
                    } else {
                        item = collectedItem
                        fireState = .readyForFire(item)
                        fire = false
                    }
                } else {
                    item = collectedItem
                    fire = false
                    if hand.isPreSnap() {
                        fireState = .snapReady(collectedItem, Date())
                    }
                }
            case .fireActive:
                // size the fire based on both hands
                let anchors = handTracking.latestAnchors
                sizeFireball(anchors)
                if let lh = anchors.leftHand,
                   let pointing = lh.isPointing() {
                    print("FIRE!!")
                    fire = false
                    var transform = fireballModel.myball.transform
                    transform.translation += normalize(pointing) * 100
                    fireballModel.myball.move(to: transform, relativeTo: nil, duration: 6, timingFunction: .linear)
                    fireState = .fireThrown(Date(timeIntervalSinceNow: 6))
                } else {
                    fire = true
                }
            case .fireLoaded(let lastLoaded):
                if let yComponent = AffineTransform3D(hand.originFromAnchorTransform)?.rotation?.axis.y {
                    if abs(yComponent) < 0.1 {
                        if Date().timeIntervalSince(lastLoaded) < 0.1 {
                            print("FIRE!!")
                            fire = false
                            fireState = .fireThrown(Date(timeIntervalSinceNow: 6))
                        } else {
                            print("too slow...")
                            fire = true
                        }
                    } else if yComponent > 0.8 {
                        fire = true
                        fireState = .fireLoaded(Date())
                    } else {
                        fire = true
                    }
                    print("hmm \(yComponent)")
                } else {
                    fire = true
                }
            case .fireThrown(let expirationTime):
                fire = false
                // thrown the fire, check for timeout
                if Date().timeIntervalSince(expirationTime) >= 0 {
                    fireState = .none
                    fireballModel.myball.transform.rotation = .zero
                }
                // Rotate the smoke effect
                fireballModel.myball.transform.rotation = .init(angle: .pi*0.4, axis: .init(x: 1, y: 0, z: 0))
            }
            
            if fire {
                let indextip = hand.handSkeleton!.joint(.indexFingerTip)
                let indextiploc = hand.getlocation(jointloc: hand.originFromAnchorTransform, parentloc: indextip.anchorFromJointTransform)
                fireballModel.myball.transform.translation = root.convert(position: indextiploc.xyz, from: nil) + simd_float3(x: 0, y: 0.07, z: 0)
            } else if let item {
                item.components.remove(OpacityComponent.self)
                let indextip = hand.handSkeleton!.joint(.indexFingerTip)
                let indextiploc = hand.getlocation(jointloc: hand.originFromAnchorTransform, parentloc: indextip.anchorFromJointTransform)
                var itemTransform = item.transform
                itemTransform.translation = indextiploc.xyz
                item.move(to: itemTransform, relativeTo: nil, duration: 0.1)
            }
        }
    }
    
    private func sizeFireball(_ hands: (HandAnchor?, HandAnchor?)) {
        let (lh, rh) = hands
        guard let lh, let rh else { return }
        
        fireballModel.myball.transform.scale = SIMD3<Float>(repeating: 3 * distance(Transform(matrix: lh.originFromAnchorTransform).translation, Transform(matrix: rh.originFromAnchorTransform).translation))
    }
    
    override func update(_ anchor: PlaneAnchor) async {
        if planeAnchors[anchor.id] == nil {
            let entity = Entity()
            entity.name = anchor.id.uuidString
            entityMap[anchor.id] = entity
            contentEntity.addChild(entity)
            self.planeAnchors[anchor.id] = anchor
            
            if anchor.alignment == .horizontal {
                guard let entity = await EasterEgg.random() else { return }
                entity.components.set(HoverEffectComponent())
                let anchor = AnchorEntity(world: Transform(matrix: anchor.originFromAnchorTransform).translation)
                anchor.addChild(entity)
                contentEntity.addChild(anchor)
            }
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
            rotationTwo.addChild(self.homeEntity)
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

extension simd_quatd {
    static var zero: simd_quatd {
        simd_quatd(angle: .zero, axis: SIMD3<Double>(x: 0, y: 1, z: 0))
    }
}

extension simd_quatf {
    static var zero: simd_quatf {
        simd_quatf(angle: .zero, axis: SIMD3<Float>(x: 0, y: 1, z: 0))
    }
}
